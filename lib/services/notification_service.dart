import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/lead.dart';

typedef NotificationCallback = void Function(Lead lead);

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final List<NotificationCallback> _callbacks = [];
  Timer? _notificationTimer;
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  final Set<String> _notifiedLeadIds = {};

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal() {
    _initializeNotifications();
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
    
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
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
      'Follow-up with ${lead.contactName} in 15 minutes',
      notificationDetails,
    );
  }

  void addListener(NotificationCallback callback) {
    _callbacks.add(callback);
  }

  void removeListener(NotificationCallback callback) {
    _callbacks.remove(callback);
  }

  void startMonitoring(List<Lead> leads) {
    _notificationTimer?.cancel();
    _notificationTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkNotifications(leads);
    });
  }

  void stopMonitoring() {
    _notificationTimer?.cancel();
  }

  void _checkNotifications(List<Lead> leads) {
    final now = DateTime.now();
    for (final lead in leads) {
      if (lead.followUpDate != null && !lead.isCompleted) {
        final followUpDateTime = DateTime(
          lead.followUpDate!.year,
          lead.followUpDate!.month,
          lead.followUpDate!.day,
          10,
          0,
        );
        final notificationTime = followUpDateTime.subtract(const Duration(minutes: 15));
        
        if (now.isAfter(notificationTime) && now.isBefore(followUpDateTime) && !_notifiedLeadIds.contains(lead.id)) {
          _notifiedLeadIds.add(lead.id);
          _showNotification(lead);
          _notifyListeners(lead);
        }
      }
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
    _notifiedLeadIds.clear();
  }
}
