import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_core/firebase_core.dart';
import '../auth_gate.dart';
import '../firebase_options.dart';
import 'package:fitlens/services/fcm_service.dart';

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

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToNextScreen();
      }
    });
  }

  void _startInitialization() async {
    // 1. Initialize Firebase (This is the BRAIN for Login/Auth)
    // We MUST wait for this, and we do.
    final firebaseFuture = Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 2. Minimum delay to let the animation start smoothly
    final animationFuture = Future.delayed(const Duration(seconds: 2));

    // Wait for BOTH (Core Firebase + Delay)
    await Future.wait([firebaseFuture, animationFuture]);

    // 🔴 3. SAFETY FIX: FCM INIT WITH TIMEOUT
    // This tries to connect notifications.
    // If it takes longer than 3 seconds (slow internet), it STOPS waiting
    // and lets the app open anyway. Login will still work!
    try {
      await FcmService.init().timeout(const Duration(seconds: 3));
    } catch (e) {
      print("⚠️ Slow Internet or FCM Error: Skipping to ensure app opens fast.");
    }

    // 4. Start the animation (This will now ALWAYS run, never get stuck)
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox(
        width: screenWidth,
        height: screenHeight,
        child: Lottie.asset(
          'assets/FlowLast.json', // Your verified asset
          controller: _controller,
          repeat: false,
          fit: BoxFit.cover,
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