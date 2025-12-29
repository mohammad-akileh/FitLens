import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  // We use the 'late' keyword to ensure it initializes properly
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  // 1. Initialize
  static Future<void> init() async {
    // Initialize Timezones
    tz_data.initializeTimeZones();

    // Android Settings
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS/Linux Settings (Just in case)
    const InitializationSettings settings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(settings);
  }

  // 2. Schedule Daily Reminder
  static Future<void> scheduleDaily(int id, String title, String body, int hour) async {
    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        _nextInstanceOfTime(hour),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminders_channel',
            'Daily Reminders',
            channelDescription: 'Reminders to log meals',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        // 🛑 THIS IS THE LINE THAT WAS GIVING YOU TROUBLE
        // With version ^17.0.0, this will work perfectly.
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repeats daily
      );
    } catch (e) {
      print("Error scheduling notification: $e");
    }
  }

  // Helper: Get next time instance
  static tz.TZDateTime _nextInstanceOfTime(int hour) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  // 3. Instant Warning
  static Future<void> showWarning(String title, String body) async {
    try {
      await _notifications.show(
          999,
          title,
          body,
          const NotificationDetails(
              android: AndroidNotificationDetails(
                'warning_channel',
                'Warnings',
                channelDescription: 'Important alerts',
                color: Color(0xFFFF5252),
                importance: Importance.high,
                priority: Priority.high,
              )
          )
      );
    } catch (e) {
      print("Error showing warning: $e");
    }
  }
}