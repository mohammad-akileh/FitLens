import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Run 'flutter pub add intl' if you get an error here
import '../../screens/meal_history_detail_screen.dart'; // Import the detail screen
class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Please login"));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2), // Matches your app theme
      appBar: AppBar(
        title: const Text("Meal History", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 📡 Listen to meals, ordered by newest first
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('meals')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No meals logged yet 🍽️"));
          }

          var docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              return _buildHistoryCard(context, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, Map<String, dynamic> data) {
    // Extract Data
    String imageUrl = data['image_url'] ?? "";
    String mealType = data['meal_type'] ?? "Meal";
    double calories = (data['total_calories'] ?? 0).toDouble();
    Timestamp? timestamp = data['timestamp'];

    // Format Date (e.g., "12:30 PM")
    String timeString = timestamp != null
        ? DateFormat('h:mm a').format(timestamp.toDate())
        : "Just now";

    // Format Date Header (e.g., "Oct 24")
    String dateString = timestamp != null
        ? DateFormat('MMM d').format(timestamp.toDate())
        : "";

    return GestureDetector(
      onTap: () {
        // 🔗 Navigate to the Detail Screen you created!
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MealHistoryDetailScreen(mealData: data),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            // 1. IMAGE (Left Side)
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
                image: imageUrl.isNotEmpty
                    ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                    : null,
                color: Colors.grey[200],
              ),
              child: imageUrl.isEmpty
                  ? const Icon(Icons.fastfood, color: Colors.grey)
                  : null,
            ),

            // 2. TEXT INFO (Middle)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      mealType, // e.g. "Lunch"
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "$dateString • $timeString",
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            // 3. CALORIES (Right Side)
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${calories.toInt()}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF5F7E5B)),
                  ),
                  const Text("kcal", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}