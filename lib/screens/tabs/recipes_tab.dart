import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/recipe_service.dart';
import '../../services/favorites_service.dart'; // Import your favorites service
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
  int? _lastFetchedTarget; // ✅ Tracks when to refresh dynamic data

  // 🔍 Search Logic
  String _searchQuery = "";
  List<Recipe> _allRecipes = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F5F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Chef's Suggestions 👨‍🍳", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.red),
            onPressed: () {
              // Navigate to the new Favorites Screen
              Navigator.push(context, MaterialPageRoute(builder: (c) => const FavoritesScreen()));
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var data = snapshot.data!.data() as Map<String, dynamic>;
          int target = (data['target_calories'] ?? 2000).toInt();
          int current = (data['current_calories'] ?? 0).toInt();
          int remaining = target - current;

          // ✅ DYNAMIC REFRESH LOGIC
          // If we haven't fetched yet, OR if the target changed by >50 calories
          if (_lastFetchedTarget == null || (remaining - _lastFetchedTarget!).abs() > 50) {
            print("🔄 Targets changed! Refreshing recipes...");
            _lastFetchedTarget = remaining;
            _recommendationsFuture = RecipeService.getSmartRecommendations(remaining);
          }

          return Column(
            children: [
              // 1. 🔍 SEARCH BAR
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
            // ✅ IMAGE + FAVORITE BUTTON STACK
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(recipe.imageUrl, height: 150, width: double.infinity, fit: BoxFit.cover),
                ),
                // ❤️ The Favorite Button (Bottom Right of Image)
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: FavoriteButton(recipe: recipe), // Separate widget to prevent lag
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

// ✅ NEW WIDGET: Handles the star logic independently
class FavoriteButton extends StatefulWidget {
  final Recipe recipe;
  const FavoriteButton({super.key, required this.recipe});

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  bool isFav = false;
  final FavoritesService _favService = FavoritesService();

  @override
  void initState() {
    super.initState();
    _checkFav();
  }

  void _checkFav() async {
    bool fav = await _favService.isFavorite(widget.recipe.title);
    if (mounted) setState(() => isFav = fav);
  }

  void _toggleFav() async {
    setState(() => isFav = !isFav); // Instant UI update
    if (isFav) {
      await _favService.addFavorite(widget.recipe);
    } else {
      await _favService.removeFavorite(widget.recipe.title);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Colors.white,
      radius: 18,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(
          isFav ? Icons.star : Icons.star_border,
          color: isFav ? Colors.red : Colors.grey,
        ),
        onPressed: _toggleFav,
      ),
    );
  }
}