// lib/screens/tabs/history_tab.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../meal_history_detail_screen.dart'; // 👈 Import the detail screen

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

  void _setupMidnightTimer() {
    DateTime now = DateTime.now();
    DateTime nextMidnight = DateTime(now.year, now.month, now.day + 1);
    Duration timeUntilMidnight = nextMidnight.difference(now);
    _midnightTimer = Timer(timeUntilMidnight, () {
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
    if (_auth.currentUser == null)
      return const Center(child: CircularProgressIndicator());

    if (_isToday) {
      return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) => _buildLayout(),
      );
    } else {
      return _buildLayout();
    }
  }

  Widget _buildLayout() {
    return Scaffold(
      backgroundColor: bgCream,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              decoration: BoxDecoration(
                color: cardWhite,
                borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5))
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15)),
                    child: Text(DateFormat('d').format(widget.currentDate),
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: primaryGreen)),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat('MMMM').format(widget.currentDate),
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                      Text(DateFormat('EEEE, yyyy').format(widget.currentDate),
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildMealsList())),
          ],
        ),
      ),
    );
  }

  Widget _buildMealsList() {
    final user = _auth.currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<List<Map<String, dynamic>>>(
      key: ValueKey(widget.currentDate.toString()),
      stream: _dbService.getMealsForDate(user.uid, widget.currentDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        var meals = snapshot.data ?? [];
        if (meals.isEmpty) {
          return Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                Icon(Icons.no_meals, size: 60, color: Colors.grey[300]),
                Text("No meals logged.",
                    style: TextStyle(color: Colors.grey[500], fontSize: 16))
              ]));
        }
        return ListView.builder(
          itemCount: meals.length,
          padding: const EdgeInsets.only(bottom: 20),
          itemBuilder: (context, index) {
            var meal = meals[index];

            // 🔴 1. WRAP CONTAINER IN GESTURE DETECTOR
            return GestureDetector(
              onTap: () {
                // 🔴 2. NAVIGATE TO DETAIL SCREEN IN "READ ONLY" MODE
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MealHistoryDetailScreen(
                      mealData: meal,
                      isReadOnly: true, // 🔒 THIS PREVENTS EDITING
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: cardWhite,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 4))
                    ]),
                child: Row(
                  children: [
                    Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Colors.grey[200]),
                        child: meal['image_url'] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.network(meal['image_url'],
                                    fit: BoxFit.cover))
                            : const Icon(Icons.fastfood)),
                    const SizedBox(width: 15),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(meal['meal_type'] ?? 'Meal',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(
                              meal['timestamp'] != null
                                  ? DateFormat('h:mm a').format(
                                      (meal['timestamp'] as Timestamp).toDate())
                                  : "--:--",
                              style: TextStyle(color: Colors.grey[500]))
                        ])),
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                            color: bgCream,
                            borderRadius: BorderRadius.circular(12)),
                        child: Text(
                            "${(meal['total_calories'] ?? 0).toInt()} kcal",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: primaryGreen))),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
