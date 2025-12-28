import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Needed for Timestamp
import '../../services/database_service.dart';
import '../meal_history_detail_screen.dart';

class HistoryTab extends StatelessWidget {
  final DateTime currentDate;

  const HistoryTab({super.key, required this.currentDate});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Please login"));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: AppBar(
        title: Text("History: ${DateFormat('MMMM d').format(currentDate)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // 🔑 THIS IS THE MAGIC: It updates automatically when HomeTab changes the date
        key: ValueKey(currentDate.toString()),
        stream: DatabaseService().getMealsForDate(user.uid, currentDate),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 10),
                  Text("No history for ${DateFormat('MMMM d').format(currentDate)}",
                      style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }

          var meals = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: meals.length,
            itemBuilder: (context, index) {
              var meal = meals[index];
              return _buildHistoryCard(context, meal);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, Map<String, dynamic> data) {
    String imageUrl = data['image_url'] ?? "";
    String mealType = data['meal_type'] ?? "Meal";
    double calories = (data['total_calories'] ?? 0).toDouble();
    Timestamp? timestamp = data['timestamp'];

    String timeString = timestamp != null
        ? DateFormat('h:mm a').format(timestamp.toDate())
        : "Just now";

    return GestureDetector(
      // 📄 OPEN DETAIL
      // 🔑 THIS IS THE MAGIC: It updates automatically when HomeTab changes the date
      //onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MealHistoryDetailScreen(mealData: data))),
      onTap: () {/*To open the detail screen () => Navigator.push(context, MaterialPageRoute(builder: (context) => MealHistoryDetailScreen(mealData: data))) */},
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
                image: imageUrl.isNotEmpty ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) : null,
                color: Colors.grey[200],
              ),
              child: imageUrl.isEmpty ? const Icon(Icons.fastfood, color: Colors.grey) : null,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(mealType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 5),
                    Text(timeString, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("${calories.toInt()}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF5F7E5B))),
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