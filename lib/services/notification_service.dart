// lib/services/notification_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // 1. Init Timezone
    tz_data.initializeTimeZones();

    // 2. Setup Android Settings
    // ⚠️ IMPORTANT: We use 'mipmap/ic_launcher' which exists by default.
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(android: androidSettings);

    // 3. Initialize Plugin
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        print("🔔 User clicked on notification: ${details.payload}");
      },
    );
    print("✅ Notification Service Initialized!");
  }

  static Future<void> showWarning(String title, String body) async {
    try {
      print("🚀 Attempting to show notification: $title");

      await _notifications.show(
          DateTime.now().millisecond, // Unique ID every time
          title,
          body,
          const NotificationDetails(
              android: AndroidNotificationDetails(
                'channel_warning_v2', // 👈 CHANGED ID (Forces phone to reset settings)
                'Important Warnings',
                channelDescription: 'Alerts for exceeding limits',
                importance: Importance.max,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher', // Explicitly setting icon
                enableVibration: true,
                playSound: true,
              )
          )
      );
      print("🦅 Notification sent to system!");
    } catch (e) {
      print("🛑 ERROR Sending Notification: $e");
    }
  }

  // ... (Keep scheduleDaily and helper functions same as before)
  static Future<void> scheduleDaily(int id, String title, String body, int hour) async {
    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        _nextInstanceOfTime(hour),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'channel_daily_v2', // 👈 CHANGED ID here too
            'Daily Reminders',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      print("⏰ Scheduled reminder for $hour:00");
    } catch (e) {
      print("🛑 ERROR Scheduling: $e");
    }
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}