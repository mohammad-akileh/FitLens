// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen_video.dart';

void main() async {
  // We only need this one line in main now.
  WidgetsFlutterBinding.ensureInitialized();

  // We REMOVED the Firebase.initializeApp() from here.

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