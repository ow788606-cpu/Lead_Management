// ignore_for_file: deprecated_member_use, duplicate_ignore

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../managers/auth_manager.dart';
import '../../services/api_config.dart';
import '../../models/lead.dart';
import '../../managers/lead_manager.dart';
import '../../widgets/app_drawer.dart';
import 'detail_lead_screen.dart';

class ViewLeadsScreen extends StatefulWidget {
  final Lead lead;

  const ViewLeadsScreen({super.key, required this.lead});

  @override
  State<ViewLeadsScreen> createState() => _ViewLeadsScreenState();
}

class _ViewLeadsScreenState extends State<ViewLeadsScreen> {
  final _leadManager = LeadManager();
  static const Color _brandBlue = Color(0xFF0B5CFF);
  static const List<String> _defaultActivityOptions = [
    'Called',
    'SMS Sent',
    'Email Sent',
    'Lead Cost',
    'Lead Converted',
  ];
  static const List<String> _defaultCallOutcomeOptions = [
    'Appointment Scheduled',
    'Call Later',
    'Ringing - No Response',
    'Busy',
    'Switched Off / Unavailable',
    'Invalid Number',
  ];
  int _selectedTab = 0;
  bool _isFabExpanded = false;
  bool _isEditingService = false;
  bool _isEditingTags = false;
  late TextEditingController _serviceController;
  late TextEditingController _tagsController;
  final List<Map<String, dynamic>> _activities = [];
  final List<String> _notes = [];
  final List<Map<String, dynamic>> _tasks = [];
  List<String> _activityOptions = List<String>.from(_defaultActivityOptions);
  List<String> _callOutcomeOptions =
      List<String>.from(_defaultCallOutcomeOptions);

  @override
  void initState() {
    super.initState();
    _serviceController = TextEditingController(text: widget.lead.service ?? '');
    _tagsController = TextEditingController(text: widget.lead.tags ?? '');
    _loadStatusOptions();
    _loadLeadHistory();
  }

  @override
  void dispose() {
    _serviceController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _showAddTaskDialog() {
    final taskTitleController = TextEditingController();
    final taskNotesController = TextEditingController();
    String priority = 'Normal';
    final dueDateController = TextEditingController();
    final dueTimeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: StatefulBuilder(
            builder: (context, setDialogState) => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Add New Task',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter')),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Task Title *',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Inter')),
                  const SizedBox(height: 8),
                  TextField(
                    controller: taskTitleController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Notes',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Inter')),
                  const SizedBox(height: 8),
                  TextField(
                    controller: taskNotesController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Priority',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Inter')),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: priority,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Low', child: Text('Low')),
                      DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                      DropdownMenuItem(value: 'High', child: Text('High')),
                      DropdownMenuItem(
                          value: 'Critical', child: Text('Critical')),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => priority = value!),
                  ),
                  const SizedBox(height: 16),
                  const Text('Due Time',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Inter')),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: dueDateController,
                          readOnly: true,
                          decoration: InputDecoration(
                            hintText: '--:--',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            suffixIcon: const Icon(Icons.calendar_today),
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                                context: context,
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2100));
                            if (date != null) {
                              setDialogState(() => dueDateController.text =
                                  '${date.day}/${date.month}/${date.year}');
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: dueTimeController,
                          readOnly: true,
                          decoration: InputDecoration(
                            hintText: '--:--',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            suffixIcon: const Icon(Icons.access_time),
                          ),
                          onTap: () async {
                            final time = await showTimePicker(
                                context: context, initialTime: TimeOfDay.now());
                            if (time != null) {
                              setDialogState(() => dueTimeController.text =
                                  time.format(context));
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      if (taskTitleController.text.isEmpty) {
                        return;
                      }

                      final dueAt = _combineDateAndTime(
                        dueDateController.text,
                        dueTimeController.text,
                      );

                      try {
                        await _saveLeadHistoryEntry(
                          title: taskTitleController.text.trim(),
                          description: taskNotesController.text.trim(),
                          statusId: 13,
                          priority: priority.toLowerCase(),
                          scheduledAt: dueAt,
                          meta: {
                            'activity': 'task',
                            'due_at': dueAt?.toIso8601String(),
                          },
                        );

                        if (!mounted) return;
                        setState(() {
                          _tasks.add({
                            'title': taskTitleController.text.trim(),
                            'notes': taskNotesController.text.trim(),
                            'priority': priority,
                            'dueDate': dueDateController.text,
                            'dueTime': dueTimeController.text,
                            'timestamp': DateTime.now(),
                          });
                        });
                        Navigator.of(this.context).pop();
                      } catch (_) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(content: Text('Failed to save task')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandBlue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Create Task',
                        style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Inter',
                            fontSize: 14)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadLeadHistory() async {
    final leadId = int.tryParse(widget.lead.id);
    if (leadId == null || leadId <= 0) {
      return;
    }
    try {
      final userId = await AuthManager().getUserId() ?? 0;
      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/lead_history.php?lead_id=$leadId&user_id=$userId'),
      );
      if (response.statusCode != 200) {
        return;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
        return;
      }

      final rows = (decoded['data'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();

      final activities = <Map<String, dynamic>>[];
      final notes = <String>[];
      final tasks = <Map<String, dynamic>>[];

      for (final row in rows) {
        final activityType = (row['activity'] ?? '').toString().toLowerCase();
        final statusId =
            int.tryParse((row['status_id'] ?? '0').toString()) ?? 0;
        final createdAt =
            DateTime.tryParse((row['created_at'] ?? '').toString()) ??
                DateTime.now();
        final scheduledAt =
            DateTime.tryParse((row['scheduled_at'] ?? '').toString());
        final dueAt = DateTime.tryParse((row['due_at'] ?? '').toString());
        final schedule = dueAt ?? scheduledAt;
        final description = _stripHtml((row['description'] ?? '').toString());
        final resultNotes = _stripHtml((row['result_notes'] ?? '').toString());
        final effectiveText =
            resultNotes.isNotEmpty ? resultNotes : description;

        final isNote = activityType == 'note' || statusId == 12;
        final isTask = activityType == 'task' || statusId == 13;

        if (isNote) {
          if (effectiveText.isNotEmpty) {
            notes.add(effectiveText);
          }
          continue;
        }

        if (isTask) {
          tasks.add({
            'title': (row['title'] ?? '').toString().trim().isEmpty
                ? (description.isNotEmpty ? description : 'Task')
                : (row['title'] ?? '').toString(),
            'notes': effectiveText,
            'priority':
                _priorityLabel((row['priority'] ?? 'normal').toString()),
            'dueDate': schedule == null ? '' : _formatDate(schedule),
            'dueTime': schedule == null ? '' : _formatTime(schedule),
            'timestamp': createdAt,
          });
          continue;
        }

        activities.add({
          'activity': _activityLabel(activityType),
          'callOutcome': (row['result'] ?? '').toString(),
          'remark': effectiveText,
          'date': schedule == null ? '' : _formatDate(schedule),
          'time': schedule == null ? '' : _formatTime(schedule),
          'lostReason': (row['lost_reason'] ?? '').toString(),
          'dealAmount': (row['amount'] ?? '').toString(),
          'timestamp': createdAt,
        });
      }

      if (!mounted) return;
      setState(() {
        _activities
          ..clear()
          ..addAll(activities);
        _notes
          ..clear()
          ..addAll(notes);
        _tasks
          ..clear()
          ..addAll(tasks);
      });
    } catch (_) {
      // Keep screen usable even if history API fails.
    }
  }

  Future<void> _saveLeadHistoryEntry({
    required String title,
    required String description,
    required int statusId,
    String priority = 'normal',
    String resultNotes = '',
    DateTime? scheduledAt,
    Map<String, dynamic> meta = const {},
  }) async {
    final leadId = int.tryParse(widget.lead.id) ?? 0;
    final userId = await AuthManager().getUserId() ?? 0;
    if (leadId <= 0 || userId <= 0) {
      throw Exception('Invalid lead or user');
    }

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/lead_history.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'lead_id': leadId,
        'user_id': userId,
        'title': title,
        'description': description,
        'status_id': statusId,
        'priority': priority,
        'result_notes': resultNotes,
        'scheduled_at': scheduledAt?.toIso8601String() ?? '',
        'meta': meta,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to save lead history');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
      throw Exception('Invalid lead history response');
    }
  }

  DateTime? _combineDateAndTime(String date, String time) {
    if (date.trim().isEmpty) return null;

    final dateParts = date.split('/');
    if (dateParts.length != 3) return null;

    final day = int.tryParse(dateParts[0]) ?? 0;
    final month = int.tryParse(dateParts[1]) ?? 0;
    final year = int.tryParse(dateParts[2]) ?? 0;
    if (day <= 0 || month <= 0 || year <= 0) return null;

    var hour = 0;
    var minute = 0;
    final normalizedTime = time.trim().toUpperCase();
    final match =
        RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$').firstMatch(normalizedTime);
    if (match != null) {
      hour = int.tryParse(match.group(1) ?? '0') ?? 0;
      minute = int.tryParse(match.group(2) ?? '0') ?? 0;
      final period = match.group(3);
      if (period == 'PM' && hour < 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;
    }

    return DateTime(year, month, day, hour, minute);
  }

  Future<void> _loadStatusOptions() async {
    try {
      final userId = await AuthManager().getUserId() ?? 0;
      if (userId <= 0) return;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/status.php?user_id=$userId'),
      );
      if (response.statusCode != 200) return;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
        return;
      }

      final rows = (decoded['data'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>();

      final mappedActivities = <String>[];
      final mappedCallOutcomes = <String>[];

      for (final row in rows) {
        final name = (row['name'] ?? '').toString().trim();
        if (name.isEmpty) continue;

        final activity = _mapStatusToActivity(name);
        if (activity.isNotEmpty && !mappedActivities.contains(activity)) {
          mappedActivities.add(activity);
        }

        final callOutcome = _mapStatusToCallOutcome(name);
        if (callOutcome.isNotEmpty &&
            !mappedCallOutcomes.contains(callOutcome)) {
          mappedCallOutcomes.add(callOutcome);
        }
      }

      if (!mounted) return;
      setState(() {
        _activityOptions = mappedActivities.isEmpty
            ? List<String>.from(_defaultActivityOptions)
            : mappedActivities;
        _callOutcomeOptions = mappedCallOutcomes.isEmpty
            ? List<String>.from(_defaultCallOutcomeOptions)
            : mappedCallOutcomes;
      });
    } catch (_) {
      // Keep default options if status API fails.
    }
  }

  String _mapStatusToActivity(String statusName) {
    switch (statusName.toLowerCase()) {
      case 'sms sent':
        return 'SMS Sent';
      case 'email sent':
        return 'Email Sent';
      case 'lost':
        return 'Lead Cost';
      case 'converted':
        return 'Lead Converted';
      default:
        return '';
    }
  }

  String _mapStatusToCallOutcome(String statusName) {
    switch (statusName.toLowerCase()) {
      case 'appointment scheduled':
        return 'Appointment Scheduled';
      case 'call later':
        return 'Call Later';
      case 'ringing no response':
        return 'Ringing - No Response';
      case 'busy':
        return 'Busy';
      case 'switched off / unavailable':
        return 'Switched Off / Unavailable';
      case 'invalid number':
        return 'Invalid Number';
      default:
        return '';
    }
  }

  String _stripHtml(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _priorityLabel(String value) {
    switch (value.toLowerCase()) {
      case 'low':
        return 'Low';
      case 'high':
        return 'High';
      case 'critical':
        return 'Critical';
      default:
        return 'Normal';
    }
  }

  String _activityLabel(String activity) {
    if (activity.isEmpty) return 'Activity';
    return activity[0].toUpperCase() + activity.substring(1);
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $suffix';
  }

  void _showAddNoteDialog() {
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Notes',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter')),
              const SizedBox(height: 24),
              TextField(
                controller: noteController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Add your notes here...',
                  hintStyle: const TextStyle(fontStyle: FontStyle.italic),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () async {
                    if (noteController.text.isEmpty) {
                      return;
                    }

                    try {
                      await _saveLeadHistoryEntry(
                        title: 'Note',
                        description: noteController.text.trim(),
                        statusId: 12,
                        meta: const {'activity': 'note'},
                      );

                      if (!mounted) return;
                      setState(() {
                        _notes.add(noteController.text.trim());
                      });
                      Navigator.of(this.context).pop();
                    } catch (_) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text('Failed to save note')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandBlue,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Add Note',
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Inter',
                          fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddActivityDialog() {
    final activityOptions = _activityOptions;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Lead Activity',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter')),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...activityOptions.map(
                (item) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title:
                      Text(item, style: const TextStyle(fontFamily: 'Inter')),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {
                    Navigator.pop(dialogContext);
                    _showActivityEntrySheet(item);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActivityEntrySheet(String activity) {
    final callOutcomeOptions = _callOutcomeOptions;
    const lostReasonOptions = [
      'No Budget',
      'Not Interested',
      'Postponed / Will decide later',
      'No Response',
      'Bought service from someone else',
    ];

    final remarkController = TextEditingController();
    final dateController = TextEditingController();
    final timeController = TextEditingController();
    final dealAmountController = TextEditingController();
    String? selectedCallOutcome;
    String? selectedLostReason;
    final isLeadCost = activity == 'Lead Cost';
    final isLeadConverted = activity == 'Lead Converted';
    final isCompactActivitySheet = isLeadConverted;
    final sheetHeightFactor = isLeadConverted
        ? 0.38
        : isLeadCost
            ? 0.56
            : activity == 'Called'
                ? 0.76
                : 0.62;
    final headerSpacing = isCompactActivitySheet ? 8.0 : 20.0;
    final footerSpacing = isCompactActivitySheet ? 4.0 : 12.0;
    final buttonVerticalPadding = isCompactActivitySheet ? 12.0 : 16.0;

    showDialog(
        context: context,
        builder: (sheetContext) {
          final mediaQuery = MediaQuery.of(sheetContext);

          return StatefulBuilder(
              builder: (context, setSheetState) => Dialog(
                    insetPadding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SizedBox(
                      width: 520,
                      height: mediaQuery.size.height * sheetHeightFactor,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(activity,
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Inter')),
                            SizedBox(height: headerSpacing),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (activity == 'Called') ...[
                                      const Text('Call Outcome',
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              fontFamily: 'Inter')),
                                      const SizedBox(height: 10),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF7F9FC),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                              color: const Color(0xFFDCE4F2)),
                                        ),
                                        child: Column(
                                          children: callOutcomeOptions
                                              .map(
                                                (option) =>
                                                    RadioListTile<String>(
                                                  value: option,
                                                  groupValue:
                                                      selectedCallOutcome,
                                                  activeColor: _brandBlue,
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 12),
                                                  dense: true,
                                                  title: Text(
                                                    option,
                                                    style: const TextStyle(
                                                        fontSize: 14,
                                                        fontFamily: 'Inter'),
                                                  ),
                                                  onChanged: (value) {
                                                    setSheetState(() {
                                                      selectedCallOutcome =
                                                          value;
                                                    });
                                                  },
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                    ],
                                    if (isLeadCost) ...[
                                      const Text('Lost Reason',
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Inter')),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<String>(
                                        value: selectedLostReason,
                                        decoration: InputDecoration(
                                          hintText: 'Select reason',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 16),
                                        ),
                                        items: lostReasonOptions
                                            .map(
                                              (reason) =>
                                                  DropdownMenuItem<String>(
                                                value: reason,
                                                child: Text(
                                                  reason,
                                                  style: const TextStyle(
                                                      fontFamily: 'Inter'),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (value) {
                                          setSheetState(() {
                                            selectedLostReason = value;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      const Text('Remark',
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Inter')),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: remarkController,
                                        minLines: 4,
                                        maxLines: 5,
                                        decoration: InputDecoration(
                                          hintText: 'Enter remark...',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.all(16),
                                          alignLabelWithHint: true,
                                        ),
                                      ),
                                    ] else if (isLeadConverted) ...[
                                      const Text('Deal Amount',
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Inter')),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: dealAmountController,
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                        decoration: InputDecoration(
                                          hintText: 'Enter Amount',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 16),
                                        ),
                                      ),
                                    ] else ...[
                                      const Text('Date',
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Inter')),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: dateController,
                                        readOnly: true,
                                        decoration: InputDecoration(
                                          hintText: 'Select date',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 16),
                                          suffixIcon:
                                              const Icon(Icons.calendar_today),
                                        ),
                                        onTap: () async {
                                          final date = await showDatePicker(
                                            context: sheetContext,
                                            firstDate: DateTime(2000),
                                            lastDate: DateTime(2100),
                                            initialDate: DateTime.now(),
                                          );
                                          if (date != null) {
                                            dateController.text =
                                                '${date.day}/${date.month}/${date.year}';
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      const Text('Time',
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Inter')),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: timeController,
                                        readOnly: true,
                                        decoration: InputDecoration(
                                          hintText: 'Select time',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 16),
                                          suffixIcon:
                                              const Icon(Icons.access_time),
                                        ),
                                        onTap: () async {
                                          final time = await showTimePicker(
                                            context: sheetContext,
                                            initialTime: TimeOfDay.now(),
                                          );
                                          if (time != null) {
                                            timeController.text =
                                                _formatTimeOfDay(time);
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      const Text('Remark *',
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Inter')),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: remarkController,
                                        minLines: 4,
                                        maxLines: 6,
                                        decoration: InputDecoration(
                                          hintText: 'Enter remark...',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.all(16),
                                          alignLabelWithHint: true,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: footerSpacing),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (activity == 'Called' &&
                                      selectedCallOutcome == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Please select a call outcome'),
                                      ),
                                    );
                                    return;
                                  }
                                  if (isLeadCost &&
                                      selectedLostReason == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Please select lost reason'),
                                      ),
                                    );
                                    return;
                                  }
                                  if (isLeadConverted &&
                                      dealAmountController.text
                                          .trim()
                                          .isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Please enter deal amount'),
                                      ),
                                    );
                                    return;
                                  }
                                  if (!isLeadCost &&
                                      !isLeadConverted &&
                                      remarkController.text.trim().isEmpty) {
                                    return;
                                  }
                                  final scheduledAt =
                                      isLeadCost || isLeadConverted
                                          ? null
                                          : _combineDateAndTime(
                                              dateController.text.trim(),
                                              timeController.text.trim(),
                                            );

                                  try {
                                    await _saveLeadHistoryEntry(
                                      title: activity,
                                      description: isLeadConverted
                                          ? ''
                                          : remarkController.text.trim(),
                                      statusId: 0,
                                      resultNotes: isLeadCost
                                          ? remarkController.text.trim()
                                          : '',
                                      scheduledAt: scheduledAt,
                                      meta: {
                                        'activity': activity.toLowerCase(),
                                        'result': selectedCallOutcome ?? '',
                                        'lost_reason': isLeadCost
                                            ? selectedLostReason
                                            : '',
                                        'amount': isLeadConverted
                                            ? dealAmountController.text.trim()
                                            : '',
                                      },
                                    );

                                    if (!mounted) return;
                                    setState(() {
                                      _activities.add({
                                        'activity': activity,
                                        'callOutcome':
                                            selectedCallOutcome ?? '',
                                        'remark': isLeadConverted
                                            ? ''
                                            : remarkController.text.trim(),
                                        'date': isLeadCost || isLeadConverted
                                            ? ''
                                            : dateController.text.trim(),
                                        'time': isLeadCost || isLeadConverted
                                            ? ''
                                            : timeController.text.trim(),
                                        'lostReason': isLeadCost
                                            ? selectedLostReason
                                            : '',
                                        'dealAmount': isLeadConverted
                                            ? dealAmountController.text.trim()
                                            : '',
                                        'timestamp': DateTime.now(),
                                      });
                                    });
                                    Navigator.of(this.context).pop();
                                    ScaffoldMessenger.of(this.context)
                                        .showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Activity added successfully!'),
                                      ),
                                    );
                                  } catch (_) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(this.context)
                                        .showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Failed to save activity'),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _brandBlue,
                                  minimumSize:
                                      Size(0, isCompactActivitySheet ? 44 : 53),
                                  padding: EdgeInsets.symmetric(
                                      vertical: buttonVerticalPadding),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                    activity == 'Lead Cost'
                                        ? 'Update Call'
                                        : 'Update',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'Inter',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ));
        });
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.lead.contactName.trim().isEmpty
        ? 'Unknown Lead'
        : widget.lead.contactName.trim();
    final avatarInitial = displayName[0].toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: AppDrawer(
        selectedIndex: 1,
        onItemSelected: (_) => Navigator.pop(context),
      ),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Cloop'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'edit') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailLeadScreen(
                      lead: widget.lead,
                      startInEditMode: true,
                    ),
                  ),
                );
                if (!context.mounted) return;
                Navigator.pop(context);
              } else if (value == 'delete') {
                final shouldDelete = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Delete Lead'),
                    content: const Text(
                        'Are you sure you want to delete this lead?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('Delete',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (!context.mounted) return;
                if (shouldDelete == true) {
                  _leadManager.deleteLead(widget.lead.id);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lead deleted successfully')),
                  );
                }
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'edit',
                child: Text('Edit'),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Text('Delete'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isFabExpanded) ...[
            _buildQuickActionButton(
              label: 'Activity',
              icon: Icons.home_outlined,
              onTap: () {
                setState(() {
                  _selectedTab = 0;
                  _isFabExpanded = false;
                });
                _showAddActivityDialog();
              },
            ),
            const SizedBox(height: 10),
            _buildQuickActionButton(
              label: 'Notes',
              icon: Icons.note_outlined,
              onTap: () {
                setState(() {
                  _selectedTab = 1;
                  _isFabExpanded = false;
                });
                _showAddNoteDialog();
              },
            ),
            const SizedBox(height: 10),
            _buildQuickActionButton(
              label: 'Tasks',
              icon: Icons.task_outlined,
              onTap: () {
                setState(() {
                  _selectedTab = 2;
                  _isFabExpanded = false;
                });
                _showAddTaskDialog();
              },
            ),
            const SizedBox(height: 12),
          ],
          FloatingActionButton(
            heroTag: 'lead_details_fab',
            backgroundColor: _brandBlue,
            onPressed: () {
              setState(() => _isFabExpanded = !_isFabExpanded);
            },
            child: Icon(
              _isFabExpanded ? Icons.close : Icons.add,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lead Details',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter')),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: _brandBlue,
                    child: Text(
                      avatarInitial,
                      style: const TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter'),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 20),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.lead.phone ?? '',
                    style: const TextStyle(
                        fontSize: 14, color: Colors.grey, fontFamily: 'Inter'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Personal Details',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter')),
                  const SizedBox(height: 12),
                  const SizedBox(height: 10),
                  _buildDetailRow(
                      Icons.email_outlined, widget.lead.email ?? 'N/A'),
                  const SizedBox(height: 10),
                  _buildDetailRow(
                      Icons.phone_outlined, widget.lead.phone ?? 'N/A'),
                  const SizedBox(height: 10),
                  _buildDetailRow(Icons.calendar_today_outlined,
                      'Joined on ${widget.lead.createdAt.day} ${_getMonthName(widget.lead.createdAt.month)}, ${widget.lead.createdAt.year}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Interested Services',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter')),
                      TextButton.icon(
                        onPressed: () => setState(
                            () => _isEditingService = !_isEditingService),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: Text(_isEditingService ? 'Save' : 'Edit'),
                        style:
                            TextButton.styleFrom(foregroundColor: _brandBlue),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _isEditingService
                      ? TextField(
                          controller: _serviceController,
                          decoration: InputDecoration(
                            hintText: 'Enter service',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        )
                      : widget.lead.service != null
                          ? Wrap(
                              spacing: 8,
                              children: [
                                Chip(
                                  label: Text(widget.lead.service!,
                                      style: const TextStyle(
                                          fontSize: 12, fontFamily: 'Inter')),
                                  backgroundColor: const Color(0xFFEAF1FF),
                                  labelStyle:
                                      const TextStyle(color: _brandBlue),
                                ),
                              ],
                            )
                          : const Text('No services',
                              style: TextStyle(
                                  color: Colors.grey, fontFamily: 'Inter')),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tags',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter')),
                      TextButton.icon(
                        onPressed: () =>
                            setState(() => _isEditingTags = !_isEditingTags),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: Text(_isEditingTags ? 'Save' : 'Edit'),
                        style:
                            TextButton.styleFrom(foregroundColor: _brandBlue),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _isEditingTags
                      ? TextField(
                          controller: _tagsController,
                          decoration: InputDecoration(
                            hintText: 'Enter tags',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        )
                      : widget.lead.tags != null
                          ? Wrap(
                              spacing: 8,
                              children: [
                                Chip(
                                  label: Text(widget.lead.tags!,
                                      style: const TextStyle(
                                          fontSize: 12, fontFamily: 'Inter')),
                                  backgroundColor: Colors.grey[200],
                                  deleteIcon: const Icon(Icons.close, size: 16),
                                  onDeleted: () {},
                                ),
                              ],
                            )
                          : const Text('Select Tags',
                              style: TextStyle(
                                  color: Colors.grey, fontFamily: 'Inter')),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedTab == 0
                                  ? _brandBlue
                                  : Colors.transparent,
                              borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.home_outlined,
                                    size: 18,
                                    color: _selectedTab == 0
                                        ? Colors.white
                                        : Colors.grey),
                                const SizedBox(width: 8),
                                Text('Activity',
                                    style: TextStyle(
                                        color: _selectedTab == 0
                                            ? Colors.white
                                            : Colors.grey,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedTab == 1
                                  ? _brandBlue
                                  : Colors.transparent,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.note_outlined,
                                    size: 18,
                                    color: _selectedTab == 1
                                        ? Colors.white
                                        : Colors.grey),
                                const SizedBox(width: 8),
                                Text('Notes',
                                    style: TextStyle(
                                        color: _selectedTab == 1
                                            ? Colors.white
                                            : Colors.grey,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 2),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedTab == 2
                                  ? _brandBlue
                                  : Colors.transparent,
                              borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(12)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.task_outlined,
                                    size: 18,
                                    color: _selectedTab == 2
                                        ? Colors.white
                                        : Colors.grey),
                                const SizedBox(width: 8),
                                Text('Tasks',
                                    style: TextStyle(
                                        color: _selectedTab == 2
                                            ? Colors.white
                                            : Colors.grey,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: _selectedTab == 0
                        ? Column(
                            children: [
                              const Text('Lead Activity',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Inter')),
                              const SizedBox(height: 16),
                              _activities.isEmpty
                                  ? const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 24),
                                      child: Text('No activity yet',
                                          style: TextStyle(
                                              color: Colors.grey,
                                              fontFamily: 'Inter')),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: _activities.length,
                                      itemBuilder: (context, index) {
                                        final activity = _activities[index];
                                        return Card(
                                          margin:
                                              const EdgeInsets.only(bottom: 12),
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                            0xFFEAF1FF),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(4),
                                                      ),
                                                      child: Text(
                                                        activity['activity'] ??
                                                            '',
                                                        style: const TextStyle(
                                                            color: _brandBlue,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontFamily:
                                                                'Inter'),
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                    Text(
                                                      '${activity['timestamp'].day}/${activity['timestamp'].month}/${activity['timestamp'].year}',
                                                      style: const TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.grey,
                                                          fontFamily: 'Inter'),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  activity['remark'] ?? '',
                                                  style: const TextStyle(
                                                      fontSize: 13,
                                                      fontFamily: 'Inter'),
                                                ),
                                                if (activity['callOutcome']
                                                        ?.isNotEmpty ??
                                                    false) ...[
                                                  const SizedBox(height: 8),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 10,
                                                        vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFFF4F7FC),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              999),
                                                    ),
                                                    child: Text(
                                                      activity['callOutcome'],
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          color: _brandBlue,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontFamily: 'Inter'),
                                                    ),
                                                  ),
                                                ],
                                                if (activity['date']
                                                        ?.isNotEmpty ??
                                                    false) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Date: ${activity['date']} ${activity['time']?.isNotEmpty ?? false ? 'Time: ${activity['time']}' : ''}',
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey,
                                                        fontFamily: 'Inter'),
                                                  ),
                                                ],
                                                if (activity['lostReason']
                                                        ?.isNotEmpty ??
                                                    false) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Reason: ${activity['lostReason']}',
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey,
                                                        fontFamily: 'Inter'),
                                                  ),
                                                ],
                                                if (activity['dealAmount']
                                                        ?.isNotEmpty ??
                                                    false) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Amount: \u20B9${activity['dealAmount']}',
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.green,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontFamily: 'Inter'),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ],
                          )
                        : _selectedTab == 1
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Notes',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Inter')),
                                  const SizedBox(height: 16),
                                  _notes.isEmpty
                                      ? const Padding(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 24),
                                          child: Text('No notes yet',
                                              style: TextStyle(
                                                  color: Colors.grey,
                                                  fontFamily: 'Inter')),
                                        )
                                      : ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: _notes.length,
                                          itemBuilder: (context, index) {
                                            return Card(
                                              margin: const EdgeInsets.only(
                                                  bottom: 12),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                child: Text(
                                                  _notes[index],
                                                  style: const TextStyle(
                                                      fontSize: 14,
                                                      fontFamily: 'Inter'),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Tasks',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Inter')),
                                  const SizedBox(height: 16),
                                  _tasks.isEmpty
                                      ? const Padding(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 24),
                                          child: Text('No tasks yet',
                                              style: TextStyle(
                                                  color: Colors.grey,
                                                  fontFamily: 'Inter')),
                                        )
                                      : ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: _tasks.length,
                                          itemBuilder: (context, index) {
                                            final task = _tasks[index];
                                            return Card(
                                              margin: const EdgeInsets.only(
                                                  bottom: 12),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            task['title'] ?? '',
                                                            style: const TextStyle(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontFamily:
                                                                    'Inter'),
                                                          ),
                                                        ),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 4),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: task['priority'] ==
                                                                    'Critical'
                                                                ? Colors.red[50]
                                                                : task['priority'] ==
                                                                        'High'
                                                                    ? Colors.orange[
                                                                        50]
                                                                    : task['priority'] ==
                                                                            'Low'
                                                                        ? Colors.green[
                                                                            50]
                                                                        : const Color(
                                                                            0xFFEAF1FF),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        4),
                                                          ),
                                                          child: Text(
                                                            task['priority'] ??
                                                                '',
                                                            style: TextStyle(
                                                                color: task['priority'] ==
                                                                        'Critical'
                                                                    ? Colors.red
                                                                    : task['priority'] ==
                                                                            'High'
                                                                        ? Colors
                                                                            .orange
                                                                        : task['priority'] ==
                                                                                'Low'
                                                                            ? Colors
                                                                                .green
                                                                            : _brandBlue,
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontFamily:
                                                                    'Inter'),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    if (task['notes']
                                                            ?.isNotEmpty ??
                                                        false) ...[
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        task['notes'] ?? '',
                                                        style: const TextStyle(
                                                            fontSize: 13,
                                                            color: Colors.grey,
                                                            fontFamily:
                                                                'Inter'),
                                                      ),
                                                    ],
                                                    if (task['dueDate']
                                                            ?.isNotEmpty ??
                                                        false) ...[
                                                      const SizedBox(height: 8),
                                                      Row(
                                                        children: [
                                                          const Icon(
                                                              Icons.access_time,
                                                              size: 14,
                                                              color:
                                                                  Colors.grey),
                                                          const SizedBox(
                                                              width: 4),
                                                          Text(
                                                            '${task['dueDate']} ${task['dueTime'] ?? ''}',
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color: Colors
                                                                        .grey,
                                                                    fontFamily:
                                                                        'Inter'),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                ],
                              ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 14, fontFamily: 'Inter', color: Colors.black87))),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _brandBlue,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
        ),
        const SizedBox(width: 8),
        FloatingActionButton(
          mini: true,
          heroTag: 'lead_details_$label',
          backgroundColor: _brandBlue,
          onPressed: onTap,
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ],
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $suffix';
  }

  String _getMonthName(int month) {
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
}
