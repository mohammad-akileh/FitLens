import 'package:flutter/material.dart';
import '../services/recipe_service.dart';

class RecipeDetailScreen extends StatelessWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // 1. Big Image Header
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(recipe.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black, blurRadius: 10)]
                  )
              ),
              background: Image.network(
                recipe.imageUrl,
                fit: BoxFit.cover,
                // 🔴 FIX: Show Fallback image instead of Grey Box
                errorBuilder: (c,o,s) => Image.network(
                    Recipe.fallbackImage,
                    fit: BoxFit.cover
                ),
              ),
            ),
          ),

          // 2. Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _macroBadge("🔥 ${recipe.calories}", "Kcal", Colors.orange),
                      _macroBadge("💪 ${recipe.protein}g", "Protein", Colors.blue),
                      _macroBadge("🌾 ${recipe.carbs}g", "Carbs", Colors.green),
                      _macroBadge("🥑 ${recipe.fat}g", "Fat", Colors.red),
                    ],
                  ),
                  const SizedBox(height: 25),

                  const Text("Ingredients", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...recipe.ingredients.map((ing) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF5F7E5B), size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text(ing, style: const TextStyle(fontSize: 16))),
                      ],
                    ),
                  )),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _macroBadge(String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}