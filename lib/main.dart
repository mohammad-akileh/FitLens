import 'package:fitlens/services/notification_service.dart';
// We don't need FcmService here anymore, it moves to Splash
import 'package:flutter/material.dart';
import 'screens/splash_screen_video.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Local Notifications ONLY
  // (We do NOT init Firebase here because Splash Screen does it)
  await NotificationService.init();

  runApp(const FitLensApp());
}

class FitLensApp extends StatelessWidget {
  const FitLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FitLens',
      // Simple Theme (No Provider, No Dark Mode button logic)
      // theme: ThemeData(
      //   brightness: Brightness.light,
      //   primarySwatch: Colors.green,
      //   scaffoldBackgroundColor: const Color(0xFFF6F5F0),
      // ),
      // darkTheme: ThemeData(
      //   brightness: Brightness.dark,
      //   primarySwatch: Colors.green,
      //   scaffoldBackgroundColor: const Color(0xFF121212),
      //   bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      //     backgroundColor: Color(0xFF1E1E1E),
      //     selectedItemColor: Color(0xFF5F7E5B),
      //     unselectedItemColor: Colors.grey,
      //     elevation: 0,
      //   ),
      // ),
      home: const SplashScreen(),
    );
  }
}