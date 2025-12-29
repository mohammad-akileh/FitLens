// lib/screens/tabs/history_tab.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';

class HistoryTab extends StatefulWidget {
  final DateTime currentDate;
  final Function(DateTime) onDateChanged;

  const HistoryTab({
    super.key,
    required this.currentDate,
    required this.onDateChanged,
  });

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Timer? _midnightTimer;

  // 🎨 COLORS
  final Color primaryGreen = const Color(0xFF5F7E5B);
  final Color bgCream = const Color(0xFFF6F5F0);
  final Color cardWhite = Colors.white;

  @override
  void initState() {
    super.initState();
    _setupMidnightTimer();
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }

  // 🕛 MIDNIGHT AUTO-RESET LOGIC
  void _setupMidnightTimer() {
    DateTime now = DateTime.now();
    DateTime nextMidnight = DateTime(now.year, now.month, now.day + 1);
    Duration timeUntilMidnight = nextMidnight.difference(now);

    _midnightTimer = Timer(timeUntilMidnight, () {
      print("🕛 Midnight Timer Triggered in History Tab!");
      widget.onDateChanged(DateTime.now());
      _setupMidnightTimer();
    });
  }

  bool get _isToday {
    final now = DateTime.now();
    return widget.currentDate.year == now.year &&
        widget.currentDate.month == now.month &&
        widget.currentDate.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;
    if (user == null) return const Center(child: Text("Please login"));

    if (_isToday) {
      // 🟢 TODAY: Listen to LIVE data stream to see meals instantly
      // We wrap it in a StreamBuilder to trigger rebuilds when database changes
      return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          // We don't actually need the user doc data here,
          // just the signal to rebuild the meal list if needed.
          // The real work happens in _buildMealsList which calls getMealsForDate
          return _buildLayout();
        },
      );
    } else {
      // 🟡 PAST: Just build the layout, the FutureBuilder is inside _buildMealsList for data
      return _buildLayout();
    }
  }

  Widget _buildLayout() {
    return Scaffold(
      backgroundColor: bgCream,
      body: SafeArea(
        child: Column(
          children: [
            // 1. BEAUTIFUL HEADER 📅
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              decoration: BoxDecoration(
                color: cardWhite,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Row(
                children: [
                  // Big Date Number
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      DateFormat('d').format(widget.currentDate),
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: primaryGreen
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  // Month & Year
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MMMM').format(widget.currentDate),
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87
                        ),
                      ),
                      Text(
                        DateFormat('EEEE, yyyy').format(widget.currentDate),
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Icon
                  Icon(Icons.history_edu, color: primaryGreen, size: 28),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. THE MEALS LIST (Expanded to fill space)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildMealsList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      key: ValueKey(widget.currentDate.toString()), // Forces refresh when date changes
      stream: _dbService.getMealsForDate(_auth.currentUser!.uid, widget.currentDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var meals = snapshot.data ?? [];

        if (meals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.no_meals, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 15),
                Text(
                  "No meals logged.",
                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: meals.length,
          padding: const EdgeInsets.only(bottom: 20),
          itemBuilder: (context, index) {
            var meal = meals[index];
            int cals = (meal['total_calories'] ?? 0).toInt();
            String? url = meal['image_url'];

            // 🛑 NO GESTURE DETECTOR / INKWELL = NOT CLICKABLE
            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardWhite,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 4)
                  )
                ],
              ),
              child: Row(
                children: [
                  // Image
                  Container(
                    width: 70, height: 70,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.grey[200]
                    ),
                    child: url != null && url.isNotEmpty
                        ? ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(url, fit: BoxFit.cover))
                        : Icon(Icons.fastfood, color: Colors.grey[400]),
                  ),
                  const SizedBox(width: 15),

                  // Meal Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            meal['meal_type'] ?? 'Meal',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87
                            )
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                                DateFormat('h:mm a').format((meal['timestamp'] as Timestamp).toDate()),
                                style: TextStyle(color: Colors.grey[500], fontSize: 13)
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Calories Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                        color: bgCream,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primaryGreen.withOpacity(0.1))
                    ),
                    child: Text(
                        "$cals kcal",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: primaryGreen
                        )
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}