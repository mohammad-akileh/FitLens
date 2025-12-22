// lib/services/database_service.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

// 1. UPDATE: Save User Profile with TARGETS
  Future<void> saveUserProfile({
    required String uid,
    required String gender,
    required int age,
    required double weight,
    required String weightUnit,
    required double height,
    required String heightUnit,
    String? goal,
    String? mealFrequency,
    String? snackHabit,
    String? weekendHabit,
    String? activityLevel,
    Map<String, int>? dailyGoals,
  }) async {
    try {
      Map<String, dynamic> userData = {
        'gender': gender,
        'age': age,
        'weight': weight,
        'weight_unit': weightUnit,
        'height': height,
        'height_unit': heightUnit,
        'goal': goal,
        'meal_frequency': mealFrequency,
        'snack_habit': snackHabit,
        'weekend_habit': weekendHabit,
        'activity_level': activityLevel,
        'onboarding_completed': true,

        // Target Calories
        'target_calories': dailyGoals?['calories'] ?? 2000,
        'target_protein': dailyGoals?['protein'] ?? 150,
        'target_carbs': dailyGoals?['carb'] ?? 250, // Careful: key might be 'carb' or 'carbs' in your map
        'target_fat': dailyGoals?['fat'] ?? 65,
        'target_water': dailyGoals?['water'] ?? 2500,

        // 🔐 THE MISSING KEY! ADD THIS LINE:
        'app_secret': 'FitLens_VIP_2025',
      };

      // Use SetOptions(merge: true) so we don't delete other fields
      await _db.collection('users').doc(uid).set(userData, SetOptions(merge: true));
    } catch (e) {
      print("Error updating user profile: $e");
      throw Exception("Could not save profile.");
    }
  }

  // 2. UPDATE: Save Meal with MACRO TOTALS
// ... inside DatabaseService ...

  Future<void> saveMeal({
    required String uid,
    required List<dynamic> foodItems,
    String? imageUrl,
  }) async {
    try {
      DocumentReference docRef = _db.collection('users').doc(uid).collection('meals').doc();

      // Calculate totals... (keep your existing math logic here)
      double totalCals = 0;
      double totalProt = 0;
      double totalCarbs = 0;
      double totalFat = 0;

      for (var item in foodItems) {
        double serving = (item['user_serving'] ?? 1.0).toDouble();
        totalCals += (item['calories_per_serving'] ?? 0) * serving;
        totalProt += (item['protein_per_serving'] ?? 0) * serving;
        totalCarbs += (item['carbs_per_serving'] ?? 0) * serving;
        totalFat += (item['fat_per_serving'] ?? 0) * serving;
      }

      await docRef.set({
        'food_items': foodItems,
        'image_url': imageUrl ?? "",
        'timestamp': FieldValue.serverTimestamp(),
        'total_calories': totalCals,
        'total_protein': totalProt,
        'total_carbs': totalCarbs,
        'total_fat': totalFat,

        // 🔒 THE DATABASE KEY (Add this line!)
        'app_secret': 'FitLens_VIP_2025',
      });
    } catch (e) {
      print("Error saving meal: $e");
      throw e;
    }
  }
  Future<String> uploadImage(File imageFile) async {
    try {
      // Create a unique filename based on time
      String fileName = 'meals/${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Get a reference to storage
      Reference ref = FirebaseStorage.instance.ref().child(fileName);
      SettableMetadata metadata = SettableMetadata(
          customMetadata: {'app_secret': 'FitLens_VIP_2025'}
      );

      // Upload
      UploadTask task = ref.putFile(imageFile);
      TaskSnapshot snapshot = await task;

      // Get the permanent URL
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading image: $e");
      return ""; // Return empty string if failed
    }
  }
}