import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/recipe_service.dart';
import '../recipe_detail_screen.dart'; // Import the new screen

class RecipesTab extends StatefulWidget {
  const RecipesTab({super.key});

  @override
  State<RecipesTab> createState() => _RecipesTabState();
}

class _RecipesTabState extends State<RecipesTab> {
  final User? user = FirebaseAuth.instance.currentUser;
  Future<List<Recipe>>? _recommendationsFuture;

  // 🔍 Search Logic
  String _searchQuery = "";
  List<Recipe> _allRecipes = []; // Stores the full list from API

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F5F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Chef's Suggestions 👨‍🍳", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var data = snapshot.data!.data() as Map<String, dynamic>;
          int target = (data['target_calories'] ?? 2000).toInt();
          int current = (data['current_calories'] ?? 0).toInt();
          int remaining = target - current;

          // Fetch only if not initialized
          _recommendationsFuture ??= RecipeService.getSmartRecommendations(remaining);

          return Column(
            children: [
              // 1. 🔍 SEARCH BAR (Filters local list)
              Padding(
                padding: const EdgeInsets.all(20),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search in recommendations...",
                    prefixIcon: const Icon(Icons.search),
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.toLowerCase();
                    });
                  },
                ),
              ),

              // 2. 🍲 THE LIST
              Expanded(
                child: FutureBuilder<List<Recipe>>(
                  future: _recommendationsFuture,
                  builder: (context, recipeSnap) {
                    if (recipeSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Save full list for searching
                    if (recipeSnap.hasData) {
                      _allRecipes = recipeSnap.data!;
                    }

                    // Filter based on search query
                    final displayList = _allRecipes.where((r) =>
                        r.title.toLowerCase().contains(_searchQuery)
                    ).toList();

                    if (displayList.isEmpty) {
                      return const Center(child: Text("No recipes found matching your search."));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: displayList.length,
                      itemBuilder: (context, index) {
                        return _buildRecipeCard(displayList[index], context);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe, BuildContext context) {
    return GestureDetector(
      // 👇 ON TAP: OPEN DETAILS
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (c) => RecipeDetailScreen(recipe: recipe)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(recipe.imageUrl, height: 150, width: double.infinity, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.local_fire_department, size: 16, color: Colors.orange),
                      Text(" ${recipe.calories} kcal  ", style: TextStyle(fontWeight: FontWeight.bold)),
                      Icon(Icons.fitness_center, size: 16, color: Colors.blue),
                      Text(" ${recipe.protein}g P"),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}