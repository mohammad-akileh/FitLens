// lib/widgets/auth_background.dart
import 'dart:ui'; // <-- THIS IS THE FIX (a colon, not a period)
import 'package:flutter/material.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. The Background Image (pic2.jpg)
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/pic2.jpg'), // Make sure this is in assets/
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. The Blur Effect
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              color: Colors.black.withOpacity(0.3), // Dark overlay
            ),
          ),

          // 3. Your Page Content (Login form, etc.)
          SafeArea(
            child: child,
          ),
        ],
      ),
    );
  }
}