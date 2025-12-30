// lib/main.dart
import 'package:fitlens/services/notification_service.dart';
import 'package:flutter/material.dart';
//import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen_video.dart';
import 'package:provider/provider.dart'; // 1. Import Provider
import 'services/theme_provider.dart';   // 2. Import your new ThemeProvider

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
  runApp(
    // 3. WRAP THE APP IN PROVIDER
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const FitLensApp(),
    ),
  );
}

class FitLensApp extends StatelessWidget {
  const FitLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 4. LISTEN TO THEME CHANGES
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FitLens',

      // 5. SET UP THEMES
      themeMode: themeProvider.themeMode, // Switches automatically!
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF6F5F0),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFF121212),
        // Define dark mode colors here if you want specifics
      ),

      home: const SplashScreen(), // Splash Screen handles Firebase
    );
  }
}