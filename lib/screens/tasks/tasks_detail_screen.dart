import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../managers/auth_manager.dart';
import '../../managers/task_manager.dart';
import '../../models/task.dart';
import '../../services/notification_service.dart';
import '../../services/task_detail_api.dart';
import '../../services/task_notification_api.dart';
import '../../widgets/app_drawer.dart';
import 'notification_tasks.dart';


class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _commentController = TextEditingController();
  final _taskManager = TaskManager();
  final _notificationService = NotificationService();
  final List<_TaskComment> _comments = [];
  final List<_TaskAttachment> _attachments = [];
  final List<_Collaborator> _collaborators = [];
  final List<_ActivityItem> _activities = [];
  PlatformFile? _pendingCommentAttachment;
  bool _showCollaboratorPicker = false;
  String? _selectedCollaboratorName;
  bool _showDueEdit = false;
  DateTime? _editDueDate;
  TimeOfDay? _editDueTime;
  bool _showAssignedEdit = false;
  String? _selectedAssigneeName;
  String _username = 'You';
  int? _userId;
  late Task _task;
  late final String _taskSource;

  static const List<String> _collaboratorOptions = [
    'Andrea C',
    'Ashley E',
    'Barbara C',
    'Dalia J',
    'Dan A',
    'Eduardo G',
    'Himraj B',
    'Jose D',
    'Juan F',
    'Kevin L',
    'Monica S',
    'Rafael F',
    'Samuel L',
    'Stefan J',
    'Sunil Mistry',
  ];

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _taskSource = _resolveTaskSource(_task);
    _seedFromTask();
    _loadUserInfo();
    _initializeNotificationService();
    _loadTaskDetail();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final name = await AuthManager().getUsername();
    final id = await AuthManager().getUserId();
    if (!mounted) return;
    setState(() {
      _username = (name == null || name.trim().isEmpty) ? 'You' : name.trim();
      _userId = id;
    });
  }

  Future<void> _initializeNotificationService() async {
    try {
      if (!_notificationService.isInitialized) {
        await _notificationService.initialize();
      }
    } catch (e) {
      debugPrint('Failed to initialize notification service in task detail: $e');
    }
  }

  Future<void> _notifyTaskDetail({
    required String title,
    required String body,
  }) async {
    try {
      if (!_notificationService.isInitialized) {
        await _notificationService.initialize();
      }
      await _notificationService.showTaskDetailNotification(
        title: title,
        body: body,
        payload: 'task_detail:${_task.id}',
      );
    } catch (e) {
      debugPrint('Failed to show task detail notification: $e');
    }
    try {
      await TaskNotificationApi.createNotification(
        taskId: _task.id,
        title: title,
        message: body,
        taskSource: _taskSource,
      );
    } catch (e) {
      debugPrint('Failed to save task notification: $e');
    }
  }

  void _seedFromTask() {
    final createdAt = _task.createdAt ?? DateTime.now();
    _activities.add(_ActivityItem(
      title: 'Task created',
      subtitle: _task.title,
      time: createdAt,
      icon: HugeIcons.strokeRoundedTask01,
      color: const Color(0xFF131416),
    ));

    if (_task.isCompleted) {
      _activities.insert(
        0,
        _ActivityItem(
          title: 'Task completed',
          subtitle: _task.title,
          time: _task.completedDate ?? DateTime.now(),
          icon: HugeIcons.strokeRoundedCheckmarkCircle02,
          color: Colors.green,
        ),
      );
    }

    final meta = _task.meta;
    if (meta is Map<String, dynamic>) {
      final attachment = meta['attachment'];
      if (attachment is Map<String, dynamic>) {
        _attachments.add(
          _TaskAttachment(
            name: (attachment['name'] ?? 'Attachment').toString(),
            size: (attachment['size'] is int)
                ? attachment['size'] as int
                : int.tryParse('${attachment['size'] ?? 0}') ?? 0,
            path: attachment['path']?.toString(),
          ),
        );
      }
    }

    final createdBy = _task.createdBy;
    if (createdBy != null && createdBy.isNotEmpty) {
      _collaborators.add(
        _Collaborator(
          name: _displayUser(createdBy),
          email: null,
        ),
      );
    }
  }

  String _storageKey() => 'task_detail_${_taskSource}_${_task.id}';

  String _resolveTaskSource(Task task) {
    final meta = task.meta;
    if (meta is Map<String, dynamic>) {
      final source = meta['source']?.toString();
      if (source == 'lead_tasks') return 'lead_tasks';
    }
    return 'tasks';
  }

  Future<void> _loadTaskDetail() async {
    await _loadPersistedTaskDetail();
    await _loadTaskDetailFromApi();
  }

  Future<void> _loadPersistedTaskDetail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey());
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      await _applyTaskDetail(decoded);
    } catch (e) {
      debugPrint('Failed to load task detail data: $e');
    }
  }

  Future<void> _loadTaskDetailFromApi() async {
    final data = await TaskDetailApi.fetchTaskDetail(
      _task.id,
      taskSource: _taskSource,
    );
    if (data == null) return;

    final hasRemoteData = _hasAnyDetailData(data);
    if (!hasRemoteData) {
      if (_hasLocalDetailData()) {
        await _saveTaskDetailToStorage();
      }
      return;
    }

    final localCounts = _detailCountsFromPayload(_buildTaskDetailPayload());
    final remoteCounts = _detailCountsFromPayload(data);
    final localHasMore = localCounts['total']! > remoteCounts['total']!;

    if (_hasLocalDetailData() && localHasMore) {
      await _saveTaskDetailToStorage();
      return;
    }

    await _applyTaskDetail(data);
    await _saveTaskDetailToStorage(skipRemote: true);
  }

  bool _hasLocalDetailData() {
    return _comments.isNotEmpty ||
        _attachments.isNotEmpty ||
        _collaborators.isNotEmpty ||
        _activities.isNotEmpty;
  }

  bool _hasAnyDetailData(Map<String, dynamic> data) {
    List<dynamic> decode(dynamic raw) {
      if (raw is List) return raw;
      if (raw is String && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is List) return decoded;
        } catch (_) {}
      }
      return [];
    }

    return decode(data['comments']).isNotEmpty ||
        decode(data['attachments']).isNotEmpty ||
        decode(data['collaborators']).isNotEmpty ||
        decode(data['activities']).isNotEmpty;
  }

  Map<String, int> _detailCountsFromPayload(Map<String, dynamic> data) {
    List<dynamic> decode(dynamic raw) {
      if (raw is List) return raw;
      if (raw is String && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is List) return decoded;
        } catch (_) {}
      }
      return [];
    }

    final comments = decode(data['comments']).length;
    final attachments = decode(data['attachments']).length;
    final collaborators = decode(data['collaborators']).length;
    final activities = decode(data['activities']).length;
    return {
      'comments': comments,
      'attachments': attachments,
      'collaborators': collaborators,
      'activities': activities,
      'total': comments + attachments + collaborators + activities,
    };
  }

  Future<void> _applyTaskDetail(Map<String, dynamic> decoded) async {
    List<dynamic> decodeList(dynamic raw) {
      if (raw is List) return raw;
      if (raw is String && raw.isNotEmpty) {
        try {
          final parsed = jsonDecode(raw);
          if (parsed is List) return parsed;
        } catch (_) {}
      }
      return [];
    }

    final commentsRaw = decodeList(decoded['comments']);
    final attachmentsRaw = decodeList(decoded['attachments']);
    final collaboratorsRaw = decodeList(decoded['collaborators']);
    final activitiesRaw = decodeList(decoded['activities']);

    if (commentsRaw.isEmpty &&
        attachmentsRaw.isEmpty &&
        collaboratorsRaw.isEmpty &&
        activitiesRaw.isEmpty) {
      return;
    }

    final loadedComments = <_TaskComment>[];
    for (final item in commentsRaw) {
      if (item is! Map<String, dynamic>) continue;
      final attachmentRaw = item['attachment'];
      _TaskAttachment? attachment;
      if (attachmentRaw is Map<String, dynamic>) {
        attachment = _TaskAttachment(
          name: (attachmentRaw['name'] ?? 'Attachment').toString(),
          size: attachmentRaw['size'] is int
              ? attachmentRaw['size'] as int
              : int.tryParse('${attachmentRaw['size'] ?? 0}') ?? 0,
          path: attachmentRaw['path']?.toString(),
        );
      }
      loadedComments.add(
        _TaskComment(
          author: (item['author'] ?? '').toString(),
          text: (item['text'] ?? '').toString(),
          createdAt: DateTime.tryParse('${item['createdAt'] ?? ''}') ??
              DateTime.now(),
          attachment: attachment,
        ),
      );
    }

    final loadedAttachments = <_TaskAttachment>[];
    for (final item in attachmentsRaw) {
      if (item is! Map<String, dynamic>) continue;
      loadedAttachments.add(
        _TaskAttachment(
          name: (item['name'] ?? 'Attachment').toString(),
          size: item['size'] is int
              ? item['size'] as int
              : int.tryParse('${item['size'] ?? 0}') ?? 0,
          path: item['path']?.toString(),
        ),
      );
    }

    final loadedCollaborators = <_Collaborator>[];
    for (final item in collaboratorsRaw) {
      if (item is! Map<String, dynamic>) continue;
      loadedCollaborators.add(
        _Collaborator(
          name: (item['name'] ?? '').toString(),
          email: item['email']?.toString(),
        ),
      );
    }

    final loadedActivities = <_ActivityItem>[];
    for (final item in activitiesRaw) {
      if (item is! Map<String, dynamic>) continue;
      final codePoint = item['iconCodePoint'];
      final fontFamily = item['iconFamily']?.toString();
      final fontPackage = item['iconPackage']?.toString();
      final icon = (codePoint is int)
          ? IconData(
              codePoint,
              fontFamily: fontFamily,
              fontPackage: fontPackage,
            )
          : HugeIcons.strokeRoundedNotification03;
      final colorValue = item['colorValue'];
      loadedActivities.add(
        _ActivityItem(
          title: (item['title'] ?? '').toString(),
          subtitle: (item['subtitle'] ?? '').toString(),
          time: DateTime.tryParse('${item['time'] ?? ''}') ?? DateTime.now(),
          icon: icon,
          color: Color(colorValue is int ? colorValue : 0xFF131416),
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      _comments
        ..clear()
        ..addAll(loadedComments);
      _attachments
        ..clear()
        ..addAll(loadedAttachments);
      _collaborators
        ..clear()
        ..addAll(loadedCollaborators);
      _activities
        ..clear()
        ..addAll(loadedActivities);
    });
  }

  Map<String, dynamic> _buildTaskDetailPayload() {
    return {
      'comments': _comments
          .map((c) => {
                'author': c.author,
                'text': c.text,
                'createdAt': c.createdAt.toIso8601String(),
                'attachment': c.attachment == null
                    ? null
                    : {
                        'name': c.attachment!.name,
                        'size': c.attachment!.size,
                        'path': c.attachment!.path,
                      },
              })
          .toList(),
      'attachments': _attachments
          .map((a) => {
                'name': a.name,
                'size': a.size,
                'path': a.path,
              })
          .toList(),
      'collaborators': _collaborators
          .map((c) => {
                'name': c.name,
                'email': c.email,
              })
          .toList(),
      'activities': _activities
          .map((a) => {
                'title': a.title,
                'subtitle': a.subtitle,
                'time': a.time.toIso8601String(),
                'iconCodePoint': a.icon.codePoint,
                'iconFamily': a.icon.fontFamily,
                'iconPackage': a.icon.fontPackage,
                // ignore: deprecated_member_use
                'colorValue': a.color.value,
              })
          .toList(),
    };
  }

  Future<void> _saveTaskDetailToStorage({bool skipRemote = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = _buildTaskDetailPayload();
      await prefs.setString(_storageKey(), jsonEncode(payload));
      if (!skipRemote) {
        final error = await TaskDetailApi.saveTaskDetail(
          taskId: _task.id,
          payload: payload,
          taskSource: _taskSource,
        );
        if (error != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to save task detail data: $e');
    }
  }

  Future<_TaskAttachment?> _uploadTaskDetailAttachment(PlatformFile file) async {
    final path = file.path;
    if (path == null || path.isEmpty) return null;
    final meta = await TaskDetailApi.uploadAttachment(
      taskId: _task.id,
      taskSource: _taskSource,
      filePath: path,
      fileName: file.name,
    );
    if (meta == null) return null;
    return _TaskAttachment(
      name: (meta['name'] ?? file.name).toString(),
      size: meta['size'] is int
          ? meta['size'] as int
          : int.tryParse('${meta['size'] ?? file.size}') ?? file.size,
      path: meta['path']?.toString(),
    );
  }

  String _displayUser(String? id) {
    if (id == null || id.trim().isEmpty) return _username;
    if (_userId != null && id == _userId.toString()) return _username;
    if (int.tryParse(id) == null) return id;
    return 'User #$id';
  }

  String _formatDateTime(DateTime date) {
    return '${_monthName(date.month)} ${date.day}, ${date.year} - ${_formatTime(date)}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  TimeOfDay _parseTimeString(String timeString) {
    final parts = timeString.trim().split(' ');
    final timeParts = parts.first.split(':');
    int hour = int.tryParse(timeParts[0]) ?? 0;
    final minute = int.tryParse(timeParts.length > 1 ? timeParts[1] : '0') ?? 0;
    if (parts.length > 1 && parts[1].toUpperCase() == 'PM' && hour != 12) {
      hour += 12;
    } else if (parts.length > 1 &&
        parts[1].toUpperCase() == 'AM' &&
        hour == 12) {
      hour = 0;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _formatDueDate() {
    return '${_monthName(_task.dueDate.month)} ${_task.dueDate.day}, ${_task.dueDate.year} - ${_task.dueTime}';
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty && _pendingCommentAttachment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a comment or attachment.')),
      );
      return;
    }

    final attachmentFile = _pendingCommentAttachment;
    _TaskAttachment? uploadedAttachment;
    if (attachmentFile != null) {
      uploadedAttachment = await _uploadTaskDetailAttachment(attachmentFile);
      if (uploadedAttachment == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload attachment.')),
        );
        return;
      }
    }

    final createdAt = DateTime.now();
    setState(() {
      _comments.insert(
        0,
        _TaskComment(
          author: _username,
          text: text,
          createdAt: createdAt,
          attachment: uploadedAttachment,
        ),
      );
      _activities.insert(
        0,
        _ActivityItem(
          title: 'Added comment',
          subtitle: _task.title,
          time: createdAt,
          icon: HugeIcons.strokeRoundedComment01,
          color: const Color(0xFF2563EB),
        ),
      );
      _commentController.clear();
      _pendingCommentAttachment = null;
    });
    await _saveTaskDetailToStorage();
    await _notifyTaskDetail(
      title: 'Comment added',
      body: '$_username added a comment on "${_task.title}"',
    );
  }

  Future<void> _pickCommentAttachment() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: false,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.path == null || file.path!.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to read selected file.')),
        );
        return;
      }
      setState(() => _pendingCommentAttachment = file);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick attachment.')),
      );
    }
  }

  Future<void> _addAttachment({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: false,
        type: type,
        allowedExtensions: allowedExtensions,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.path == null || file.path!.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to read selected file.')),
        );
        return;
      }
      final attachment = await _uploadTaskDetailAttachment(file);
      if (attachment == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload attachment.')),
        );
        return;
      }
      final createdAt = DateTime.now();
      setState(() {
        _attachments.insert(0, attachment);
        _activities.insert(
          0,
          _ActivityItem(
            title: 'Added attachment',
            subtitle: attachment.name,
            time: createdAt,
            icon: HugeIcons.strokeRoundedAttachment01,
            color: Colors.orange,
          ),
        );
      });
      await _saveTaskDetailToStorage();
      await _notifyTaskDetail(
        title: 'Activity update',
        body: 'Attachment "${attachment.name}" added to "${_task.title}"',
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add attachment.')),
      );
    }
  }

  void _toggleCollaboratorPicker() {
    setState(() {
      _showCollaboratorPicker = !_showCollaboratorPicker;
      if (!_showCollaboratorPicker) {
        _selectedCollaboratorName = null;
      }
    });
  }

  Future<void> _confirmAddCollaborator() async {
    final name = _selectedCollaboratorName?.trim();
    if (name == null || name.isEmpty) return;

    final createdAt = DateTime.now();
    setState(() {
      _collaborators.add(_Collaborator(name: name, email: null));
      _activities.insert(
        0,
        _ActivityItem(
          title: 'Added collaborator',
          subtitle: name,
          time: createdAt,
          icon: HugeIcons.strokeRoundedUserMultiple,
          color: const Color(0xFF0EA5E9),
        ),
      );
      _selectedCollaboratorName = null;
      _showCollaboratorPicker = false;
    });
    await _saveTaskDetailToStorage();
    await _notifyTaskDetail(
      title: 'Collaborator added',
      body: '$name was added to "${_task.title}"',
    );
  }

  void _openDueEdit() {
    setState(() {
      _showDueEdit = true;
      _showAssignedEdit = false;
      _editDueDate = _task.dueDate;
      _editDueTime = _parseTimeString(_task.dueTime);
    });
  }

  void _openAssignedEdit() {
    setState(() {
      _showAssignedEdit = true;
      _showDueEdit = false;
      final current = _task.assignedTo;
      if (current != null && _collaboratorOptions.contains(current.trim())) {
        _selectedAssigneeName = current.trim();
      } else {
        _selectedAssigneeName = null;
      }
    });
  }

  void _cancelAssignedEdit() {
    setState(() {
      _showAssignedEdit = false;
      _selectedAssigneeName = null;
    });
  }

  void _cancelDueEdit() {
    setState(() {
      _showDueEdit = false;
      _editDueDate = null;
      _editDueTime = null;
    });
  }

  Future<void> _updateDueDateTime() async {
    if (_editDueDate == null || _editDueTime == null) return;
    final newDueDate = DateTime(
      _editDueDate!.year,
      _editDueDate!.month,
      _editDueDate!.day,
    );
    final newDueTime = _formatTimeOfDay(_editDueTime!);

    final updatedTask = Task(
      id: _task.id,
      leadId: _task.leadId,
      createdBy: _task.createdBy,
      assignedTo: _task.assignedTo,
      title: _task.title,
      description: _task.description,
      priority: _task.priority,
      dueDate: newDueDate,
      dueTime: newDueTime,
      isCompleted: _task.isCompleted,
      completedDate: _task.completedDate,
      createdAt: _task.createdAt,
      updatedAt: DateTime.now(),
      meta: _task.meta,
    );

    try {
      await _taskManager.updateTask(updatedTask);
      if (!mounted) return;
      setState(() {
        _task = updatedTask;
        _showDueEdit = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Due date updated'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update due date: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _updateAssignedTo() {
    final name = _selectedAssigneeName?.trim();
    if (name == null || name.isEmpty) return;
    setState(() {
      _task = Task(
        id: _task.id,
        leadId: _task.leadId,
        createdBy: _task.createdBy,
        assignedTo: name,
        title: _task.title,
        description: _task.description,
        priority: _task.priority,
        dueDate: _task.dueDate,
        dueTime: _task.dueTime,
        isCompleted: _task.isCompleted,
        completedDate: _task.completedDate,
        createdAt: _task.createdAt,
        updatedAt: DateTime.now(),
        meta: _task.meta,
      );
      _showAssignedEdit = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Assigned user updated'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final description = _task.description.trim();
    String subtitle = '';
    String body = description;
    final dotIndex = description.indexOf('.');
    if (dotIndex > 20 && dotIndex < description.length - 1) {
      subtitle = description.substring(0, dotIndex + 1);
      body = description.substring(dotIndex + 1).trim();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _task.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF131416),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _priorityColor(_task.priority).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _task.priority,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _priorityColor(_task.priority),
                  ),
                ),
              ),
            ],
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
          if (body.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              body,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
          const SizedBox(height: 6),
          _buildInfoRow(
            icon: HugeIcons.strokeRoundedFlag01,
            label: 'Priority',
            value: _task.priority,
            pillColor: _priorityColor(_task.priority),
          ),
          _buildInfoRow(
            icon: HugeIcons.strokeRoundedUser,
            label: 'Created by',
            value: _displayUser(_task.createdBy),
          ),
          _buildInfoRow(
            icon: HugeIcons.strokeRoundedUserMultiple,
            label: 'Assigned to',
            value: _displayUser(_task.assignedTo),
            trailing: _compactEditIcon(_openAssignedEdit),
          ),
          if (_showAssignedEdit) ...[
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final current = _task.assignedTo?.trim();
                final options = <String>{
                  if (current != null && current.isNotEmpty) current,
                  ..._collaboratorOptions,
                }.toList();
                return DropdownButtonFormField<String>(
                  initialValue: _selectedAssigneeName,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Select User',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: options
                      .map((name) =>
                          DropdownMenuItem(value: name, child: Text(name)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedAssigneeName = value),
                );
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _updateAssignedTo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF131416),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text('Update',
                      style: TextStyle(fontSize: 12, color: Colors.white)),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: _cancelAssignedEdit,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(fontSize: 12, color: Colors.black87)),
                ),
              ],
            ),
          ],
          _buildInfoRow(
            icon: HugeIcons.strokeRoundedCalendar03,
            label: 'Created on',
            value: _task.createdAt != null
                ? _formatDateTime(_task.createdAt!)
                : _formatDateTime(DateTime.now()),
          ),
          _buildInfoRow(
            icon: HugeIcons.strokeRoundedClock01,
            label: 'Due date',
            value: _formatDueDate(),
            trailing: _compactEditIcon(_openDueEdit),
          ),
          if (_showDueEdit) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _editDueDate ?? _task.dueDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        setState(() => _editDueDate = date);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _editDueDate != null
                                ? '${_editDueDate!.day.toString().padLeft(2, '0')}-${_editDueDate!.month.toString().padLeft(2, '0')}-${_editDueDate!.year}'
                                : 'Select date',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const Icon(Icons.calendar_today,
                              size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _editDueTime ?? TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() => _editDueTime = time);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _editDueTime != null
                                ? _formatTimeOfDay(_editDueTime!)
                                : 'Select time',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const Icon(Icons.access_time,
                              size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _updateDueDateTime,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF131416),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text('Update',
                      style: TextStyle(fontSize: 12, color: Colors.white)),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: _cancelDueEdit,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(fontSize: 12, color: Colors.black87)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommentsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedComment01,
                color: Color(0xFF6B7280),
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text('Comments',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _comments.length.toString(),
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_comments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No comments yet.',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            )
          else
            Column(
              children: _comments.map(_buildCommentItem).toList(),
            ),
          const SizedBox(height: 12),
          Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
          const SizedBox(height: 12),
          const Text('Add Comment',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _commentController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Write a comment... type @ to mention someone',
              hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          if (_pendingCommentAttachment != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.attach_file, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _pendingCommentAttachment!.name,
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      setState(() => _pendingCommentAttachment = null),
                  icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _addComment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF131416),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  icon: const Icon(Icons.send, size: 16, color: Colors.white),
                  label: const Text('Post Comment',
                      style: TextStyle(fontSize: 12, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _pickCommentAttachment,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                icon: const Icon(Icons.attach_file,
                    size: 16, color: Color(0xFF131416)),
                label: const Text('Attach',
                    style: TextStyle(fontSize: 12, color: Color(0xFF131416))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(_TaskComment comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFFE5E7EB),
                child: Text(
                  comment.author.isNotEmpty
                      ? comment.author[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF131416),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  comment.author,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                _formatDateTime(comment.createdAt),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (comment.text.isNotEmpty)
            Text(
              comment.text,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          if (comment.attachment != null) ...[
            const SizedBox(height: 8),
            _buildAttachmentRow(comment.attachment!),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachmentsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedAttachment01,
                    color: Color(0xFF6B7280),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text('Attachments',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _attachments.length.toString(),
                      style:
                          const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ),
                ],
              ),
              PopupMenuButton<_AttachmentPickType>(
                onSelected: (value) {
                  switch (value) {
                    case _AttachmentPickType.image:
                      _addAttachment(type: FileType.image);
                      break;
                    case _AttachmentPickType.document:
                      _addAttachment(
                        type: FileType.custom,
                        allowedExtensions: [
                          'pdf',
                          'doc',
                          'docx',
                          'xls',
                          'xlsx',
                          'ppt',
                          'pptx',
                          'txt',
                        ],
                      );
                      break;
                    case _AttachmentPickType.any:
                      _addAttachment(type: FileType.any);
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _AttachmentPickType.image,
                    child: Row(
                      children: [
                        Icon(Icons.image, size: 16),
                        SizedBox(width: 8),
                        Text('Image'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: _AttachmentPickType.document,
                    child: Row(
                      children: [
                        Icon(Icons.description, size: 16),
                        SizedBox(width: 8),
                        Text('Document'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: _AttachmentPickType.any,
                    child: Row(
                      children: [
                        Icon(Icons.attach_file, size: 16),
                        SizedBox(width: 8),
                        Text('Any File'),
                      ],
                    ),
                  ),
                ],
                child: OutlinedButton.icon(
                  onPressed: null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 16, color: Colors.black87),
                  label: const Text('Add',
                      style: TextStyle(fontSize: 12, color: Colors.black87)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_attachments.isEmpty)
            const Text('No attachments yet.',
                style: TextStyle(fontSize: 12, color: Colors.grey))
          else
            Column(
              children: _attachments.map(_buildAttachmentItem).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildAttachmentItem(_TaskAttachment attachment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const HugeIcon(
            icon: HugeIcons.strokeRoundedFile01,
            color: Color(0xFF6B7280),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.name,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatFileSize(attachment.size),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('Comment',
                style: TextStyle(fontSize: 10, color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentRow(_TaskAttachment attachment) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const HugeIcon(
            icon: HugeIcons.strokeRoundedFile01,
            color: Color(0xFF6B7280),
            size: 16,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              attachment.name,
              style: const TextStyle(fontSize: 11, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _formatFileSize(attachment.size),
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
    Color? pillColor,
  }) {
    final valueWidget = pillColor == null
        ? Text(value,
            style: const TextStyle(fontSize: 12, color: Colors.black87))
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: pillColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(value,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: pillColor)),
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HugeIcon(icon: icon, color: const Color(0xFF6B7280), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 90,
                  child: Text(label,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: valueWidget,
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 6),
                  trailing,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactEditIcon(VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        child: const Icon(Icons.edit, size: 14, color: Colors.grey),
      ),
    );
  }

  Widget _buildCollaboratorsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedUserMultiple,
                    color: Color(0xFF6B7280),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text('Collaborators',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _collaborators.length.toString(),
                      style:
                          const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: _toggleCollaboratorPicker,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                icon: const Icon(Icons.add, size: 16, color: Colors.black87),
                label: const Text('Add',
                    style: TextStyle(fontSize: 12, color: Colors.black87)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_showCollaboratorPicker)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCollaboratorName,
                    decoration: const InputDecoration(
                      labelText: 'Select User',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: _collaboratorOptions
                        .map((name) =>
                            DropdownMenuItem(value: name, child: Text(name)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedCollaboratorName = value),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _confirmAddCollaborator,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF131416),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text('Add',
                            style:
                                TextStyle(fontSize: 12, color: Colors.white)),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: _toggleCollaboratorPicker,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text('Cancel',
                            style:
                                TextStyle(fontSize: 12, color: Colors.black87)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (_collaborators.isEmpty)
            const Text('No collaborators yet.',
                style: TextStyle(fontSize: 12, color: Colors.grey))
          else
            Column(
              children: _collaborators.asMap().entries.map((entry) {
                final idx = entry.key;
                final collaborator = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFFE5E7EB),
                        child: Text(
                          collaborator.name.isNotEmpty
                              ? collaborator.name[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF131416),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(collaborator.name,
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600)),
                            if (collaborator.email != null)
                              Text(collaborator.email!,
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          final removed = _collaborators[idx];
                          final createdAt = DateTime.now();
                          setState(() {
                            _collaborators.removeAt(idx);
                            _activities.insert(
                              0,
                              _ActivityItem(
                                title: 'Removed collaborator',
                                subtitle: removed.name,
                                time: createdAt,
                                icon: HugeIcons.strokeRoundedUserRemove01,
                                color: Colors.red,
                              ),
                            );
                          });
                          await _saveTaskDetailToStorage();
                          await _notifyTaskDetail(
                            title: 'Collaborator removed',
                            body: '${removed.name} was removed from "${_task.title}"',
                          );
                        },
                        icon: const Icon(Icons.close,
                            size: 16, color: Colors.red),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history, color: Color(0xFF6B7280), size: 18),
              SizedBox(width: 8),
              Text('Activity History',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          if (_activities.isEmpty)
            const Text('No activity yet.',
                style: TextStyle(fontSize: 12, color: Colors.grey))
          else
            Column(
              children: _activities.map(_buildActivityItem).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(_ActivityItem activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: activity.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: HugeIcon(
              icon: activity.icon,
              color: activity.color,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.title,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(activity.subtitle,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black87)),
                const SizedBox(height: 2),
                Text(_formatDateTime(activity.time),
                    style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return const Color(0xFFE11D48); // red
      case 'high':
        return const Color(0xFFF97316); // orange
      case 'medium':
        return const Color(0xFF2563EB); // blue
      case 'low':
        return const Color(0xFF16A34A); // green
      case 'normal':
        return const Color(0xFF6B7280); // gray
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _formatFileSize(int size) {
    if (size <= 0) return '0 KB';
    final kb = size / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      drawer: AppDrawer(
        selectedIndex: 4,
        onItemSelected: (_) => Navigator.pop(context),
      ),
      appBar: AppBar(
        toolbarHeight: 56,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, size: 28),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Task Detail',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        actions: [
          IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedNotification03,
              color: Colors.black,
              size: 24.0,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TaskNotificationsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            const SizedBox(height: 4),
            _buildHeaderCard(),
            const SizedBox(height: 12),
            _buildCommentsCard(),
            const SizedBox(height: 12),
            _buildAttachmentsCard(),
            const SizedBox(height: 12),
            _buildCollaboratorsCard(),
            const SizedBox(height: 12),
            _buildActivityCard(),
          ],
        ),
      ),
    );
  }
}

class _TaskAttachment {
  final String name;
  final int size;
  final String? path;

  _TaskAttachment({required this.name, required this.size, this.path});
}

class _TaskComment {
  final String author;
  final String text;
  final DateTime createdAt;
  final _TaskAttachment? attachment;

  _TaskComment({
    required this.author,
    required this.text,
    required this.createdAt,
    this.attachment,
  });
}

class _Collaborator {
  final String name;
  final String? email;

  _Collaborator({required this.name, this.email});
}

class _ActivityItem {
  final String title;
  final String subtitle;
  final DateTime time;
  final IconData icon;
  final Color color;

  _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
  });
}

enum _AttachmentPickType { image, document, any }
