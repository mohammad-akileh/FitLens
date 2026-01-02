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
      home: const SplashScreen(),
    );
  }
}