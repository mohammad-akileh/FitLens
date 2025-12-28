import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For SystemNavigator
import 'package:google_nav_bar/google_nav_bar.dart';
import '../services/database_service.dart';
import 'tabs/home_tab.dart';
import 'tabs/history_tab.dart';
import 'tabs/profile_tab.dart'; // Ensure you have this or use Placeholder

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

// 1. ADD THE OBSERVER MIXIN 👇
class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  // 🎨 COLORS
  final Color activeColor = const Color(0xFF5F7E5B);
  final Color tabBackgroundColor = const Color(0xB2DFE2D1);
  final Color iconColor = Colors.grey;
  final Color backgroundColor = const Color(0xFFF5F7F2);

  // 📅 GLOBAL DATE STATE
  DateTime _globalDate = DateTime.now();
  int _selectedIndex = 0;

  // ⏳ BACK BUTTON MEMORY
  DateTime? _lastPressedAt;

  @override
  void initState() {
    super.initState();
    // 2. LISTEN TO APP LIFECYCLE 👇
    WidgetsBinding.instance.addObserver(this);

    _repairUserDatabase();
    if (FirebaseAuth.instance.currentUser != null) {
      DatabaseService().checkAndResetDailyStats(FirebaseAuth.instance.currentUser!.uid);
    }
  }

  @override
  void dispose() {
    // 3. STOP LISTENING WHEN CLOSED 👇
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 4. THE LIFECYCLE FIX (The Ghost Buster 👻) 👇
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // The app just woke up!
      // Forcefully WIPE the back button memory so it doesn't remember the old click.
      setState(() {
        _lastPressedAt = null;
      });
      print("☀️ App Resumed - Back button memory wiped.");
    }
  }

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
    final List<Widget> widgetOptions = <Widget>[
      HomeTab(
        currentDate: _globalDate,
        onDateChanged: _updateDate,
      ),
      HistoryTab(
        currentDate: _globalDate,
      ),
      const Center(child: Text("Search Screen (Coming Soon)", style: TextStyle(fontSize: 24, color: Colors.grey))),
      const ProfileTab(),
    ];

    // 🛡️ POP SCOPE
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;

        // A. If NOT on Home Tab, go to Home Tab
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
          return;
        }

        // B. Double Tap Logic
        final now = DateTime.now();
        final maxDuration = const Duration(seconds: 2);

        // Check if the warning is still valid
        final isWarningStillActive = _lastPressedAt != null &&
            now.difference(_lastPressedAt!) < maxDuration;

        if (isWarningStillActive) {
          // EXIT APP
          // We wipe memory here too, just in case
          _lastPressedAt = null;
          SystemNavigator.pop();
        } else {
          // FIRST TAP
          _lastPressedAt = now;
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Tap back again to exit"),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.black87,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: widgetOptions.elementAt(_selectedIndex),
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
      ),
    );
  }
}