// lib/screens/main_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitlens/screens/tabs/recipes_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../services/database_service.dart';
import 'tabs/home_tab.dart';
import 'tabs/history_tab.dart';
import 'tabs/settings_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

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
    WidgetsBinding.instance.addObserver(this); // Start listening to lifecycle
    _repairUserDatabase();
    _runMidnightCheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Stop listening
    super.dispose();
  }

  // 🦅 THE GHOST BUSTER & TIME TRAVELER 🦅
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 1. Wipe Back Button Memory (Ghost Click Fix)
      setState(() {
        _lastPressedAt = null;
      });

      // 2. Check for New Day (Time Travel Fix)
      _checkIfDayChanged();

      // 3. Run the Database Reset Logic again just in case
      _runMidnightCheck();
    }
  }

  // Helper: Checks if the app is stuck on an old date
  void _checkIfDayChanged() {
    final now = DateTime.now();
    // If the selected date is NOT today...
    bool isSelectedDateToday = _globalDate.year == now.year &&
        _globalDate.month == now.month &&
        _globalDate.day == now.day;

    // ...BUT we were supposed to be on "Live Mode" (implying we drifted into a new day)
    // We force the calendar to jump to the new Today.
    if (!isSelectedDateToday) {
      // Only auto-jump if the user hasn't explicitly navigated way back in history.
      // For now, let's assume if the app wakes up, we prefer showing Today.
      print("📅 Detected a new day! Jumping to Today.");
      setState(() {
        _globalDate = now;
      });
    }
  }

  void _runMidnightCheck() {
    if (FirebaseAuth.instance.currentUser != null) {
      DatabaseService().checkAndResetDailyStats(FirebaseAuth.instance.currentUser!.uid);
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

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final userDoc = await userRef.get();

    // 🛡️ IF NEW USER (Or Broken Data): Create the PERFECT Clean Structure
    if (!userDoc.exists) {
      print("🚑 Creating Fresh User Database...");
      await userRef.set({
        // Profile Defaults
        'email': user.email,
        'first_name': user.displayName ?? 'Besti',
        'created_at': FieldValue.serverTimestamp(),
        'onboarding_completed': false, // Force them to check profile if needed

        // 🎯 Targets (Default Safety Net)
        'target_calories': 2000,
        'target_protein': 150,
        'target_carbs': 250,
        'target_fat': 65,
        'target_water': 2500,

        // 📅 The Anchor (Today's Date)
        'last_active_date': "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2,'0')}-${DateTime.now().day.toString().padLeft(2,'0')}",

        // ⚡ Live Counters (Start at 0)
        'current_calories': 0,
        'current_protein': 0,
        'current_carbs': 0,
        'current_fat': 0,
        'current_water': 0,

        'app_secret': 'FitLens_VIP_2025',
      }, SetOptions(merge: true));
      print("✅ Fresh User Database Created!");
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
        onDateChanged: _updateDate, // 👈 ADD THIS LINE
      ),
      const RecipesTab(),
      const SettingsTab(),
    ];

    // 🛡️ POP SCOPE
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;

        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
          return;
        }

        final now = DateTime.now();
        final maxDuration = const Duration(seconds: 2);
        final isWarningStillActive = _lastPressedAt != null &&
            now.difference(_lastPressedAt!) < maxDuration;

        if (isWarningStillActive) {
          _lastPressedAt = null;
          SystemNavigator.pop();
        } else {
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
        body: IndexedStack(
          index: _selectedIndex,
          children: widgetOptions,
        ),
        // inside main_screen.dart

        // inside lib/screens/main_screen.dart

        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            // 🔴 FIX 1: Change specific color to Dynamic Logic
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E1E1E) // Dark Grey for Dark Mode
                : Colors.white,           // White for Light Mode

            boxShadow: [
              BoxShadow(
                  blurRadius: 20,
                  color: Colors.black.withOpacity(.1)
              )
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
              child: GNav(
                // 🔴 FIX 2: Change Ripple to Dynamic
                rippleColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]!
                    : Colors.grey[300]!,

                // 🔴 FIX 3: Change Hover to Dynamic
                hoverColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[900]!
                    : Colors.grey[100]!,

                gap: 8,
                activeColor: const Color(0xFF5F7E5B), // Primary Green
                iconSize: 24,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                duration: const Duration(milliseconds: 400),

                // 🔴 FIX 4: Change Tab Background (Bubble) to Dynamic
                tabBackgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF5F7E5B).withOpacity(0.2)
                    : const Color(0xFF5F7E5B).withOpacity(0.1),

                // 🔴 FIX 5: Change Icon Color (Inactive) to Dynamic
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.black54,

                tabs: const [
                  GButton(icon: Icons.home_rounded, text: 'Home'),
                  GButton(icon: Icons.history_rounded, text: 'History'),
                  GButton(icon: Icons.receipt_long_sharp, text: 'Recipes'),
                  GButton(icon: Icons.settings, text: 'Settings'),
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