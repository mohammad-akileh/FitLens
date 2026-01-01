// import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
// import 'package:fitlens/services/notification_service.dart';
//
// class AlarmService {
//   static Future<void> init() async {
//     await AndroidAlarmManager.initialize();
//   }
//
//   // 🔴 THE CALLBACK: Runs in the background when phone wakes up
//   @pragma('vm:entry-point')
//   static void triggerAlarm() {
//     print("⏰ ALARM MANAGER FIRED! Waking up Notification Service...");
//
//     // Initialize notifications and show the message immediately
//     NotificationService.init().then((_) {
//       NotificationService.showWarning(
//           "FitLens Reminder 🔔",
//           "Time to check your meals! 🥗"
//       );
//     });
//   }
//
//   // 🔴 THE SCHEDULER
//   static Future<void> scheduleDailyAlarm(int id, int hour, int minute) async {
//     // 1. Calculate Target Time
//     DateTime now = DateTime.now();
//     DateTime targetTime = DateTime(now.year, now.month, now.day, hour, minute);
//
//     // If time passed today, schedule for tomorrow
//     if (targetTime.isBefore(now)) {
//       targetTime = targetTime.add(const Duration(days: 1));
//     }
//
//     print("📌 Setting System Alarm (ID: $id) for: $targetTime");
//
//     // 2. Set the "Nuclear" Alarm
//     await AndroidAlarmManager.oneShotAt(
//       targetTime,
//       id,
//       triggerAlarm, // Calls the function above
//       exact: true,
//       wakeup: true, // ⚡ FORCE SCREEN/CPU WAKE UP
//       rescheduleOnReboot: true,
//       alarmClock: true, // ⚡ BYPASS BATTERY SAVER
//     );
//   }
// }