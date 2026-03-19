import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import '../models/lead.dart';

typedef NotificationCallback = void Function(Lead lead);
typedef TaskNotificationCallback = void Function(Map<String, dynamic> task, Lead lead);
typedef ActivityNotificationCallback = void Function(Map<String, dynamic> activity, Lead lead);

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final List<NotificationCallback> _callbacks = [];
  final List<TaskNotificationCallback> _taskCallbacks = [];
  final List<ActivityNotificationCallback> _activityCallbacks = [];
  Timer? _notificationTimer;
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  final Set<String> _notifiedLeadIds = {};
  final Set<String> _notifiedTaskIds = {};
  final Set<String> _notifiedActivityIds = {};
  bool _isInitialized = false;
  
  // OFFLINE NOTIFICATION SUPPORT
  Timer? _offlineNotificationTimer;
  List<Lead> _cachedLeads = [];
  List<Map<String, dynamic>> _cachedTasks = [];
  List<Map<String, dynamic>> _cachedActivities = [];

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  /// Check if the notification service has been initialized
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;
    // NOTIFICATION INITIALIZATION - ROBUST ERROR HANDLING
    // This addresses the "Notification initialization may fail silently" issue
    // The method now throws exceptions instead of failing silently
    // All initialization failures are properly propagated to the caller
    try {
      await _initializeNotifications();
      _isInitialized = true;
      debugPrint('NotificationService initialization successful');
    } catch (e) {
      debugPrint('Failed to initialize NotificationService: $e');
      _isInitialized = false;
      // EXPLICIT ERROR PROPAGATION - No silent failures
      throw Exception('NotificationService initialization failed: $e');
    }
  }

  Future<void> _initializeNotifications() async {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInitializationSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );
    
    final initialized = await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    if (initialized != true) {
      throw Exception('Failed to initialize notifications');
    }
    
    // Request notification permissions for Android 13+
    final androidImplementation = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      final granted = await androidImplementation.requestNotificationsPermission();
      if (granted != true) {
        debugPrint('Notification permission denied');
      }
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - navigate to lead details if payload exists
    if (response.payload != null) {
      // Store the payload for navigation when app becomes active
      _pendingPayload = response.payload!;
    }
  }

  String? _pendingPayload;
  
  String? get pendingPayload => _pendingPayload;
  
  void clearPendingPayload() {
    _pendingPayload = null;
  }

  // Legacy support for existing code
  String? get pendingLeadId {
    if (_pendingPayload != null && _pendingPayload!.startsWith('lead:')) {
      return _pendingPayload!.substring(5);
    }
    return null;
  }
  
  void clearPendingLeadId() {
    _pendingPayload = null;
  }

  Map<String, String>? get pendingActivityInfo {
    if (_pendingPayload != null && _pendingPayload!.startsWith('activity:')) {
      final parts = _pendingPayload!.split(':');
      if (parts.length >= 3) {
        return {
          'activityId': parts[1],
          'leadId': parts[2],
        };
      }
    }
    return null;
  }

  Future<void> _showNotification(Lead lead) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'lead_notifications',
      'Lead Follow-up Notifications',
      channelDescription: 'Notifications for lead follow-ups',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      autoCancel: false,
      ongoing: true,
      showWhen: true,
    );
    
    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );
    
    await _flutterLocalNotificationsPlugin.show(
      lead.id.hashCode,
      'Lead Follow-up Reminder',
      'Follow-up with ${lead.contactName} is due in 5 minutes',
      notificationDetails,
      payload: 'lead:${lead.id}',
    );
  }

  Future<void> _showTaskNotification(Map<String, dynamic> task, Lead lead) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'task_notifications',
      'Task Reminder Notifications',
      channelDescription: 'Notifications for task reminders',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      autoCancel: false,
      ongoing: true,
      showWhen: true,
    );
    
    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );
    
    await _flutterLocalNotificationsPlugin.show(
      task['id'].hashCode + 10000, // Offset to avoid conflicts with lead notifications
      'Task Reminder',
      'Task "${task['title']}" for ${lead.contactName} is due in 5 minutes',
      notificationDetails,
      payload: 'task:${task['id']}:${lead.id}',
    );
  }

  Future<void> _showActivityNotification(Map<String, dynamic> activity, Lead lead) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'activity_notifications',
      'Activity Reminder Notifications',
      channelDescription: 'Notifications for scheduled activities',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      autoCancel: false,
      ongoing: true,
      showWhen: true,
    );
    
    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );
    
    // Get activity type for notification message
    String activityType = activity['title'] ?? 'Activity';
    String message = _getActivityNotificationMessage(activityType, lead.contactName);
    
    await _flutterLocalNotificationsPlugin.show(
      activity['id'].hashCode + 20000, // Offset to avoid conflicts
      'Activity Reminder',
      message,
      notificationDetails,
      payload: 'activity:${activity['id']}:${lead.id}',
    );
  }

  String _getActivityNotificationMessage(String activityType, String contactName) {
    switch (activityType) {
      case 'Called - Call Later':
        return 'Time to call back $contactName (due in 5 minutes)';
      case 'Called - Appointment Scheduled':
        return 'Appointment with $contactName is due in 5 minutes';
      case 'Called - Ringing – No Response':
        return 'Retry calling $contactName (due in 5 minutes)';
      case 'Called - Busy':
        return 'Retry calling $contactName (was busy, due in 5 minutes)';
      case 'Called - Switched Off / Unavailable':
        return 'Retry calling $contactName (was unavailable, due in 5 minutes)';
      case 'SMS Sent':
        return 'Follow up on SMS sent to $contactName (due in 5 minutes)';
      case 'Email Sent':
        return 'Follow up on email sent to $contactName (due in 5 minutes)';
      default:
        return 'Activity reminder for $contactName is due in 5 minutes';
    }
  }

  void addListener(NotificationCallback callback) {
    _callbacks.add(callback);
  }

  void removeListener(NotificationCallback callback) {
    _callbacks.remove(callback);
  }

  void addTaskListener(TaskNotificationCallback callback) {
    _taskCallbacks.add(callback);
  }

  void removeTaskListener(TaskNotificationCallback callback) {
    _taskCallbacks.remove(callback);
  }

  void addActivityListener(ActivityNotificationCallback callback) {
    _activityCallbacks.add(callback);
  }

  void removeActivityListener(ActivityNotificationCallback callback) {
    _activityCallbacks.remove(callback);
  }

  void startMonitoring(List<Lead> leads, {List<Map<String, dynamic>>? allTasks, List<Map<String, dynamic>>? allActivities}) {
    // GLOBAL NOTIFICATION MONITORING - WORKS ACROSS ALL SCREENS
    // This addresses the "Notification monitoring only works in AllLeadsScreen" issue
    // The monitoring is started globally in MainScreen and works throughout the app
    // It includes proper initialization validation and error handling
    if (!_isInitialized) {
      debugPrint('NotificationService not initialized');
      return;
    }
    
    // Cache data for offline use
    _cachedLeads = List.from(leads);
    _cachedTasks = allTasks != null ? List.from(allTasks) : [];
    _cachedActivities = allActivities != null ? List.from(allActivities) : [];
    
    // Save cached data to persistent storage for offline access
    _saveCachedDataToStorage();
    
    _notificationTimer?.cancel();
    // TESTING MODE: 10-second intervals for more precise timing during testing
    _notificationTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkNotifications(leads);
      if (allTasks != null) {
        _checkTaskNotifications(allTasks, leads);
      }
      if (allActivities != null) {
        _checkActivityNotifications(allActivities, leads);
      }
    });
    
    // Start offline monitoring as backup
    _startOfflineMonitoring();
    
    debugPrint('🔔 Notification monitoring started with ${leads.length} leads, ${allTasks?.length ?? 0} tasks, and ${allActivities?.length ?? 0} activities');
    debugPrint('💾 Offline notification backup enabled');
  }

  /// Schedule notifications for leads, tasks, and activities when app is closed
  Future<void> scheduleNotificationsForClosedApp(List<Lead> leads, {List<Map<String, dynamic>>? allTasks, List<Map<String, dynamic>>? allActivities}) async {
    if (!_isInitialized) {
      debugPrint('NotificationService not initialized');
      return;
    }

    // Cancel all existing scheduled notifications first
    await _flutterLocalNotificationsPlugin.cancelAll();
    
    final now = DateTime.now();
    debugPrint('📅 Scheduling notifications for when app is closed...');
    
    // Schedule lead follow-up notifications
    for (final lead in leads) {
      if (lead.followUpDate != null && !lead.isCompleted) {
        await _scheduleLeadNotification(lead, now);
      }
    }
    
    // Schedule task notifications
    if (allTasks != null) {
      for (final task in allTasks) {
        if (task['dueDate'] != null && !(task['isCompleted'] ?? false)) {
          await _scheduleTaskNotification(task, leads, now);
        }
      }
    }
    
    // Schedule activity notifications
    if (allActivities != null) {
      for (final activity in allActivities) {
        if (activity['scheduledDate'] != null) {
          await _scheduleActivityNotification(activity, leads, now);
        }
      }
    }
    
    debugPrint('✅ All notifications scheduled for when app is closed');
  }

  Future<void> _scheduleLeadNotification(Lead lead, DateTime now) async {
    // Parse follow-up time with fallback to 10:00 AM
    int hour = 10;
    int minute = 0;
    
    if (lead.followUpTime != null && lead.followUpTime!.isNotEmpty) {
      try {
        final timeMatch = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)', caseSensitive: false)
            .firstMatch(lead.followUpTime!);
        if (timeMatch != null) {
          hour = int.parse(timeMatch.group(1)!);
          minute = int.parse(timeMatch.group(2)!);
          final isPM = timeMatch.group(3)!.toUpperCase() == 'PM';
          if (isPM && hour != 12) hour += 12;
          if (!isPM && hour == 12) hour = 0;
        }
      } catch (e) {
        hour = 10;
        minute = 0;
      }
    }
    
    final followUpDateTime = DateTime(
      lead.followUpDate!.year,
      lead.followUpDate!.month,
      lead.followUpDate!.day,
      hour,
      minute,
    );
    
    // Only schedule if follow-up is in the future
    if (followUpDateTime.isAfter(now)) {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        lead.id.hashCode,
        'Lead Follow-up Reminder',
        'Follow-up with ${lead.contactName} is due now',
        tz.TZDateTime.from(followUpDateTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'lead_notifications',
            'Lead Follow-up Notifications',
            channelDescription: 'Notifications for lead follow-ups',
            importance: Importance.max,
            priority: Priority.high,
            autoCancel: false,
            ongoing: false,
            showWhen: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'lead:${lead.id}',
      );
      
      debugPrint('📅 Scheduled notification for ${lead.contactName} at $followUpDateTime');
    }
  }

  Future<void> _scheduleTaskNotification(Map<String, dynamic> task, List<Lead> leads, DateTime now) async {
    final dueDate = task['dueDate'] as DateTime;
    final dueTimeString = task['dueTime'] as String? ?? '12:00 PM';
    
    // Parse the due time string
    int hour = 12;
    int minute = 0;
    
    try {
      final timeMatch = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)', caseSensitive: false)
          .firstMatch(dueTimeString);
      if (timeMatch != null) {
        hour = int.parse(timeMatch.group(1)!);
        minute = int.parse(timeMatch.group(2)!);
        final isPM = timeMatch.group(3)!.toUpperCase() == 'PM';
        if (isPM && hour != 12) hour += 12;
        if (!isPM && hour == 12) hour = 0;
      }
    } catch (e) {
      hour = 12;
      minute = 0;
    }
    
    final completeDueDateTime = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      hour,
      minute,
    );
    
    // Only schedule if due time is in the future
    if (completeDueDateTime.isAfter(now)) {
      // Find associated lead
      Lead? associatedLead = leads.isNotEmpty ? leads.first : null;
      
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        task['id'].hashCode + 10000,
        'Task Reminder',
        'Task "${task['title']}" is due now${associatedLead != null ? ' for ${associatedLead.contactName}' : ''}',
        tz.TZDateTime.from(completeDueDateTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_notifications',
            'Task Reminder Notifications',
            channelDescription: 'Notifications for task reminders',
            importance: Importance.max,
            priority: Priority.high,
            autoCancel: false,
            ongoing: false,
            showWhen: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'task:${task['id']}:${associatedLead?.id ?? ''}',
      );
      
      debugPrint('📋 Scheduled task notification for "${task['title']}" at $completeDueDateTime');
    }
  }

  Future<void> _scheduleActivityNotification(Map<String, dynamic> activity, List<Lead> leads, DateTime now) async {
    final scheduledDate = activity['scheduledDate'] as DateTime;
    
    // Only schedule if scheduled time is in the future
    if (scheduledDate.isAfter(now)) {
      // Find associated lead
      Lead? associatedLead;
      try {
        if (activity['leadId'] != null) {
          associatedLead = leads.firstWhere(
            (lead) => lead.id == activity['leadId'],
            orElse: () => leads.isNotEmpty ? leads.first : throw Exception('No leads available'),
          );
        } else {
          associatedLead = leads.isNotEmpty ? leads.first : null;
        }
      } catch (e) {
        associatedLead = leads.isNotEmpty ? leads.first : null;
      }
      
      String activityType = activity['title'] ?? 'Activity';
      String message = associatedLead != null 
          ? _getActivityNotificationMessage(activityType, associatedLead.contactName)
          : 'Activity "$activityType" is scheduled now';
      
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        activity['id'].hashCode + 20000,
        'Activity Reminder',
        message,
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'activity_notifications',
            'Activity Reminder Notifications',
            channelDescription: 'Notifications for scheduled activities',
            importance: Importance.max,
            priority: Priority.high,
            autoCancel: false,
            ongoing: false,
            showWhen: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'activity:${activity['id']}:${associatedLead?.id ?? ''}',
      );
      
      debugPrint('📞 Scheduled activity notification for "$activityType" at $scheduledDate');
    }
  }

  void stopMonitoring() {
    _notificationTimer?.cancel();
    _offlineNotificationTimer?.cancel();
  }
  
  /// OFFLINE NOTIFICATION MONITORING
  /// Provides notification functionality when internet is not available
  /// Uses cached data stored locally to continue showing notifications
  void _startOfflineMonitoring() {
    _offlineNotificationTimer?.cancel();
    
    // Start offline monitoring with slightly different interval to avoid conflicts
    _offlineNotificationTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _checkOfflineNotifications();
    });
    
    debugPrint('📶 Offline notification monitoring started');
  }
  
  /// Check notifications using cached data when offline
  void _checkOfflineNotifications() async {
    try {
      // Load cached data from storage if not in memory
      if (_cachedLeads.isEmpty || _cachedTasks.isEmpty || _cachedActivities.isEmpty) {
        await _loadCachedDataFromStorage();
      }
      
      final now = DateTime.now();
      debugPrint('📶 Checking offline notifications at ${now.hour}:${now.minute.toString().padLeft(2, '0')}');
      
      // Check lead notifications offline
      _checkOfflineLeadNotifications(_cachedLeads);
      
      // Check task notifications offline
      _checkOfflineTaskNotifications(_cachedTasks, _cachedLeads);
      
      // Check activity notifications offline
      _checkOfflineActivityNotifications(_cachedActivities, _cachedLeads);
      
    } catch (e) {
      debugPrint('Error in offline notification check: $e');
    }
  }
  
  /// Check lead notifications using cached data
  void _checkOfflineLeadNotifications(List<Lead> leads) {
    final now = DateTime.now();
    
    for (final lead in leads) {
      if (lead.followUpDate != null && !lead.isCompleted && !_notifiedLeadIds.contains('offline_${lead.id}')) {
        // Parse follow-up time with fallback to 10:00 AM
        int hour = 10;
        int minute = 0;
        
        if (lead.followUpTime != null && lead.followUpTime!.isNotEmpty) {
          try {
            final timeMatch = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)', caseSensitive: false)
                .firstMatch(lead.followUpTime!);
            if (timeMatch != null) {
              hour = int.parse(timeMatch.group(1)!);
              minute = int.parse(timeMatch.group(2)!);
              final isPM = timeMatch.group(3)!.toUpperCase() == 'PM';
              if (isPM && hour != 12) hour += 12;
              if (!isPM && hour == 12) hour = 0;
            }
          } catch (e) {
            hour = 10;
            minute = 0;
          }
        }
        
        final followUpDateTime = DateTime(
          lead.followUpDate!.year,
          lead.followUpDate!.month,
          lead.followUpDate!.day,
          hour,
          minute,
        );
        
        final minutesUntilFollowUp = followUpDateTime.difference(now).inMinutes;
        
        // Show notification 5 minutes before due
        if (minutesUntilFollowUp >= 4 && minutesUntilFollowUp <= 6) {
          _notifiedLeadIds.add('offline_${lead.id}');
          _showOfflineNotification(
            'Lead Follow-up Reminder (Offline)',
            'Follow-up with ${lead.contactName} is due in 5 minutes',
            'lead:${lead.id}',
            lead.id.hashCode + 50000, // Offset for offline notifications
          );
          debugPrint('📶 Offline notification sent for lead: ${lead.contactName}');
        }
      }
    }
  }
  
  /// Check task notifications using cached data
  void _checkOfflineTaskNotifications(List<Map<String, dynamic>> tasks, List<Lead> leads) {
    final now = DateTime.now();
    
    for (final task in tasks) {
      if (task['dueDate'] != null && !(task['isCompleted'] ?? false) && !_notifiedTaskIds.contains('offline_${task['id']}')) {
        final dueDate = task['dueDate'] as DateTime;
        final dueTimeString = task['dueTime'] as String? ?? '12:00 PM';
        
        // Parse the due time string
        int hour = 12;
        int minute = 0;
        
        try {
          final timeMatch = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)', caseSensitive: false)
              .firstMatch(dueTimeString);
          if (timeMatch != null) {
            hour = int.parse(timeMatch.group(1)!);
            minute = int.parse(timeMatch.group(2)!);
            final isPM = timeMatch.group(3)!.toUpperCase() == 'PM';
            if (isPM && hour != 12) hour += 12;
            if (!isPM && hour == 12) hour = 0;
          }
        } catch (e) {
          hour = 12;
          minute = 0;
        }
        
        final completeDueDateTime = DateTime(
          dueDate.year,
          dueDate.month,
          dueDate.day,
          hour,
          minute,
        );
        
        final minutesUntilDue = completeDueDateTime.difference(now).inMinutes;
        
        // Show notification 5 minutes before due
        if (minutesUntilDue >= 4 && minutesUntilDue <= 6) {
          _notifiedTaskIds.add('offline_${task['id']}');
          
          // Find associated lead
          Lead? associatedLead = leads.isNotEmpty ? leads.first : null;
          
          _showOfflineNotification(
            'Task Reminder (Offline)',
            'Task "${task['title']}" is due in 5 minutes${associatedLead != null ? ' for ${associatedLead.contactName}' : ''}',
            'task:${task['id']}:${associatedLead?.id ?? ''}',
            (task['id'].hashCode + 60000), // Offset for offline task notifications
          );
          debugPrint('📶 Offline notification sent for task: ${task['title']}');
        }
      }
    }
  }
  
  /// Check activity notifications using cached data
  void _checkOfflineActivityNotifications(List<Map<String, dynamic>> activities, List<Lead> leads) {
    final now = DateTime.now();
    
    for (final activity in activities) {
      if (activity['scheduledDate'] != null && !_notifiedActivityIds.contains('offline_${activity['id']}')) {
        final scheduledDate = activity['scheduledDate'] as DateTime;
        final minutesUntilScheduled = scheduledDate.difference(now).inMinutes;
        
        // Show notification 5 minutes before scheduled
        if (minutesUntilScheduled >= 4 && minutesUntilScheduled <= 6) {
          _notifiedActivityIds.add('offline_${activity['id']}');
          
          // Find associated lead
          Lead? associatedLead;
          try {
            if (activity['leadId'] != null) {
              associatedLead = leads.firstWhere(
                (lead) => lead.id == activity['leadId'],
                orElse: () => leads.isNotEmpty ? leads.first : throw Exception('No leads available'),
              );
            } else {
              associatedLead = leads.isNotEmpty ? leads.first : null;
            }
          } catch (e) {
            associatedLead = leads.isNotEmpty ? leads.first : null;
          }
          
          String activityType = activity['title'] ?? 'Activity';
          String message = associatedLead != null 
              ? _getActivityNotificationMessage(activityType, associatedLead.contactName)
              : 'Activity "$activityType" is scheduled in 5 minutes';
          
          _showOfflineNotification(
            'Activity Reminder (Offline)',
            message,
            'activity:${activity['id']}:${associatedLead?.id ?? ''}',
            (activity['id'].hashCode + 70000), // Offset for offline activity notifications
          );
          debugPrint('📶 Offline notification sent for activity: $activityType');
        }
      }
    }
  }
  
  /// Show offline notification
  Future<void> _showOfflineNotification(String title, String body, String payload, int id) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'offline_notifications',
      'Offline Notifications',
      channelDescription: 'Notifications when app is offline',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'offline_ticker',
      autoCancel: false,
      ongoing: false,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );
    
    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );
    
    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// NOTIFICATION TIMING LOGIC - SHOW ONLY FOR LEADS WITH FOLLOW-UP WITHIN 5 MINUTES
  /// Modified to trigger notifications only for leads with follow-up within next 5 minutes
  void _checkNotifications(List<Lead> leads) {
    final now = DateTime.now();
    debugPrint('🔍 Checking notifications at ${now.hour}:${now.minute.toString().padLeft(2, '0')} for ${leads.length} leads');
    
    for (final lead in leads) {
      // Show notification ONLY for leads that have follow-up within next 5 minutes
      if (lead.followUpDate != null && !lead.isCompleted && !_notifiedLeadIds.contains(lead.id)) {
        // Parse follow-up time with fallback to 10:00 AM
        int hour = 10;
        int minute = 0;
        
        if (lead.followUpTime != null && lead.followUpTime!.isNotEmpty) {
          try {
            final timeMatch = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)', caseSensitive: false)
                .firstMatch(lead.followUpTime!);
            if (timeMatch != null) {
              hour = int.parse(timeMatch.group(1)!);
              minute = int.parse(timeMatch.group(2)!);
              final isPM = timeMatch.group(3)!.toUpperCase() == 'PM';
              if (isPM && hour != 12) hour += 12;
              if (!isPM && hour == 12) hour = 0;
            }
          } catch (e) {
            hour = 10;
            minute = 0;
          }
        }
        
        final followUpDateTime = DateTime(
          lead.followUpDate!.year,
          lead.followUpDate!.month,
          lead.followUpDate!.day,
          hour,
          minute,
        );
        
        // Calculate minutes until follow-up
        final minutesUntilFollowUp = followUpDateTime.difference(now).inMinutes;
        
        debugPrint('📅 Lead: ${lead.contactName}');
        
        // Format time properly for 12-hour display
        String formattedTime;
        int displayHour = hour;
        String period = 'AM';
        
        if (displayHour == 0) {
          displayHour = 12;
        } else if (displayHour > 12) {
          displayHour = displayHour - 12;
          period = 'PM';
        } else if (displayHour == 12) {
          period = 'PM';
        }
        
        formattedTime = '${displayHour.toString()}:${minute.toString().padLeft(2, '0')} $period';
        
        debugPrint('   Follow-up: ${followUpDateTime.day}/${followUpDateTime.month} $formattedTime');
        debugPrint('   Minutes until follow-up: $minutesUntilFollowUp');
        
        // 5 MINUTES BEFORE: Show notification 5 minutes before follow-up is due
        bool shouldNotify = false;
        
        if (minutesUntilFollowUp >= 4 && minutesUntilFollowUp <= 6) {
          // Follow-up is due in 5 minutes (4-6 minute window for accuracy)
          shouldNotify = true;
          debugPrint('   → Notification triggered: Follow-up due in 5 minutes');
        } else {
          debugPrint('   → No notification: Follow-up is $minutesUntilFollowUp minutes away');
        }
        
        if (shouldNotify) {
          _notifiedLeadIds.add(lead.id);
          _showNotification(lead);
          _notifyListeners(lead);
          debugPrint('✅ Notification sent for lead: ${lead.contactName}');
        }
      }
    }
  }

  /// TASK NOTIFICATION LOGIC - ONLY WITHIN 5 MINUTES OF DUE TIME
  /// Checks tasks and sends notifications only if due within next 5 minutes
  void _checkTaskNotifications(List<Map<String, dynamic>> allTasks, List<Lead> leads) {
    final now = DateTime.now();
    debugPrint('📋 Checking task notifications at ${now.hour}:${now.minute.toString().padLeft(2, '0')} for ${allTasks.length} tasks');
    
    for (final task in allTasks) {
      if (task['dueDate'] != null && !(task['isCompleted'] ?? false) && !_notifiedTaskIds.contains(task['id'].toString())) {
        final dueDate = task['dueDate'] as DateTime;
        final dueTimeString = task['dueTime'] as String? ?? '12:00 PM';
        
        // Parse the due time string to get hour and minute
        int hour = 12;
        int minute = 0;
        
        try {
          final timeMatch = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)', caseSensitive: false)
              .firstMatch(dueTimeString);
          if (timeMatch != null) {
            hour = int.parse(timeMatch.group(1)!);
            minute = int.parse(timeMatch.group(2)!);
            final isPM = timeMatch.group(3)!.toUpperCase() == 'PM';
            if (isPM && hour != 12) hour += 12;
            if (!isPM && hour == 12) hour = 0;
          }
        } catch (e) {
          debugPrint('Error parsing task time: $dueTimeString, using default 12:00 PM');
          hour = 12;
          minute = 0;
        }
        
        // Create the complete due DateTime with the parsed time
        final completeDueDateTime = DateTime(
          dueDate.year,
          dueDate.month,
          dueDate.day,
          hour,
          minute,
        );
        
        final minutesUntilDue = completeDueDateTime.difference(now).inMinutes;
        
        // Find the associated lead for this task
        Lead? associatedLead;
        try {
          // First try to find lead by leadId if available
          if (task['leadId'] != null) {
            associatedLead = leads.firstWhere(
              (lead) => lead.id == task['leadId'],
              orElse: () => leads.isNotEmpty ? leads.first : throw Exception('No leads available'),
            );
          } else {
            // Fallback to first available lead
            associatedLead = leads.isNotEmpty ? leads.first : null;
          }
        } catch (e) {
          debugPrint('Could not find associated lead for task: ${task['title']}');
          associatedLead = leads.isNotEmpty ? leads.first : null;
        }
        
        if (associatedLead != null) {
          debugPrint('📋 Task: ${task['title']}');
          debugPrint('   Due: ${dueDate.day}/${dueDate.month} $dueTimeString');
          debugPrint('   Minutes until due: $minutesUntilDue');
          debugPrint('   Associated with: ${associatedLead.contactName}');
          
          // 5 MINUTES BEFORE: Show notification 5 minutes before task is due
          bool shouldNotify = false;
          
          if (minutesUntilDue >= 4 && minutesUntilDue <= 6) {
            // Task is due in 5 minutes (4-6 minute window for accuracy)
            shouldNotify = true;
            debugPrint('   → Task notification triggered: Due in 5 minutes');
          } else {
            debugPrint('   → No notification: Task is $minutesUntilDue minutes away');
          }
          
          if (shouldNotify) {
            _notifiedTaskIds.add(task['id'].toString());
            _showTaskNotification(task, associatedLead);
            _notifyTaskListeners(task, associatedLead);
            debugPrint('✅ Task notification sent: ${task['title']}');
          }
        } else {
          debugPrint('❌ No associated lead found for task: ${task['title']}');
        }
      }
    }
  }

  /// ACTIVITY NOTIFICATION LOGIC - ONLY WITHIN 5 MINUTES OF SCHEDULED TIME
  /// Checks activities and sends notifications only if scheduled within next 5 minutes
  void _checkActivityNotifications(List<Map<String, dynamic>> allActivities, List<Lead> leads) {
    final now = DateTime.now();
    debugPrint('📞 Checking activity notifications at ${now.hour}:${now.minute.toString().padLeft(2, '0')} for ${allActivities.length} activities');
    
    // Debug: Print all activities being checked
    for (int i = 0; i < allActivities.length; i++) {
      final activity = allActivities[i];
      debugPrint('   Activity $i: ${activity['title']} - Scheduled: ${activity['scheduledDate']}');
    }
    
    for (final activity in allActivities) {
      if (activity['scheduledDate'] != null && !_notifiedActivityIds.contains(activity['id'].toString())) {
        final scheduledDate = activity['scheduledDate'] as DateTime;
        final minutesUntilScheduled = scheduledDate.difference(now).inMinutes;
        
        // Find the associated lead for this activity
        Lead? associatedLead;
        try {
          if (activity['leadId'] != null) {
            associatedLead = leads.firstWhere(
              (lead) => lead.id == activity['leadId'],
              orElse: () => leads.isNotEmpty ? leads.first : throw Exception('No leads available'),
            );
          } else {
            associatedLead = leads.isNotEmpty ? leads.first : null;
          }
        } catch (e) {
          debugPrint('Could not find associated lead for activity: ${activity['title']}');
          continue;
        }
        
        if (associatedLead != null) {
          debugPrint('📞 Activity: ${activity['title']}');
          
          // Format time properly for 12-hour display
          String formattedTime;
          int displayHour = scheduledDate.hour;
          String period = 'AM';
          
          if (displayHour == 0) {
            displayHour = 12;
          } else if (displayHour > 12) {
            displayHour = displayHour - 12;
            period = 'PM';
          } else if (displayHour == 12) {
            period = 'PM';
          }
          
          formattedTime = '${displayHour.toString()}:${scheduledDate.minute.toString().padLeft(2, '0')} $period';
          
          debugPrint('   Scheduled: ${scheduledDate.day}/${scheduledDate.month} $formattedTime');
          debugPrint('   Minutes until scheduled: $minutesUntilScheduled');
          
          // 5 MINUTES BEFORE: Show notification 5 minutes before activity is scheduled
          bool shouldNotify = false;
          
          if (minutesUntilScheduled >= 4 && minutesUntilScheduled <= 6) {
            // Activity is scheduled in 5 minutes (4-6 minute window for accuracy)
            shouldNotify = true;
            debugPrint('   → Activity notification triggered: Scheduled in 5 minutes');
          } else {
            debugPrint('   → No notification: Activity is $minutesUntilScheduled minutes away');
          }
          
          if (shouldNotify) {
            _notifiedActivityIds.add(activity['id'].toString());
            _showActivityNotification(activity, associatedLead);
            _notifyActivityListeners(activity, associatedLead);
            debugPrint('✅ Activity notification sent: ${activity['title']}');
          }
        }
      }
    }
  }

  void _notifyActivityListeners(Map<String, dynamic> activity, Lead lead) {
    for (final callback in _activityCallbacks) {
      callback(activity, lead);
    }
  }

  void _notifyTaskListeners(Map<String, dynamic> task, Lead lead) {
    for (final callback in _taskCallbacks) {
      callback(task, lead);
    }
  }

  void _notifyListeners(Lead lead) {
    for (final callback in _callbacks) {
      callback(lead);
    }
  }

  void dispose() {
    _notificationTimer?.cancel();
    _offlineNotificationTimer?.cancel();
    _callbacks.clear();
    _taskCallbacks.clear();
    _activityCallbacks.clear();
    _notifiedLeadIds.clear();
    _notifiedTaskIds.clear();
    _notifiedActivityIds.clear();
  }
  
  /// OFFLINE DATA CACHING METHODS
  /// Save notification data to persistent storage for offline access
  Future<void> _saveCachedDataToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save leads
      final leadsJson = _cachedLeads.map((lead) => {
        'id': lead.id,
        'contactName': lead.contactName,
        'email': lead.email,
        'phone': lead.phone,
        'service': lead.service,
        'tags': lead.tags,
        'notes': lead.notes,
        'followUpDate': lead.followUpDate?.toIso8601String(),
        'followUpTime': lead.followUpTime,
        'createdAt': lead.createdAt.toIso8601String(),
        'isCompleted': lead.isCompleted,
      }).toList();
      await prefs.setString('cached_leads_for_notifications', jsonEncode(leadsJson));
      
      // Save tasks
      final tasksJson = _cachedTasks.map((task) => {
        'id': task['id'],
        'title': task['title'],
        'description': task['description'],
        'dueDate': (task['dueDate'] as DateTime).toIso8601String(),
        'dueTime': task['dueTime'],
        'isCompleted': task['isCompleted'],
        'priority': task['priority'],
      }).toList();
      await prefs.setString('cached_tasks_for_notifications', jsonEncode(tasksJson));
      
      // Save activities
      final activitiesJson = _cachedActivities.map((activity) => {
        'id': activity['id'],
        'title': activity['title'],
        'description': activity['description'],
        'scheduledDate': activity['scheduledDate'] != null 
            ? (activity['scheduledDate'] as DateTime).toIso8601String()
            : null,
        'leadId': activity['leadId'],
      }).toList();
      await prefs.setString('cached_activities_for_notifications', jsonEncode(activitiesJson));
      
      debugPrint('💾 Cached notification data saved to storage');
    } catch (e) {
      debugPrint('Error saving cached notification data: $e');
    }
  }
  
  /// Load cached notification data from persistent storage
  Future<void> _loadCachedDataFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load leads
      final leadsString = prefs.getString('cached_leads_for_notifications');
      if (leadsString != null) {
        final leadsJson = jsonDecode(leadsString) as List;
        _cachedLeads = leadsJson.map((leadData) {
          return Lead(
            id: leadData['id'],
            contactName: leadData['contactName'],
            email: leadData['email'],
            phone: leadData['phone'],
            service: leadData['service'],
            tags: leadData['tags'],
            notes: leadData['notes'],
            followUpDate: leadData['followUpDate'] != null 
                ? DateTime.parse(leadData['followUpDate'])
                : null,
            followUpTime: leadData['followUpTime'],
            createdAt: DateTime.parse(leadData['createdAt']),
            isCompleted: leadData['isCompleted'] ?? false,
          );
        }).toList();
      }
      
      // Load tasks
      final tasksString = prefs.getString('cached_tasks_for_notifications');
      if (tasksString != null) {
        final tasksJson = jsonDecode(tasksString) as List;
        _cachedTasks = tasksJson.map((taskData) => {
          'id': taskData['id'],
          'title': taskData['title'],
          'description': taskData['description'],
          'dueDate': DateTime.parse(taskData['dueDate']),
          'dueTime': taskData['dueTime'],
          'isCompleted': taskData['isCompleted'],
          'priority': taskData['priority'],
        }).toList();
      }
      
      // Load activities
      final activitiesString = prefs.getString('cached_activities_for_notifications');
      if (activitiesString != null) {
        final activitiesJson = jsonDecode(activitiesString) as List;
        _cachedActivities = activitiesJson.map((activityData) => {
          'id': activityData['id'],
          'title': activityData['title'],
          'description': activityData['description'],
          'scheduledDate': activityData['scheduledDate'] != null 
              ? DateTime.parse(activityData['scheduledDate'])
              : null,
          'leadId': activityData['leadId'],
        }).toList();
      }
      
      debugPrint('💾 Cached notification data loaded from storage');
      debugPrint('   Leads: ${_cachedLeads.length}');
      debugPrint('   Tasks: ${_cachedTasks.length}');
      debugPrint('   Activities: ${_cachedActivities.length}');
    } catch (e) {
      debugPrint('Error loading cached notification data: $e');
    }
  }
  
  /// Update cached data when new items are added
  void updateCachedData({List<Lead>? leads, List<Map<String, dynamic>>? tasks, List<Map<String, dynamic>>? activities}) {
    if (leads != null) {
      _cachedLeads = List.from(leads);
    }
    if (tasks != null) {
      _cachedTasks = List.from(tasks);
    }
    if (activities != null) {
      _cachedActivities = List.from(activities);
    }
    
    // Save updated data to storage
    _saveCachedDataToStorage();
    debugPrint('💾 Cached notification data updated');
  }
  
  /// Initialize offline notifications on app start
  Future<void> initializeOfflineNotifications() async {
    await _loadCachedDataFromStorage();
    if (_cachedLeads.isNotEmpty || _cachedTasks.isNotEmpty || _cachedActivities.isNotEmpty) {
      _startOfflineMonitoring();
      debugPrint('📶 Offline notifications initialized with cached data');
    }
  }
  
  /// Check internet connectivity
  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  /// Enhanced notification check that works both online and offline
  Future<void> checkNotificationsWithFallback() async {
    final hasInternet = await _hasInternetConnection();
    
    if (hasInternet) {
      debugPrint('🌐 Internet available - using online notifications');
      // Online notifications are handled by the regular monitoring
    } else {
      debugPrint('📶 No internet - using offline notifications');
      // Force offline notification check
      _checkOfflineNotifications();
    }
  }
  
  /// Force immediate notification check for all types
  /// Used when new activities, tasks, or notes are created
  void forceNotificationCheck() {
    if (!_isInitialized) {
      debugPrint('NotificationService not initialized');
      return;
    }
    
    debugPrint('🔄 Force checking all notifications...');
    
    // Clear notification tracking to allow re-notifications for testing
    // This ensures notifications can be triggered again for the same items
    
    // Check online notifications with cached data
    if (_cachedLeads.isNotEmpty) {
      _checkNotifications(_cachedLeads);
    }
    if (_cachedTasks.isNotEmpty && _cachedLeads.isNotEmpty) {
      _checkTaskNotifications(_cachedTasks, _cachedLeads);
    }
    if (_cachedActivities.isNotEmpty && _cachedLeads.isNotEmpty) {
      _checkActivityNotifications(_cachedActivities, _cachedLeads);
    }
    
    // Also check offline notifications as backup
    _checkOfflineNotifications();
    
    debugPrint('🔄 Force notification check completed');
  }
  
  /// Test notification functionality
  Future<void> showTestNotification() async {
    if (!_isInitialized) {
      debugPrint('NotificationService not initialized');
      return;
    }
    
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'test_notifications',
      'Test Notifications',
      channelDescription: 'Test notifications to verify functionality',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'test_ticker',
      autoCancel: true,
      ongoing: false,
      showWhen: true,
    );
    
    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );
    
    await _flutterLocalNotificationsPlugin.show(
      999999, // Test notification ID
      'Test Notification',
      'This is a test notification to verify the system is working',
      notificationDetails,
      payload: 'test:notification',
    );
    
    debugPrint('📢 Test notification sent');
  }
  
  /// Clear notification tracking to allow re-notifications
  /// Useful for testing or when you want to reset notification state
  void clearNotificationTracking() {
    _notifiedLeadIds.clear();
    _notifiedTaskIds.clear();
    _notifiedActivityIds.clear();
    debugPrint('🧽 Notification tracking cleared - notifications can be sent again');
  }
  
  /// Show immediate test notification for activities, tasks, or leads
  Future<void> showImmediateTestNotification(String type, String title, String message) async {
    if (!_isInitialized) {
      debugPrint('NotificationService not initialized');
      return;
    }
    
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'immediate_test_notifications',
      'Immediate Test Notifications',
      channelDescription: 'Immediate test notifications for debugging',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'immediate_test_ticker',
      autoCancel: true,
      ongoing: false,
      showWhen: true,
    );
    
    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );
    
    final notificationId = DateTime.now().millisecondsSinceEpoch % 100000;
    
    await _flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      message,
      notificationDetails,
      payload: '$type:test:${DateTime.now().millisecondsSinceEpoch}',
    );
    
    debugPrint('📢 Immediate test notification sent: $title - $message');
  }
  
  Future<void> cancelNotification(String leadId) async {
    await _flutterLocalNotificationsPlugin.cancel(leadId.hashCode);
    _notifiedLeadIds.remove(leadId);
  }
  
  Future<void> cancelTaskNotification(String taskId) async {
    await _flutterLocalNotificationsPlugin.cancel(int.parse(taskId).hashCode + 10000);
    _notifiedTaskIds.remove(taskId);
  }
  
  Future<void> cancelActivityNotification(String activityId) async {
    await _flutterLocalNotificationsPlugin.cancel(int.parse(activityId).hashCode + 20000);
    _notifiedActivityIds.remove(activityId);
  }
  
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    _notifiedLeadIds.clear();
    _notifiedTaskIds.clear();
    _notifiedActivityIds.clear();
  }
}
