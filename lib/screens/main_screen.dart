import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart'; // 📦 The Package
import 'tabs/home_tab.dart'; // Your actual Home Screen
import 'tabs/history_tab.dart'; // (Uncomment when you have these)
import 'tabs/profile_tab.dart'; // (Uncomment when you have these)

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // 🎨 COLOR ZONE -------------------------------------------------------------
  // Modify these to change the Bottom Bar look
  final Color activeColor = const Color(0xFF5F7E5B); // Dark Green (Selected Text/Icon)
  final Color tabBackgroundColor = const Color(0xB2DFE2D1); // Light Green (The Pill 💊)
  final Color iconColor = Colors.grey; // Unselected Icon
  final Color backgroundColor = const Color(0xFFF5F7F2); // Bar Background
  // ---------------------------------------------------------------------------
// inside _MainScreenState class...

  @override
  void initState() {
    super.initState();
    _repairUserDatabase(); // 🚑 Call the Doctor!
  }

  Future<void> _repairUserDatabase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    if (!userDoc.exists) {
      print("🚑 REPAIRING USER DATABASE...");
      // Create the missing document
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': user.email,
        'first_name': user.displayName ?? 'Besti',
        'created_at': FieldValue.serverTimestamp(),
        'target_calories': 2000, // Default safety values
        'app_secret': 'FitLens_VIP_2025',
      }, SetOptions(merge: true));
      print("✅ User Database Repaired!");
    }
  }
  int _selectedIndex = 0;

  // 📄 THE SCREENS
  // This list controls what shows up when you click the buttons.
  // For tomorrow's demo, I put "Placeholder" widgets for History/Profile.
  // We will replace them with real screens later!
  static final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(), // 🏠 1. The Real Home Screen
    const HistoryTab(), // 📊 2. The Real History Screen
    const Center(child: Text("Search Screen (Coming Soon)", style: TextStyle(fontSize: 24, color: Colors.grey))), // 🔍 3. Dummy Search
    const Center(child: Text("Profile Screen (Coming Soon)", style: TextStyle(fontSize: 24, color: Colors.grey))), // 👤 4. Dummy Profile
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      // 🔄 THE BODY SWITCHER
      body: _widgetOptions.elementAt(_selectedIndex),

      // ⚓ THE BOTTOM BAR
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withOpacity(.1),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
              rippleColor: Colors.grey[300]!,
              hoverColor: Colors.grey[100]!,
              gap: 8, // Space between icon and text
              activeColor: activeColor, // 🎨 Selected Color
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: tabBackgroundColor, // 🎨 The Pill Color
              color: iconColor, // 🎨 Unselected Icon Color

              tabs: const [
                GButton(
                  icon: Icons.home_rounded,
                  text: 'Home',
                ),
                GButton(
                  icon: Icons.history_rounded, // Or Icons.favorite_border
                  text: 'History',
                ),
                GButton(
                  icon: Icons.search_rounded,
                  text: 'Search',
                ),
                GButton(
                  icon: Icons.person_rounded,
                  text: 'Profile',
                ),
              ],
              selectedIndex: _selectedIndex,
              onTabChange: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}