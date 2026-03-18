import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
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
      'Follow-up with ${lead.contactName} is due within 5 minutes',
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
      'Task "${task['title']}" for ${lead.contactName} is due within 5 minutes',
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
        return 'Time to call back $contactName (due within 5 minutes)';
      case 'Called - Appointment Scheduled':
        return 'Appointment with $contactName is due within 5 minutes';
      case 'Called - Ringing – No Response':
        return 'Retry calling $contactName (due within 5 minutes)';
      case 'Called - Busy':
        return 'Retry calling $contactName (was busy, due within 5 minutes)';
      case 'Called - Switched Off / Unavailable':
        return 'Retry calling $contactName (was unavailable, due within 5 minutes)';
      case 'SMS Sent':
        return 'Follow up on SMS sent to $contactName (due within 5 minutes)';
      case 'Email Sent':
        return 'Follow up on email sent to $contactName (due within 5 minutes)';
      default:
        return 'Activity reminder for $contactName is due within 5 minutes';
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
    debugPrint('🔔 Notification monitoring started with ${leads.length} leads, ${allTasks?.length ?? 0} tasks, and ${allActivities?.length ?? 0} activities');
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
        
        // STRICT 5-MINUTE RULE: Only show notification if follow-up is within next 5 minutes
        bool shouldNotify = false;
        
        if (minutesUntilFollowUp >= 0 && minutesUntilFollowUp <= 5) {
          // Follow-up is within the next 5 minutes
          shouldNotify = true;
          debugPrint('   → Notification triggered: Follow-up within 5 minutes');
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
          associatedLead = leads.isNotEmpty ? leads.first : null;
        } catch (e) {
          debugPrint('Could not find associated lead for task: ${task['title']}');
          continue;
        }
        
        if (associatedLead != null) {
          debugPrint('📋 Task: ${task['title']}');
          debugPrint('   Due: ${dueDate.day}/${dueDate.month} $dueTimeString');
          debugPrint('   Minutes until due: $minutesUntilDue');
          
          // STRICT 5-MINUTE RULE: Only show notification if task is due within next 5 minutes
          bool shouldNotify = false;
          
          if (minutesUntilDue >= 0 && minutesUntilDue <= 5) {
            // Task is due within the next 5 minutes
            shouldNotify = true;
            debugPrint('   → Task notification triggered: Due within 5 minutes');
          } else {
            debugPrint('   → No notification: Task is $minutesUntilDue minutes away');
          }
          
          if (shouldNotify) {
            _notifiedTaskIds.add(task['id'].toString());
            _showTaskNotification(task, associatedLead);
            _notifyTaskListeners(task, associatedLead);
            debugPrint('✅ Task notification sent: ${task['title']}');
          }
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
          
          // STRICT 5-MINUTE RULE: Only show notification if activity is scheduled within next 5 minutes
          bool shouldNotify = false;
          
          if (minutesUntilScheduled >= 0 && minutesUntilScheduled <= 5) {
            // Activity is scheduled within the next 5 minutes
            shouldNotify = true;
            debugPrint('   → Activity notification triggered: Scheduled within 5 minutes');
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
    _callbacks.clear();
    _taskCallbacks.clear();
    _activityCallbacks.clear();
    _notifiedLeadIds.clear();
    _notifiedTaskIds.clear();
    _notifiedActivityIds.clear();
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
