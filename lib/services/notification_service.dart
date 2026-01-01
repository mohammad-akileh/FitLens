import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz_data.initializeTimeZones();

    // 1. Force Jordan Time
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Amman'));
    } catch (e) {
      print("Timezone error: $e");
    }

    // 2. Setup Android Settings
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        print("🔔 CLICKED: ${details.payload}");
      },
    );
  }

  // --- 🔴 INSTANT TEST FUNCTION ---
  static Future<void> scheduleTestNotification() async {
    try {
      // 1. Ask Permission
      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      print("🧪 Attempting INSTANT notification...");

      // 2. SHOW IMMEDIATELY
      await _notifications.show(
        888, // Test ID
        'FitLens Test',
        'If you see this, IT WORKS! 🎉',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'fitlens_channel_v3',
            'FitLens Reminders',
            channelDescription: 'Reminders to log your meals',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
        ),
      );
      print("✅ Notification sent to system.");
    } catch (e) {
      print("🛑 ERROR: $e");
    }
  }

  // --- DAILY SCHEDULER (With Minutes Support) ---
  static Future<void> scheduleDaily(int id, String title, String body, int hour, int minute) async {
    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        _nextInstanceOfTime(hour, minute), // Pass minute to helper
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'fitlens_channel_v3',
            'FitLens Reminders',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      print("⏰ Scheduled reminder for $hour:$minute Jordan Time");
    } catch (e) {
      print("🛑 ERROR Scheduling Daily: $e");
    }
  }

  // --- HELPER FUNCTION (ONLY ONE VERSION NOW) ---
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    // Create date using hour AND minute
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  // --- ⚠️ WARNING NOTIFICATIONS (For Home Tab Limits) ---
  static Future<void> showWarning(String title, String body) async {
    try {
      print("🚀 Triggering Warning: $title");
      await _notifications.show(
        DateTime.now().millisecond, // Unique ID
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'fitlens_channel_v3',
            'FitLens Warnings',
            channelDescription: 'Alerts for exceeding limits',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
        ),
      );
    } catch (e) {
      print("🛑 ERROR Sending Warning: $e");
    }
  }
}