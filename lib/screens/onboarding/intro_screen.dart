// lib/screens/onboarding/intro_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'onboarding_gender_screen.dart';
import '../login_screen.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  // Text Color (Deep Sage)
  final Color mainTextColor = const Color(0xFF5F7E5B);
  // Button Background Color (Light Sage - Same as Gender Screen)
  final Color buttonColor = const Color(0xFFDFE2D1);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Image
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/intro_back.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. Back/SignOut Button
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.8),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: mainTextColor),
                onPressed: () async {
                  // Just sign out. AuthGate will handle the rest!
                  await FirebaseAuth.instance.signOut();
                },
              ),
            ),
          ),

          // 3. White Card Overlay
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              height: screenHeight * 0.45,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(30, 40, 30, 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Track Your Nutrition,\nTransform Your\nHealth",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: mainTextColor,
                        height: 1.5,
                        fontFamily: 'serif',
                      ),
                    ),
                    SizedBox(height: 15),
                    Text(
                      "Stay healthy by tracking every meal.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: mainTextColor.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Spacer(),

                    // --- CORRECTED BUTTON ---
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OnboardingGenderScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor, // <-- #DFE2D1 (Light Sage)
                          foregroundColor: Colors.black, // <-- Black text to pop out
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          "Continue",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // ------------------------
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}