// lib/screens/splash_screen_video.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_core/firebase_core.dart';
import '../auth_gate.dart';
import '../firebase_options.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);

    // Listen for when the animation finishes
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToNextScreen();
      }
    });
  }

  void _startInitialization() async {
    // 1. Initialize Firebase
    final firebaseFuture = Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 2. Add a tiny minimum delay so the animation doesn't flash too fast
    final animationFuture = Future.delayed(const Duration(seconds: 2));

    // Wait for both
    await Future.wait([firebaseFuture, animationFuture]);

    // 3. Start the animation
    _controller.forward();
  }

  void _navigateToNextScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AuthGate()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsiveness
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white, // Matches your animation background
      body: SizedBox(
        width: screenWidth,
        height: screenHeight,
        child: Lottie.asset(
          'assets/Flow.json', // ⚠️ Verify this name is correct!

          controller: _controller,

          // 🛑 STOP THE LOOPING!
          repeat: false,

          // 📏 RESPONSIVE FIT
          // 'cover' fills the screen. Since you manually moved the girl,
          // this will now look perfect on all screens.
          fit: BoxFit.cover,

          // 🎯 ALIGNMENT
          // Centers the video. Since you edited the girl's position,
          // Center is usually safest now.
          alignment: Alignment.center,

          width: screenWidth,
          height: screenHeight,

          onLoaded: (composition) {
            _controller.duration = composition.duration;
            _startInitialization();
          },
        ),
      ),
    );
  }
}