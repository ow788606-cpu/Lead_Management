import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/lead.dart';

typedef NotificationCallback = void Function(Lead lead);
typedef TaskNotificationCallback = void Function(Map<String, dynamic> task, Lead lead);
typedef ActivityNotificationCallback = void Function(Map<String, dynamic> activity, Lead lead);

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final List<NotificationCallback> _callbacks = [];
  final List<TaskNotificationCallback> _taskCallbacks = [];
  final List<ActivityNotificationCallback> _activityCallbacks = [];

  // Single timer — no duplicate online/offline timers
  Timer? _timer;

  // Notified IDs reset daily so overdue items re-notify each day
  final Map<String, DateTime> _notifiedLeads = {};
  final Map<String, DateTime> _notifiedTasks = {};
  final Map<String, DateTime> _notifiedActivities = {};
  final Map<String, DateTime> _notifiedOverdueTasks = {};

  bool _isInitialized = false;

  List<Lead> _cachedLeads = [];
  List<Map<String, dynamic>> _cachedTasks = [];
  List<Map<String, dynamic>> _cachedActivities = [];

  bool get isInitialized => _isInitialized;

  // ─── Initialization ───────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      final initialized = await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
        onDidReceiveNotificationResponse: _onTapped,
      );
      if (initialized != true) throw Exception('Plugin initialize() returned false');

      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        await androidImpl.requestNotificationsPermission();
      }

      _isInitialized = true;
      debugPrint('✅ NotificationService initialized');
    } catch (e) {
      _isInitialized = false;
      throw Exception('NotificationService init failed: $e');
    }
  }

  // ─── Notification tap handling ────────────────────────────────────────────

  String? _pendingPayload;
  String? get pendingPayload => _pendingPayload;
  void clearPendingPayload() => _pendingPayload = null;

  void _onTapped(NotificationResponse response) {
    if (response.payload != null) _pendingPayload = response.payload;
  }

  // ─── Monitoring ───────────────────────────────────────────────────────────

  void startMonitoring(
    List<Lead> leads, {
    List<Map<String, dynamic>>? allTasks,
    List<Map<String, dynamic>>? allActivities,
  }) {
    if (!_isInitialized) {
      debugPrint('⚠️ NotificationService not initialized');
      return;
    }

    _cachedLeads = List.from(leads);
    _cachedTasks = allTasks != null ? List.from(allTasks) : _cachedTasks;
    _cachedActivities = allActivities != null ? List.from(allActivities) : _cachedActivities;

    _saveToStorage();

    // Only start the timer if not already running
    if (_timer == null || !_timer!.isActive) {
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 30), (_) => _runChecks());
      debugPrint('🔔 Notification timer started');
    }

    debugPrint('🔔 Monitoring updated — leads: ${_cachedLeads.length}, tasks: ${_cachedTasks.length}, activities: ${_cachedActivities.length}');
  }

  void updateCachedData({
    List<Lead>? leads,
    List<Map<String, dynamic>>? tasks,
    List<Map<String, dynamic>>? activities,
  }) {
    if (leads != null) _cachedLeads = List.from(leads);
    if (tasks != null) _cachedTasks = List.from(tasks);
    if (activities != null) _cachedActivities = List.from(activities);
    _saveToStorage();
    debugPrint('💾 Cached data updated — leads: ${_cachedLeads.length}, tasks: ${_cachedTasks.length}, activities: ${_cachedActivities.length}');
  }

  void forceNotificationCheck() {
    if (!_isInitialized) return;
    debugPrint('🔄 Force notification check');
    _runChecks();
  }

  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }

  // ─── Core check runner ────────────────────────────────────────────────────

  void _runChecks() {
    _pruneOldNotifiedIds();
    _checkLeads(_cachedLeads);
    _checkTasks(_cachedTasks, _cachedLeads);
    _checkOverdueTasks(_cachedTasks, _cachedLeads);
    _checkActivities(_cachedActivities, _cachedLeads);
  }

  /// Remove notified IDs older than 6 hours so they can re-notify if still pending
  void _pruneOldNotifiedIds() {
    final cutoff = DateTime.now().subtract(const Duration(hours: 6));
    _notifiedLeads.removeWhere((_, dt) => dt.isBefore(cutoff));
    _notifiedTasks.removeWhere((_, dt) => dt.isBefore(cutoff));
    _notifiedActivities.removeWhere((_, dt) => dt.isBefore(cutoff));
    _notifiedOverdueTasks.removeWhere((_, dt) => dt.isBefore(cutoff));
  }

  // ─── Lead checks ─────────────────────────────────────────────────────────

  void _checkLeads(List<Lead> leads) {
    final now = DateTime.now();
    for (final lead in leads) {
      if (lead.followUpDate == null || lead.isCompleted) continue;
      if (_notifiedLeads.containsKey(lead.id)) continue;

      final followUpDt = _buildFollowUpDateTime(lead);
      final diff = followUpDt.difference(now).inMinutes;

      debugPrint('📅 Lead "${lead.contactName}" — diff: $diff min');

      // Notify only at exactly 5 minutes before (4-6 min window for 30s timer)
      if (diff >= 4 && diff <= 6) {
        _notifiedLeads[lead.id] = now;
        _showNotification(
          id: lead.id.hashCode,
          title: 'Lead Follow-up Reminder',
          body: 'Follow-up with ${lead.contactName} is due in 5 minutes',
          payload: 'lead:${lead.id}',
          channel: _leadChannel,
        );
        for (final cb in _callbacks) { cb(lead); }
        debugPrint('✅ Lead notification sent: ${lead.contactName}');
      }
    }
  }

  DateTime _buildFollowUpDateTime(Lead lead) {
    int hour = 10, minute = 0;
    if (lead.followUpTime != null && lead.followUpTime!.isNotEmpty) {
      final m = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)', caseSensitive: false)
          .firstMatch(lead.followUpTime!);
      if (m != null) {
        hour = int.parse(m.group(1)!);
        minute = int.parse(m.group(2)!);
        final isPM = m.group(3)!.toUpperCase() == 'PM';
        if (isPM && hour != 12) hour += 12;
        if (!isPM && hour == 12) hour = 0;
      }
    }
    return DateTime(
      lead.followUpDate!.year,
      lead.followUpDate!.month,
      lead.followUpDate!.day,
      hour,
      minute,
    );
  }

  // ─── Task checks ─────────────────────────────────────────────────────────

  void _checkTasks(List<Map<String, dynamic>> tasks, List<Lead> leads) {
    final now = DateTime.now();
    for (final task in tasks) {
      if (task['dueDate'] == null) continue;
      if (task['isCompleted'] == true) continue;
      final key = task['id'].toString();
      if (_notifiedTasks.containsKey(key)) continue;

      final dueDt = _buildTaskDateTime(task);
      final diff = dueDt.difference(now).inMinutes;

      debugPrint('📋 Task "${task['title']}" — diff: $diff min');

      // Notify only at exactly 5 minutes before (4-6 min window for 30s timer)
      if (diff >= 4 && diff <= 6) {
        _notifiedTasks[key] = now;
        final lead = _findLead(leads, task['leadId']);
        final body = lead != null
            ? 'Task "${task['title']}" for ${lead.contactName} is due in 5 minutes'
            : 'Task "${task['title']}" is due in 5 minutes';
        _showNotification(
          id: task['id'].hashCode + 10000,
          title: 'Task Reminder',
          body: body,
          payload: 'task:${task['id']}:${lead?.id ?? ''}',
          channel: _taskChannel,
        );
        if (lead != null) {
          for (final cb in _taskCallbacks) { cb(task, lead); }
        }
        debugPrint('✅ Task notification sent: ${task['title']}');
      }
    }
  }

  DateTime _buildTaskDateTime(Map<String, dynamic> task) {
    // dueDate can be DateTime (from TaskManager) or String (from storage)
    final raw = task['dueDate'];
    final dueDate = raw is DateTime ? raw : DateTime.parse(raw.toString());
    final timeStr = task['dueTime'] as String? ?? '12:00 PM';
    int hour = 12, minute = 0;
    final m = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)', caseSensitive: false)
        .firstMatch(timeStr);
    if (m != null) {
      hour = int.parse(m.group(1)!);
      minute = int.parse(m.group(2)!);
      final isPM = m.group(3)!.toUpperCase() == 'PM';
      if (isPM && hour != 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;
    }
    return DateTime(dueDate.year, dueDate.month, dueDate.day, hour, minute);
  }

  // ─── Overdue Task checks ─────────────────────────────────────────────────

  void _checkOverdueTasks(List<Map<String, dynamic>> tasks, List<Lead> leads) {
    final now = DateTime.now();
    for (final task in tasks) {
      if (task['dueDate'] == null) continue;
      if (task['isCompleted'] == true) continue;
      final key = 'overdue_${task['id']}';
      if (_notifiedOverdueTasks.containsKey(key)) continue;

      final dueDt = _buildTaskDateTime(task);
      final hoursSinceOverdue = now.difference(dueDt).inHours;

      debugPrint('⏰ Task "${task['title']}" — overdue hours: $hoursSinceOverdue');

      // Notify if task is overdue by 24 hours (23-25 hour window)
      if (hoursSinceOverdue >= 23 && hoursSinceOverdue <= 25) {
        _notifiedOverdueTasks[key] = now;
        final lead = _findLead(leads, task['leadId']);
        final body = lead != null
            ? 'Task "${task['title']}" for ${lead.contactName} is overdue by 24 hours'
            : 'Task "${task['title']}" is overdue by 24 hours';
        _showNotification(
          id: task['id'].hashCode + 30000,
          title: '⚠️ Task Overdue',
          body: body,
          payload: 'task_overdue:${task['id']}:${lead?.id ?? ''}',
          channel: _overdueTaskChannel,
        );
        if (lead != null) {
          for (final cb in _taskCallbacks) { cb(task, lead); }
        }
        debugPrint('✅ Overdue task notification sent: ${task['title']}');
      }
    }
  }

  // ─── Activity checks ──────────────────────────────────────────────────────

  void _checkActivities(List<Map<String, dynamic>> activities, List<Lead> leads) {
    final now = DateTime.now();
    for (final activity in activities) {
      if (activity['scheduledDate'] == null) continue;
      final key = activity['id'].toString();
      if (_notifiedActivities.containsKey(key)) continue;

      final rawDt = activity['scheduledDate'];
      final scheduledDt = rawDt is DateTime ? rawDt : DateTime.parse(rawDt.toString());
      final diff = scheduledDt.difference(now).inMinutes;

      debugPrint('📞 Activity "${activity['title']}" — diff: $diff min');

      // Notify only at exactly 5 minutes before (4-6 min window for 30s timer)
      if (diff >= 4 && diff <= 6) {
        _notifiedActivities[key] = now;
        final lead = _findLead(leads, activity['leadId']);
        if (lead == null) continue;
        final activityType = activity['title'] ?? 'Activity';
        _showNotification(
          id: activity['id'].hashCode + 20000,
          title: 'Activity Reminder',
          body: _activityMsg(activityType, lead.contactName),
          payload: 'activity:${activity['id']}:${lead.id}',
          channel: _activityChannel,
        );
        for (final cb in _activityCallbacks) { cb(activity, lead); }
        debugPrint('✅ Activity notification sent: $activityType');
      }
    }
  }

  String _activityMsg(String type, String name) {
    switch (type) {
      case 'Called - Call Later': return 'Time to call back $name';
      case 'Called - Appointment Scheduled': return 'Appointment with $name is due';
      case 'Called - Ringing – No Response': return 'Retry calling $name';
      case 'Called - Busy': return 'Retry calling $name (was busy)';
      case 'Called - Switched Off / Unavailable': return 'Retry calling $name (unavailable)';
      case 'SMS Sent': return 'Follow up on SMS sent to $name';
      case 'Email Sent': return 'Follow up on email sent to $name';
      default: return 'Activity reminder for $name';
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Lead? _findLead(List<Lead> leads, dynamic leadId) {
    if (leads.isEmpty) return null;
    if (leadId == null) return leads.first;
    try {
      return leads.firstWhere((l) => l.id == leadId);
    } catch (_) {
      return leads.first;
    }
  }

  // ─── Notification channels ────────────────────────────────────────────────

  static const _leadChannel = AndroidNotificationDetails(
    'lead_notifications', 'Lead Follow-up Notifications',
    channelDescription: 'Notifications for lead follow-ups',
    importance: Importance.max, priority: Priority.high,
    autoCancel: true, ongoing: false, showWhen: true,
  );

  static const _taskChannel = AndroidNotificationDetails(
    'task_notifications', 'Task Reminder Notifications',
    channelDescription: 'Notifications for task reminders',
    importance: Importance.max, priority: Priority.high,
    autoCancel: true, ongoing: false, showWhen: true,
  );

  static const _activityChannel = AndroidNotificationDetails(
    'activity_notifications', 'Activity Reminder Notifications',
    channelDescription: 'Notifications for scheduled activities',
    importance: Importance.max, priority: Priority.high,
    autoCancel: true, ongoing: false, showWhen: true,
  );

  static const _overdueTaskChannel = AndroidNotificationDetails(
    'overdue_task_notifications', 'Overdue Task Notifications',
    channelDescription: 'Notifications for tasks overdue by 24 hours',
    importance: Importance.max, priority: Priority.high,
    autoCancel: true, ongoing: false, showWhen: true,
  );

  static const _iosDetails = DarwinNotificationDetails(
    presentAlert: true, presentBadge: true, presentSound: true,
  );

  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
    required AndroidNotificationDetails channel,
  }) async {
    try {
      await _plugin.show(
        id, title, body,
        NotificationDetails(android: channel, iOS: _iosDetails),
        payload: payload,
      );
    } catch (e) {
      debugPrint('❌ Failed to show notification: $e');
    }
  }

  // ─── Scheduled notifications (app closed) ────────────────────────────────

  Future<void> scheduleNotificationsForClosedApp(
    List<Lead> leads, {
    List<Map<String, dynamic>>? allTasks,
    List<Map<String, dynamic>>? allActivities,
  }) async {
    if (!_isInitialized) return;
    await _plugin.cancelAll();
    final now = DateTime.now();

    for (final lead in leads) {
      if (lead.followUpDate == null || lead.isCompleted) continue;
      final dt = _buildFollowUpDateTime(lead);
      if (dt.isAfter(now)) {
        await _scheduleOne(
          id: lead.id.hashCode,
          title: 'Lead Follow-up Reminder',
          body: 'Follow-up with ${lead.contactName} is due now',
          scheduledDt: dt,
          payload: 'lead:${lead.id}',
          channel: _leadChannel,
        );
      }
    }

    for (final task in allTasks ?? []) {
      if (task['dueDate'] == null || task['isCompleted'] == true) continue;
      final dt = _buildTaskDateTime(task);
      if (dt.isAfter(now)) {
        final lead = _findLead(leads, task['leadId']);
        await _scheduleOne(
          id: task['id'].hashCode + 10000,
          title: 'Task Reminder',
          body: 'Task "${task['title']}" is due now${lead != null ? ' for ${lead.contactName}' : ''}',
          scheduledDt: dt,
          payload: 'task:${task['id']}:${lead?.id ?? ''}',
          channel: _taskChannel,
        );
      }
    }

    for (final activity in allActivities ?? []) {
      if (activity['scheduledDate'] == null) continue;
      final raw = activity['scheduledDate'];
      final dt = raw is DateTime ? raw : DateTime.parse(raw.toString());
      if (dt.isAfter(now)) {
        final lead = _findLead(leads, activity['leadId']);
        final type = activity['title'] ?? 'Activity';
        await _scheduleOne(
          id: activity['id'].hashCode + 20000,
          title: 'Activity Reminder',
          body: lead != null ? _activityMsg(type, lead.contactName) : 'Activity "$type" is due now',
          scheduledDt: dt,
          payload: 'activity:${activity['id']}:${lead?.id ?? ''}',
          channel: _activityChannel,
        );
      }
    }

    debugPrint('✅ Scheduled notifications for closed app');
  }

  Future<void> _scheduleOne({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDt,
    required String payload,
    required AndroidNotificationDetails channel,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id, title, body,
        tz.TZDateTime.from(scheduledDt, tz.local),
        NotificationDetails(android: channel, iOS: _iosDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      debugPrint('❌ Failed to schedule notification: $e');
    }
  }

  // ─── Persistence ──────────────────────────────────────────────────────────

  Future<void> initializeOfflineNotifications() async {
    await _loadFromStorage();
    if (_cachedLeads.isNotEmpty || _cachedTasks.isNotEmpty || _cachedActivities.isNotEmpty) {
      debugPrint('📶 Offline data loaded — leads: ${_cachedLeads.length}, tasks: ${_cachedTasks.length}, activities: ${_cachedActivities.length}');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final leadsJson = _cachedLeads.map((l) => {
        'id': l.id, 'contactName': l.contactName, 'email': l.email,
        'phone': l.phone, 'service': l.service, 'tags': l.tags,
        'notes': l.notes, 'followUpDate': l.followUpDate?.toIso8601String(),
        'followUpTime': l.followUpTime, 'createdAt': l.createdAt.toIso8601String(),
        'isCompleted': l.isCompleted,
      }).toList();
      await prefs.setString('cached_leads_for_notifications', jsonEncode(leadsJson));

      final tasksJson = _cachedTasks.map((t) => {
        'id': t['id'], 'title': t['title'], 'description': t['description'],
        'dueDate': (t['dueDate'] as DateTime).toIso8601String(),
        'dueTime': t['dueTime'], 'isCompleted': t['isCompleted'],
        'priority': t['priority'], 'leadId': t['leadId'],
      }).toList();
      await prefs.setString('cached_tasks_for_notifications', jsonEncode(tasksJson));

      final activitiesJson = _cachedActivities.map((a) => {
        'id': a['id'], 'title': a['title'], 'description': a['description'],
        'scheduledDate': a['scheduledDate'] != null
            ? (a['scheduledDate'] as DateTime).toIso8601String()
            : null,
        'leadId': a['leadId'],
      }).toList();
      await prefs.setString('cached_activities_for_notifications', jsonEncode(activitiesJson));
    } catch (e) {
      debugPrint('❌ Error saving cached data: $e');
    }
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final leadsStr = prefs.getString('cached_leads_for_notifications');
      if (leadsStr != null) {
        _cachedLeads = (jsonDecode(leadsStr) as List).map((d) => Lead(
          id: d['id'], contactName: d['contactName'], email: d['email'],
          phone: d['phone'], service: d['service'], tags: d['tags'],
          notes: d['notes'],
          followUpDate: d['followUpDate'] != null ? DateTime.parse(d['followUpDate']) : null,
          followUpTime: d['followUpTime'],
          createdAt: DateTime.parse(d['createdAt']),
          isCompleted: d['isCompleted'] ?? false,
        )).toList();
      }

      final tasksStr = prefs.getString('cached_tasks_for_notifications');
      if (tasksStr != null) {
        _cachedTasks = (jsonDecode(tasksStr) as List).map<Map<String, dynamic>>((d) => {
          'id': d['id'], 'title': d['title'], 'description': d['description'],
          'dueDate': DateTime.parse(d['dueDate']), 'dueTime': d['dueTime'],
          'isCompleted': d['isCompleted'], 'priority': d['priority'],
          'leadId': d['leadId'],
        }).toList();
      }

      final activitiesStr = prefs.getString('cached_activities_for_notifications');
      if (activitiesStr != null) {
        _cachedActivities = (jsonDecode(activitiesStr) as List).map<Map<String, dynamic>>((d) => {
          'id': d['id'], 'title': d['title'], 'description': d['description'],
          'scheduledDate': d['scheduledDate'] != null ? DateTime.parse(d['scheduledDate']) : null,
          'leadId': d['leadId'],
        }).toList();
      }
    } catch (e) {
      debugPrint('❌ Error loading cached data: $e');
    }
  }

  // ─── Test / utility ───────────────────────────────────────────────────────

  Future<void> showTestNotification() async {
    if (!_isInitialized) return;
    await _showNotification(
      id: 999999,
      title: 'Test Notification',
      body: 'Notification system is working correctly',
      payload: 'test:notification',
      channel: const AndroidNotificationDetails(
        'test_notifications', 'Test Notifications',
        importance: Importance.max, priority: Priority.high,
        autoCancel: true, ongoing: false,
      ),
    );
  }

  void clearNotificationTracking() {
    _notifiedLeads.clear();
    _notifiedTasks.clear();
    _notifiedActivities.clear();
    _notifiedOverdueTasks.clear();
    debugPrint('🧽 Notification tracking cleared');
  }

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
    clearNotificationTracking();
  }

  void addListener(NotificationCallback cb) => _callbacks.add(cb);
  void removeListener(NotificationCallback cb) => _callbacks.remove(cb);
  void addTaskListener(TaskNotificationCallback cb) => _taskCallbacks.add(cb);
  void removeTaskListener(TaskNotificationCallback cb) => _taskCallbacks.remove(cb);
  void addActivityListener(ActivityNotificationCallback cb) => _activityCallbacks.add(cb);
  void removeActivityListener(ActivityNotificationCallback cb) => _activityCallbacks.remove(cb);

  // Legacy compat
  String? get pendingLeadId {
    if (_pendingPayload?.startsWith('lead:') == true) return _pendingPayload!.substring(5);
    return null;
  }
  void clearPendingLeadId() => _pendingPayload = null;

  Future<void> cancelNotification(String leadId) async {
    await _plugin.cancel(leadId.hashCode);
    _notifiedLeads.remove(leadId);
  }

  Future<void> cancelTaskNotification(String taskId) async {
    await _plugin.cancel(taskId.hashCode + 10000);
    _notifiedTasks.remove(taskId);
  }

  Future<void> cancelActivityNotification(String activityId) async {
    await _plugin.cancel(activityId.hashCode + 20000);
    _notifiedActivities.remove(activityId);
  }

  void dispose() {
    _timer?.cancel();
    _callbacks.clear();
    _taskCallbacks.clear();
    _activityCallbacks.clear();
  }
}
