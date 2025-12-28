import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../services/database_service.dart';
import 'tabs/home_tab.dart';
import 'tabs/history_tab.dart';
import 'tabs/profile_tab.dart'; // Ensure you have this file created

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // 🎨 COLOR ZONE
  final Color activeColor = const Color(0xFF5F7E5B);
  final Color tabBackgroundColor = const Color(0xB2DFE2D1);
  final Color iconColor = Colors.grey;
  final Color backgroundColor = const Color(0xFFF5F7F2);

  // 📅 THE BRAIN: GLOBAL DATE STATE
  // This variable stays alive even when you switch tabs!
  DateTime _globalDate = DateTime.now();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _repairUserDatabase();
    if (FirebaseAuth.instance.currentUser != null) {
      DatabaseService().checkAndResetDailyStats(FirebaseAuth.instance.currentUser!.uid);
    }
  }

  // Helper to update date from HomeTab
  void _updateDate(DateTime newDate) {
    setState(() {
      _globalDate = newDate;
    });
  }

  Future<void> _repairUserDatabase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!userDoc.exists) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': user.email,
        'first_name': user.displayName ?? 'Besti',
        'created_at': FieldValue.serverTimestamp(),
        'target_calories': 2000,
        'app_secret': 'FitLens_VIP_2025',
      }, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    // 📄 THE SCREENS (Rebuilt with the current Date)
    final List<Widget> screens = [
      // 1. HOME: We pass the date and the function to change it
      HomeTab(
        currentDate: _globalDate,
        onDateChanged: _updateDate,
      ),
      // 2. HISTORY: We pass the date so it knows what to show
      HistoryTab(
        currentDate: _globalDate,
      ),
      // 3. SEARCH (Dummy)
      const Center(child: Text("Search Screen (Coming Soon)", style: TextStyle(fontSize: 24, color: Colors.grey))),
      // 4. PROFILE
      const ProfileTab(),
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: screens.elementAt(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(blurRadius: 20, color: Colors.black.withOpacity(.1))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
              rippleColor: Colors.grey[300]!,
              hoverColor: Colors.grey[100]!,
              gap: 8,
              activeColor: activeColor,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: tabBackgroundColor,
              color: iconColor,
              tabs: const [
                GButton(icon: Icons.home_rounded, text: 'Home'),
                GButton(icon: Icons.history_rounded, text: 'History'),
                GButton(icon: Icons.search_rounded, text: 'Search'),
                GButton(icon: Icons.person_rounded, text: 'Profile'),
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