import 'package:fitlens/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'screens/splash_screen_video.dart';
import 'package:provider/provider.dart';
import 'services/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Notifications
  await NotificationService.init();

  // 2. 📅 SCHEDULE REMINDERS
  // Now you can pass (ID, Title, Body, HOUR, MINUTE)

  // TEST: If it is 7:10 AM, set this to 7, 12 (2 mins later)
  await NotificationService.scheduleDaily(
      1, "Hydration Check 💧", "Time to drink some water!", 14, 41);

  // Lunch at 1:00 PM
  await NotificationService.scheduleDaily(
      2, "Lunch Time 🥗", "Don't forget to scan your meal.", 13, 0);

  // Recap at 8:00 PM
  await NotificationService.scheduleDaily(
      3, "Daily Recap 🌙", "Check your calories for the day.", 20, 0);

  // 3. Run App
  runApp(
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
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FitLens',
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF6F5F0),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFF121212),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1E1E1E),
          selectedItemColor: Color(0xFF5F7E5B),
          unselectedItemColor: Colors.grey,
          elevation: 0,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}