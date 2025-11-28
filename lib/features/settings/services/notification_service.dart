import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  // Singleton pattern (only one instance of this class exists)
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Initialize Timezones
    tz.initializeTimeZones();

    // 2. Android Settings (Use the app icon)
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // 3. iOS Settings
    final DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false, // request later
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    // 4. Initialize Plugin
    await _notificationsPlugin.initialize(
      InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

  // Request Permissions (Required for Android 13+ and iOS)
  Future<void> requestPermissions() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // Schedule the Daily Reminder
  Future<void> scheduleDailyReminder(int hour, int minute) async {
    // First, cancel any existing reminder so we don't have duplicates
    await cancelReminders();

    await _notificationsPlugin.zonedSchedule(
      0, // Notification ID
      'Bible Reading Time', // Title
      'Time to read your daily chapters! 📖', // Body
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder', // Channel ID
          'Daily Reminder', // Channel Name
          channelDescription: 'Daily Bible reading reminder',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      // This ensures it repeats daily at the same time
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // REPEAT DAILY
    );
  }

  Future<void> cancelReminders() async {
    await _notificationsPlugin.cancelAll();
  }

  // Helper to calculate "Next 7:00 AM" (Today or Tomorrow?)
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}