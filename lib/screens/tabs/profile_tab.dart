// lib/screens/tabs/profile_tab.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth_gate.dart'; 

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => AuthGate()), 
      (route) => false, 
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F5F0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             CircleAvatar(radius: 50, backgroundColor: Color(0xFF5F7E5B), child: Icon(Icons.person, size: 50, color: Colors.white)),
             SizedBox(height: 20),
             Text("My Profile", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
             SizedBox(height: 40),
             
             // Sign Out Button
             TextButton.icon(
               onPressed: () => _signOut(context),
               icon: Icon(Icons.logout, color: Colors.red),
               label: Text("Sign Out", style: TextStyle(color: Colors.red, fontSize: 18)),
             )
          ],
        ),
      ),
    );
  }
}
