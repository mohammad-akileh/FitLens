import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../keys.dart'; // Ensure this file exists as we discussed!

class Recipe {
  final String title;
  final String imageUrl;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final String sourceUrl;
  final List<String> ingredients;

  // 🛡️ SHARED BACKUP IMAGE
  static const String fallbackImage = "https://i.postimg.cc/T2cPsMKx/project2.jpg";

  Recipe({
    required this.title,
    required this.imageUrl,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.sourceUrl,
    required this.ingredients,
  });

  Map<String, dynamic> toJson() => {
    'label': title,
    'image': imageUrl,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'url': sourceUrl,
    'ingredientLines': ingredients,
  };

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      title: json['label'] ?? "Unknown Meal",
      imageUrl: json['image'] ?? fallbackImage,
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      protein: (json['protein'] as num?)?.toInt() ?? 0,
      carbs: (json['carbs'] as num?)?.toInt() ?? 0,
      fat: (json['fat'] as num?)?.toInt() ?? 0,
      sourceUrl: json['url'] ?? "",
      ingredients: List<String>.from(json['ingredientLines'] ?? []),
    );
  }

  factory Recipe.fromEdamam(Map<String, dynamic> json) {
    final nutrients = json['totalNutrients'] ?? {};

    // 🔴 THE FIX: FORCE HTTPS 🔴
    // Edamam sends 'http', which Android blocks. We change it to 'https'.
    String imgUrl = json['image'] ?? fallbackImage;
    if (imgUrl.startsWith("http://")) {
      imgUrl = imgUrl.replaceFirst("http://", "https://");
    }

    return Recipe(
      title: json['label'] ?? "Unknown Meal",
      imageUrl: imgUrl, // ✅ Use the secure URL
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      protein: (nutrients['PROCNT']?['quantity'] as num? ?? 0).toInt(),
      fat: (nutrients['FAT']?['quantity'] as num? ?? 0).toInt(),
      carbs: (nutrients['CHOCDF']?['quantity'] as num? ?? 0).toInt(),
      sourceUrl: json['url'] ?? "",
      ingredients: List<String>.from(json['ingredientLines'] ?? []),
    );
  }
}

class RecipeService {
  // Uses keys from your keys.dart file
  static final String _appId = RecipeKeys.appId;
  static const String _appKey = RecipeKeys.appKey;
  static const String _baseUrl = "https://api.edamam.com/api/recipes/v2";

  static Future<List<Recipe>> getSmartRecommendations(int targetCalories) async {
    final prefs = await SharedPreferences.getInstance();

    int? cachedTarget = prefs.getInt('cached_target_calories');
    String? cachedData = prefs.getString('cached_recipes');

    // Cache Logic
    if (cachedData != null && cachedTarget != null) {
      if ((targetCalories - cachedTarget).abs() < 50) {
        print("💾 Loading from Cache");
        List<dynamic> decoded = json.decode(cachedData);
        return decoded.map((e) => Recipe.fromJson(e)).toList();
      }
    }

    return _fetchFromApi(targetCalories, prefs);
  }

  static Future<List<Recipe>> _fetchFromApi(int target, SharedPreferences prefs) async {
    int safeTarget = target < 300 ? 500 : target;

    try {
      final url = Uri.parse(
          "$_baseUrl?type=public&q=healthy&app_id=$_appId&app_key=$_appKey&calories=0-$safeTarget&to=80&random=true"
      );

      print("🦅 Calling Edamam API...");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List hits = data['hits'];

        if (hits.isEmpty) return _backupRecipes;

        List<Recipe> recipes = hits.map((hit) => Recipe.fromEdamam(hit['recipe'])).toList();

        // Save Cache
        String encoded = json.encode(recipes.map((r) => r.toJson()).toList());
        await prefs.setString('cached_recipes', encoded);
        await prefs.setInt('cached_target_calories', target);

        return recipes;
      } else {
        print("⚠️ API Error: ${response.statusCode}");
        return _backupRecipes;
      }
    } catch (e) {
      print("🛑 Network Error: $e");
      return _backupRecipes;
    }
  }

  // 🛡️ BACKUP RECIPES
  static final List<Recipe> _backupRecipes = [
    Recipe(
      title: "Classic Hummus Plate",
      imageUrl: Recipe.fallbackImage,
      calories: 400, protein: 12, carbs: 45, fat: 20,
      sourceUrl: "", ingredients: ["Chickpeas", "Tahini", "Lemon", "Olive Oil"],
    ),
    Recipe(
      title: "Grilled Shish Tawook",
      imageUrl: Recipe.fallbackImage,
      calories: 450, protein: 45, carbs: 5, fat: 25,
      sourceUrl: "", ingredients: ["Chicken Breast", "Yogurt", "Garlic", "Lemon"],
    ),
    Recipe(
      title: "Tabouleh Salad",
      imageUrl: Recipe.fallbackImage,
      calories: 220, protein: 5, carbs: 20, fat: 15,
      sourceUrl: "", ingredients: ["Parsley", "Bulgur", "Tomatoes", "Olive Oil"],
    ),
  ];
}