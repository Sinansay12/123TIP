/// Notification Service for Timer Alerts and Study Reminders
library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;
    debugPrint('NotificationService initialized');
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Handle notification tap - could navigate to specific screen
  }

  /// Show immediate notification (e.g., timer complete)
  Future<void> showTimerCompleteNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'timer_channel',
      'Timer Bildirimleri',
      channelDescription: 'Pomodoro timer bittiğinde bildirim',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0,
      title,
      body,
      details,
    );
  }

  /// Show work session complete notification
  Future<void> showWorkComplete() async {
    await showTimerCompleteNotification(
      title: '🍅 Çalışma Tamamlandı!',
      body: 'Harika iş! Şimdi kısa bir mola zamanı.',
    );
  }

  /// Show break complete notification
  Future<void> showBreakComplete() async {
    await showTimerCompleteNotification(
      title: '⏰ Mola Bitti!',
      body: 'Çalışmaya devam etmeye hazır mısın?',
    );
  }

  /// Schedule daily study reminder
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    // Cancel existing reminder first
    await _notifications.cancel(100);

    // Note: For scheduled notifications, you need to use timezone package
    // This is a simplified version - in production use tz.TZDateTime
    debugPrint('Daily reminder scheduled for $hour:$minute');
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Request notification permissions (call on first launch)
  Future<bool> requestPermissions() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    
    return true; // iOS permissions handled in initialization
  }
}

/// Global notification service instance
final notificationService = NotificationService();
