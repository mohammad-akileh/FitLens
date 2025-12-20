// lib/screens/meal_history_detail_screen.dart
import 'package:flutter/material.dart';

class MealHistoryDetailScreen extends StatelessWidget {
  final Map<String, dynamic> mealData;

  const MealHistoryDetailScreen({super.key, required this.mealData});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> foodItems = mealData['food_items'] ?? [];
    final String imageUrl = mealData['image_url'] ?? "";
    final double totalCals = (mealData['total_calories'] ?? 0).toDouble();

    // Your colors
    final Color mainTextColor = const Color(0xFF5F7E5B);
    final Color cardBgColor = const Color(0xFFF6F5F0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Meal Details", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 1. The Image (If it exists)
          Container(
            height: 250,
            width: double.infinity,
            color: Colors.grey[200],
            child: imageUrl.isNotEmpty
                ? Image.network(imageUrl, fit: BoxFit.cover)
                : Icon(Icons.restaurant, size: 50, color: Colors.grey),
          ),

          // 2. Summary
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total Calories", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("${totalCals.toStringAsFixed(0)} kcal", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: mainTextColor)),
              ],
            ),
          ),

          Divider(),

          // 3. The List of Items
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: foodItems.length,
              itemBuilder: (context, index) {
                final item = foodItems[index];
                return _buildHistoryCard(item, cardBgColor, mainTextColor);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item, Color bg, Color text) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['food_name'] ?? "Unknown", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(item['serving_unit'] ?? "1 serving", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              Text("${item['calories_per_serving'] ?? 0} kcal", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: text)),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniMacro("Prot", "${item['protein_per_serving'] ?? 0}g", Colors.blue[100]!),
              _buildMiniMacro("Carb", "${item['carbs_per_serving'] ?? 0}g", Colors.orange[100]!),
              _buildMiniMacro("Fat", "${item['fat_per_serving'] ?? 0}g", Colors.red[100]!),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMiniMacro(String label, String val, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text("$label: $val", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
