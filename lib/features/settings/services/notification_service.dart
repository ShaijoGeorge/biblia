import 'dart:developer' as log;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize the notification plugin
  Future<void> init() async {
    if (_isInitialized) return;

    _initializeTimezone();

    final settings = _initSettings();
    final didInit = await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _isInitialized = didInit ?? false;
    log.log('Notifications initialized: $_isInitialized',
        name: 'NotificationService');
  }

  /// Timezone setup
  Future<void> _initializeTimezone() async {
    tz.initializeTimeZones();

    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('Could not get local timezone: $e');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    /// fallback
    try {
      final localName = DateTime.now().timeZoneName;
      tz.setLocalLocation(tz.getLocation(localName));
      log.log('Fallback timezone set to: $localName',
          name: 'NotificationService');
    } catch (e) {
      log.log('Fallback to UTC: $e', name: 'NotificationService');
      tz.setLocalLocation(tz.UTC);
    }
  }

  InitializationSettings _initSettings() {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    return const InitializationSettings(android: android, iOS: ios);
  }

  void _onNotificationTap(NotificationResponse response) {
    log.log('Notification tapped: ${response.payload}',
        name: 'NotificationService');
  }

  /// Ask for permissions (must call before scheduling)
  Future<bool> requestPermissions() async {
    /// iOS
    final ios = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    /// Android (Android 13+)
    final android = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    final granted = (ios ?? true) && (android ?? true);

    log.log('Notification permissions granted: $granted',
        name: 'NotificationService');

    return granted;
  }

  /// Check if app is allowed to show notifications
  Future<bool> areNotificationsEnabled() async {
    if (!_isInitialized) await init();

    final android = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.areNotificationsEnabled();

    return android ?? true;
  }

  /// Daily reminder scheduler
  Future<void> scheduleDailyReminder(int hour, int minute) async {
    if (!_isInitialized) await init();

    await cancelReminders();

    final hasPermission = await requestPermissions();
    if (!hasPermission) {
      log.log('No permission, cannot schedule reminder',
          name: 'NotificationService');
      return;
    }

    final scheduled = _nextInstance(hour, minute);

    log.log('Scheduling reminder for: $scheduled',
        name: 'NotificationService');

    try {
      await _notificationsPlugin.zonedSchedule(
        0,
        'Bible Reading Time',
        'Time to read your daily chapters! 📖',
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder',
            'Daily Reminder',
            channelDescription: 'Daily Bible reading reminder',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      log.log('Daily reminder scheduled successfully!',
          name: 'NotificationService');
    } catch (e, st) {
      log.log('Failed to schedule reminder: $e',
          name: 'NotificationService', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Cancel all scheduled notifications
  Future<void> cancelReminders() async {
    if (!_isInitialized) await init();
    await _notificationsPlugin.cancelAll();
    log.log('All reminders cancelled', name: 'NotificationService');
  }

  /// Helper: Find next instance of [hour:minute]
  tz.TZDateTime _nextInstance(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);

    var date = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);

    if (date.isBefore(now)) {
      date = date.add(const Duration(days: 1));
    }

    return date;
  }

  /// Debug test notification
  Future<void> showTestNotification() async {
    if (!_isInitialized) await init();

    await _notificationsPlugin.show(
      999,
      'Test Notification',
      'If you see this, notifications are working! ✅',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Test Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );

    log.log('Test notification shown', name: 'NotificationService');
  }
}
