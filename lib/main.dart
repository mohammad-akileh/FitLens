// lib/main.dart
import 'package:fitlens/services/notification_service.dart';
import 'package:flutter/material.dart';
//import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen_video.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Notifications
  await NotificationService.init();

  // 2. 📅 SCHEDULE THE DAILY REMINDERS (This was missing!)
  // ID 1: 10:00 AM
  await NotificationService.scheduleDaily(
      1, "Hydration Check 💧", "Time to drink some water!", 10);

  // ID 2: 1:00 PM (13:00)
  await NotificationService.scheduleDaily(
      2, "Lunch Time 🥗", "Don't forget to scan your meal.", 13);

  // ID 3: 8:00 PM (20:00)
  await NotificationService.scheduleDaily(
      3, "Daily Recap 🌙", "Check your calories for the day.", 20);

  // 3. Run App (Splash Screen handles Firebase)
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FitLens', // We can set the name here
      home: SplashScreen(),
    );
  }
}