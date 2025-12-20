// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'tabs/home_tab.dart';     // We will create this next
import 'tabs/history_tab.dart';  // We will create this next
import 'tabs/profile_tab.dart';  // We will create this next

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  // The 3 Pages
  final List<Widget> _pages = [
    const HomeTab(),
    const HistoryTab(),
    const ProfileTab(),
  ];

  // Colors
  final Color mainColor = const Color(0xFF5F7E5B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      
      // --- MODERN FLOATING NAVBAR ---
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(20), // Float it off the bottom
        decoration: BoxDecoration(
          color: Colors.black87, // Dark modern look
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            backgroundColor: Colors.transparent, // Uses container color
            selectedItemColor: Color(0xFFDFE2D1), // Sage Light
            unselectedItemColor: Colors.white54,
            showSelectedLabels: false, // Cleaner look
            showUnselectedLabels: false,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: "Home"),
              BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: "History"),
              BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Profile"),
            ],
          ),
        ),
      ),
      // Use extendBody so the content goes behind the floating nav
      extendBody: true, 
    );
  }
}
