// lib/screens/tabs/home_tab.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../scan_screen.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  final Color mainColor = const Color(0xFF5F7E5B);
  final Color creamColor = const Color(0xFFF6F5F0);

  // Helper to check if a timestamp is "Today"
  bool _isToday(Timestamp? timestamp) {
    if (timestamp == null) return false;
    DateTime date = timestamp.toDate();
    DateTime now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: creamColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: StreamBuilder<DocumentSnapshot>(
            // 1. Listen to USER PROFILE (To get Goals)
            stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
            builder: (context, userSnap) {
              if (!userSnap.hasData) return Center(child: CircularProgressIndicator());

              final userData = userSnap.data!.data() as Map<String, dynamic>?;

              // Get Goals (Default to 2000 if missing)
              final int goalCals = userData?['target_calories'] ?? 2000;
              final int goalProt = userData?['target_protein'] ?? 150;
              final int goalCarbs = userData?['target_carbs'] ?? 250;
              final int goalFat = userData?['target_fat'] ?? 65;
              final String userName = userData?['name'] ?? "Friend"; // Assuming you saved name at signup

              return StreamBuilder<QuerySnapshot>(
                // 2. Listen to MEALS (To get Progress)
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('meals')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, mealSnap) {
                  // Calculate Today's Totals
                  double eatenCals = 0;
                  double eatenProt = 0;
                  double eatenCarbs = 0;
                  double eatenFat = 0;

                  if (mealSnap.hasData) {
                    for (var doc in mealSnap.data!.docs) {
                      Map<String, dynamic> meal = doc.data() as Map<String, dynamic>;
                      if (_isToday(meal['timestamp'])) {
                        eatenCals += (meal['total_calories'] ?? 0);
                        eatenProt += (meal['total_protein'] ?? 0);
                        eatenCarbs += (meal['total_carbs'] ?? 0);
                        eatenFat += (meal['total_fat'] ?? 0);
                      }
                    }
                  }

                  // Progress Math (0.0 to 1.0)
                  double progress = (eatenCals / goalCals).clamp(0.0, 1.0);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Welcome back,", style: TextStyle(color: Colors.grey, fontSize: 14)),
                              Text("Let's hit your goals!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          CircleAvatar(backgroundColor: mainColor, child: Icon(Icons.person, color: Colors.white)),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // Circular Tracker
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 200, height: 200,
                              child: CircularProgressIndicator(
                                value: 1.0, strokeWidth: 15, color: Colors.grey[300],
                              ),
                            ),
                            SizedBox(
                              width: 200, height: 200,
                              child: CircularProgressIndicator(
                                value: progress, // REAL PROGRESS!
                                strokeWidth: 15, color: mainColor, strokeCap: StrokeCap.round,
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 30),
                                Text(eatenCals.toStringAsFixed(0), style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                                Text("of $goalCals kcal", style: TextStyle(color: Colors.grey)),
                              ],
                            )
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Macros Row (Real Data!)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMacroCard("Protein", "${eatenProt.toStringAsFixed(0)} / ${goalProt}g", Colors.blue[100]!),
                          _buildMacroCard("Carbs", "${eatenCarbs.toStringAsFixed(0)} / ${goalCarbs}g", Colors.orange[100]!),
                          _buildMacroCard("Fat", "${eatenFat.toStringAsFixed(0)} / ${goalFat}g", Colors.red[100]!),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // Scan Button
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => ScanScreen()));
                          },
                          icon: Icon(Icons.camera_alt_rounded, color: Colors.white),
                          label: Text("Scan New Meal", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMacroCard(String label, String value, Color color) {
    return Container(
      width: 105, // Slightly wider to fit "50 / 150g"
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0,2))],
      ),
      child: Column(
        children: [
          CircleAvatar(radius: 5, backgroundColor: color),
          SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)), // Adjusted font size
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}