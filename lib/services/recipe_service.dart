import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// 1. The Recipe Model (Now with ToJson/FromJson for saving!)
class Recipe {
  final String title;
  final String imageUrl;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final String sourceUrl;
  final List<String> ingredients;

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

  // Convert to Map (for saving to phone)
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

  // Create from Map (loading from phone)
  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      title: json['label'] ?? "Unknown Meal",
      imageUrl: json['image'] ?? "https://via.placeholder.com/150",
      calories: (json['calories'] as num).toInt(),
      protein: (json['protein'] as num?)?.toInt() ?? 0,
      carbs: (json['carbs'] as num?)?.toInt() ?? 0,
      fat: (json['fat'] as num?)?.toInt() ?? 0,
      sourceUrl: json['url'] ?? "",
      ingredients: List<String>.from(json['ingredientLines'] ?? []),
    );
  }

  // Create from API (Edamam format is slightly different)
  factory Recipe.fromEdamam(Map<String, dynamic> json) {
    final nutrients = json['totalNutrients'];
    return Recipe(
      title: json['label'] ?? "Unknown Meal",
      imageUrl: json['image'] ?? "https://via.placeholder.com/150",
      calories: (json['calories'] as num).toInt(),
      protein: (nutrients['PROCNT']?['quantity'] as num? ?? 0).toInt(),
      fat: (nutrients['FAT']?['quantity'] as num? ?? 0).toInt(),
      carbs: (nutrients['CHOCDF']?['quantity'] as num? ?? 0).toInt(),
      sourceUrl: json['url'] ?? "",
      ingredients: List<String>.from(json['ingredientLines'] ?? []),
    );
  }
}

class RecipeService {
  // 🔑 YOUR KEYS FROM THE SCREENSHOT
  static const String _appId = "538a4d05";
  static const String _appKey = "d95387336370474ae20c002554dce446";
  static const String _baseUrl = "https://api.edamam.com/search";

  // 🦅 THE SMART LOGIC
  static Future<List<Recipe>> getSmartRecommendations(int targetCalories) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Check if we already have recipes for THIS calorie target
    int? cachedTarget = prefs.getInt('cached_target_calories');
    String? cachedData = prefs.getString('cached_recipes');

    // Logic: If target hasn't changed much (within 50kcal) AND we have data -> USE CACHE
    if (cachedData != null && cachedTarget != null) {
      if ((targetCalories - cachedTarget).abs() < 50) {
        print("💾 Loading from Cache (Zero API Hits)");
        List<dynamic> decoded = json.decode(cachedData);
        return decoded.map((e) => Recipe.fromJson(e)).toList();
      }
    }

    // 2. If Cache is invalid, HIT THE API 🌍
    return _fetchFromApi(targetCalories, prefs);
  }

  static Future<List<Recipe>> _fetchFromApi(int target, SharedPreferences prefs) async {
    // Safety buffer
    int safeTarget = target < 300 ? 500 : target;

    try {
      final url = Uri.parse(
          "$_baseUrl?q=healthy&app_id=$_appId&app_key=$_appKey&to=20&calories=0-$safeTarget"
      );

      print("🦅 Calling Edamam API (1 Hit used)...");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List hits = data['hits'];

        if (hits.isEmpty) return _backupRecipes;

        List<Recipe> recipes = hits.map((hit) => Recipe.fromEdamam(hit['recipe'])).toList();

        // 💾 SAVE TO CACHE
        String encoded = json.encode(recipes.map((r) => r.toJson()).toList());
        await prefs.setString('cached_recipes', encoded);
        await prefs.setInt('cached_target_calories', target); // Remember this target

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

  // 🛡️ BACKUP LIST (Safety Net)
  static final List<Recipe> _backupRecipes = [
    Recipe(
      title: "Classic Hummus Plate",
      imageUrl: "https://i.postimg.cc/c1cJzyvq/project.jpg",
      calories: 400, protein: 12, carbs: 45, fat: 20,
      sourceUrl: "", ingredients: ["Chickpeas", "Tahini", "Lemon", "Olive Oil"],
    ),
    Recipe(
      title: "Grilled Shish Tawook",
      imageUrl: "https://i.postimg.cc/T2cPsMKx/project2.jpg",
      calories: 450, protein: 45, carbs: 5, fat: 25,
      sourceUrl: "", ingredients: ["Chicken Breast", "Yogurt", "Garlic", "Lemon"],
    ),
    Recipe(
      title: "Tabouleh Salad",
      imageUrl: "https://i.postimg.cc/ry9pHXDk/project3.jpg",
      calories: 220, protein: 5, carbs: 20, fat: 15,
      sourceUrl: "", ingredients: ["Parsley", "Bulgur", "Tomatoes", "Olive Oil"],
    ),
  ];
}