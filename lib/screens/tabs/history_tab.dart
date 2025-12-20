// lib/screens/tabs/history_tab.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../meal_history_detail_screen.dart';

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F5F0), // Cream
      appBar: AppBar(
        title: Text("Meal History", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('meals')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No meals scanned yet."));
          }

          final meals = snapshot.data!.docs;

          // inside history_tab.dart
// Don't forget to import: import '../meal_history_detail_screen.dart';

          return ListView.builder(
            padding: EdgeInsets.all(20),
            itemCount: meals.length + 1,
            itemBuilder: (context, index) {
              if (index == meals.length) return SizedBox(height: 100);

              final meal = meals[index].data() as Map<String, dynamic>;
              double cals = (meal['total_calories'] ?? 0).toDouble();

              // --- FORMAT THE DATE ---
              Timestamp? ts = meal['timestamp'];
              String dateString = "Unknown Date";
              if (ts != null) {
                DateTime date = ts.toDate();
                // Format: "12/9 - 10:30"
                dateString = "${date.month}/${date.day} • ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
              }
              // -----------------------

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MealHistoryDetailScreen(mealData: meal),
                    ),
                  );
                },
                child: Container(
                  margin: EdgeInsets.only(bottom: 15),
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
                  ),
                  child: Row(
                    children: [
                      // Thumbnail
                      Container(
                        height: 50, width: 50,
                        decoration: BoxDecoration(
                          color: Color(0xFF5F7E5B).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                          image: (meal['image_url'] != null && meal['image_url'] != "")
                              ? DecorationImage(image: NetworkImage(meal['image_url']), fit: BoxFit.cover)
                              : null,
                        ),
                        child: (meal['image_url'] == null || meal['image_url'] == "")
                            ? Icon(Icons.fastfood, color: Color(0xFF5F7E5B))
                            : null,
                      ),
                      SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- SHOW DATE HERE ---
                          Text(dateString, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("${cals.toStringAsFixed(0)} kcal", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                      Spacer(),
                      Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
