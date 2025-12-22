// lib/auth_gate.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitlens/screens/dummy_test_screen.dart';
import 'package:fitlens/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding/intro_screen.dart';
import 'screens/onboarding/onboarding_gender_screen.dart';

class AuthGate extends StatefulWidget {
  AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<User?> _authStream;

  @override
  void initState() {
    super.initState();
    _authStream = _authService.user;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStream,
      builder: (context, authSnapshot) {

        // User is not logged in
        if (!authSnapshot.hasData) {
          return LoginScreen();
        }

        // User is logged in, now we check their data
        if (authSnapshot.connectionState == ConnectionState.active) {
          User user = authSnapshot.data!;

          // --- THIS IS THE FIX ---
          // We changed this from a FutureBuilder to a StreamBuilder.
          // Now it will "react" when the user's document changes!
          return StreamBuilder<DocumentSnapshot>(
            stream: _firestore.collection('users').doc(user.uid).snapshots(), // .snapshots() listens
            builder: (context, firestoreSnapshot) {

              if (firestoreSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              if (firestoreSnapshot.hasError) {
                return const Scaffold(body: Center(child: Text("Error checking user data...")));
              }

              // Check if the document exists
              if (!firestoreSnapshot.data!.exists) {
                // This user's document hasn't been created yet
                // (This can happen if Google Sign In is slow)
                // We'll treat them as new.
                return OnboardingGenderScreen();
              }

              final data = firestoreSnapshot.data!.data() as Map<String, dynamic>?;

              // Check if onboarding is complete
              if (data != null && data.containsKey('onboarding_completed') && data['onboarding_completed'] == true) {

                // --- Onboarding is complete, show the app ---
                return MainScreen();//should be MainScreen

              } else {

                // --- Onboarding is NOT complete, show the 10 GUIs ---
                return IntroScreen();//should be IntroScreen

              }
            },
          );
        }

        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}