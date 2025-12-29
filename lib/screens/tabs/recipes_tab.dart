import 'package:flutter/material.dart';

class RecipesTab extends StatelessWidget {
  const RecipesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F5F0),
      appBar: AppBar(
        title: const Text("Healthy Recipes", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildRecipeCard("Avocado Toast", "350 kcal", "assets/egg.png"),
          _buildRecipeCard("Chicken Salad", "450 kcal", "assets/lunch_bowl.png"),
          _buildRecipeCard("Oatmeal Bowl", "280 kcal", "assets/snack.png"),
          // Add more here easily!
        ],
      ),
    );
  }

  Widget _buildRecipeCard(String title, String cals, String asset) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Row(
        children: [
          Image.asset(asset, width: 60, height: 60, errorBuilder: (c,o,s)=>const Icon(Icons.fastfood)),
          const SizedBox(width: 15),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(cals, style: const TextStyle(color: Colors.grey)),
          ]),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey)
        ],
      ),
    );
  }
}