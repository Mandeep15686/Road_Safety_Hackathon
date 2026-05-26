import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidInit);
    
    await _notifications.initialize(settings);

    // Create the channel for Background Service to prevent "Bad notification" crash on Android 8.0+
    const channel = AndroidNotificationChannel(
      'crash_guard_channel', // MUST match main.dart
      'CrashGuard Background Service',
      description: 'Monitoring for accidents in background',
      importance: Importance.low,
      playSound: false,
      showBadge: false,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    tz.initializeTimeZones();
  }

  static Future<void> scheduleExpiryReminder(int id, String title, String body, DateTime expiryDate) async {
    // Schedule for 15 days before
    final reminder15 = expiryDate.subtract(const Duration(days: 15));
    if (reminder15.isAfter(DateTime.now())) {
      await _schedule(id * 10 + 1, "Expiry Alert: $title", "$body expires in 15 days", reminder15);
    }

    // Schedule for 5 days before
    final reminder5 = expiryDate.subtract(const Duration(days: 5));
    if (reminder5.isAfter(DateTime.now())) {
      await _schedule(id * 10 + 2, "Urgent Expiry: $title", "$body expires in 5 days!", reminder5);
    }
  }

  static Future<void> _schedule(int id, String title, String body, DateTime scheduledDate) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'expiry_reminders',
          'Document Expirations',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
