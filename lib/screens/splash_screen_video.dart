import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_core/firebase_core.dart';
import '../auth_gate.dart';
import '../firebase_options.dart';
import 'package:fitlens/services/fcm_service.dart'; // 👈 IMPORT FCM SERVICE

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
    // 1. Initialize Firebase
    final firebaseFuture = Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 2. Add delay for animation
    final animationFuture = Future.delayed(const Duration(seconds: 2));

    // Wait for BOTH to finish
    await Future.wait([firebaseFuture, animationFuture]);

    // 🔴 3. NOW INIT FCM (Safe because Firebase is done!)
    // This will print the Token to your console
    try {
      await FcmService.init();
    } catch (e) {
      print("⚠️ FCM Init Error (Non-fatal): $e");
    }

    // 4. Start the animation
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
          'assets/FlowLast.json',
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