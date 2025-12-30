import 'package:flutter/material.dart';
import '../services/favorites_service.dart';
import '../services/recipe_service.dart'; // Import Recipe model
import 'recipe_detail_screen.dart'; // Import Detail screen

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FavoritesService favService = FavoritesService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Favorites ❤️", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<List<Recipe>>(
        stream: favService.getFavoritesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("No favorites yet!", style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          final favorites = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final recipe = favorites[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(recipe.imageUrl, width: 60, height: 60, fit: BoxFit.cover),
                  ),
                  title: Text(recipe.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${recipe.calories} kcal • ${recipe.protein}g Protein"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => favService.removeFavorite(recipe.title),
                  ),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (c) => RecipeDetailScreen(recipe: recipe)));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}