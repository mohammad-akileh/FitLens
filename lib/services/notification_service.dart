import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  // 🟢 SINGLE ID FOR EVERYTHING (Prevents the "v3 vs v4" bug)
  static const String _channelId = 'fitlens_reminders_final';

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

    const InitializationSettings settings =
    InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        print("🔔 CLICKED: ${details.payload}");
      },
    );

    // 3. Ask for Permission IMMEDIATELY on launch
    final bool? granted = await _notifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    print("🔔 Permission Status: $granted");
  }

  // --- 🧪 INSTANT TEST FUNCTION ---
  static Future<void> scheduleTestNotification() async {
    try {
      // Re-ask permission just in case
      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      print("🧪 Attempting INSTANT notification...");

      await _notifications.show(
        888, // Test ID
        'FitLens Test',
        'If you see this, IT WORKS! 🎉',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId, // 🟢 USES THE UNIFIED ID
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

  // --- 📅 DAILY SCHEDULER (Reliable Inexact Mode) ---
  static Future<void> scheduleDaily(int id, String title, String body, int hour, int minute) async {
    try {
      print("📌 Scheduling reminder at $hour:$minute");
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        _nextInstanceOfTime(hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId, // 🟢 USES THE UNIFIED ID
            'FitLens Reminders',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            ongoing: false,
            autoCancel: true,
          ),
        ),
        // 🟢 INEXACT MODE (Reliable, bypasses strict permissions)
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,

        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      print("✅ Reminder scheduled successfully");
      print("⏰ Scheduled REPEATING reminder for $hour:$minute Jordan Time");
    } catch (e) {
      print("🛑 ERROR Scheduling Daily: $e");
    }
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
            _channelId, // 🟢 USES THE UNIFIED ID
            'FitLens Warnings',
            channelDescription: 'Alerts for exceeding limits',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
            ongoing: false,
            autoCancel: true,
          ),
        ),
      );
    } catch (e) {
      print("🛑 ERROR Sending Warning: $e");
    }
  }

  // --- HELPER FUNCTION ---
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}