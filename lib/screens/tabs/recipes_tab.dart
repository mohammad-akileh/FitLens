import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/recipe_service.dart';
import '../../services/favorites_service.dart';
import '../favorites_screen.dart';
import '../recipe_detail_screen.dart';

class RecipesTab extends StatefulWidget {
  const RecipesTab({super.key});

  @override
  State<RecipesTab> createState() => _RecipesTabState();
}

class _RecipesTabState extends State<RecipesTab> {
  final User? user = FirebaseAuth.instance.currentUser;

  Future<List<Recipe>>? _recommendationsFuture;
  int? _lastFetchedTarget;

  // 🔍 Search Logic
  String _searchQuery = "";
  List<Recipe> _allRecipes = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFE2D1),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Chef's Suggestions 👨‍🍳", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.red),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (c) => const FavoritesScreen()));
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          // 🛡️ SAFEST WAY TO READ DATA
          // checks if data exists, handles nulls, handles doubles/ints safely
          var data = snapshot.data!.data() as Map<String, dynamic>?;

          // Safety Default: If data is totally null, assume 0
          if (data == null) return const Center(child: Text("Loading Profile..."));

          int target = (data['target_calories'] as num? ?? 2000).toInt();
          int current = (data['current_calories'] as num? ?? 0).toInt();
          int remaining = target - current;

          // DYNAMIC REFRESH LOGIC (Normal Cache)
          if (_lastFetchedTarget == null || (remaining - _lastFetchedTarget!).abs() > 50) {
            _lastFetchedTarget = remaining;
            _recommendationsFuture = RecipeService.getSmartRecommendations(remaining);
          }

          return Column(
            children: [
              // 1. SEARCH BAR
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

              // 2. THE LIST
              Expanded(
                child: FutureBuilder<List<Recipe>>(
                  future: _recommendationsFuture,
                  builder: (context, recipeSnap) {
                    if (recipeSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (recipeSnap.hasData) {
                      _allRecipes = recipeSnap.data!;
                    }

                    // Filter based on search query
                    final displayList = _allRecipes.where((r) =>
                        r.title.toLowerCase().contains(_searchQuery)
                    ).toList();

                    if (displayList.isEmpty) {
                      return const Center(child: Text("No recipes found."));
                    }

                    // 🔴 REFRESH INDICATOR (The Fix)
                    return RefreshIndicator(
                      onRefresh: () async {
                        // FORCE REFRESH: Bust the cache
                        var newRecipes = await RecipeService.getSmartRecommendations(remaining, forceRefresh: true);
                        setState(() {
                          _recommendationsFuture = Future.value(newRecipes);
                          _lastFetchedTarget = remaining; // Update tracker
                        });
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: displayList.length,
                        itemBuilder: (context, index) {
                          return _buildRecipeCard(displayList[index], context);
                        },
                      ),
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
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(
                    recipe.imageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    // Safety check for broken images
                    errorBuilder: (context, error, stackTrace) {
                      return Image.network(
                        Recipe.fallbackImage, // Uses shared backup
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: FavoriteButton(recipe: recipe),
                )
              ],
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
                      const Icon(Icons.local_fire_department, size: 16, color: Colors.orange),
                      Text(" ${recipe.calories} kcal  ", style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Icon(Icons.fitness_center, size: 16, color: Colors.blue),
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

// ------------------------------------------------------------------
// ✅ FAVORITE BUTTON (Ensured Included)
// ------------------------------------------------------------------

class FavoriteButton extends StatelessWidget {
  final Recipe recipe;
  const FavoriteButton({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    final FavoritesService favService = FavoritesService();

    // Listens to the DB live!
    return StreamBuilder<List<Recipe>>(
      stream: favService.getFavoritesStream(),
      builder: (context, snapshot) {

        bool isFav = false;
        if (snapshot.hasData) {
          // Check if this recipe exists in the favorites list
          isFav = snapshot.data!.any((r) => r.title == recipe.title);
        }

        return CircleAvatar(
          backgroundColor: Colors.white,
          radius: 18,
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(
              isFav ? Icons.star : Icons.star_border,
              color: isFav ? Colors.orange : Colors.grey,
              size: 22,
            ),
            onPressed: () async {
              if (isFav) {
                await favService.removeFavorite(recipe.title);
              } else {
                await favService.addFavorite(recipe);
              }
            },
          ),
        );
      },
    );
  }
}