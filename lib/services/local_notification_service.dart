import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    
    await _notifications.initialize(settings);
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
