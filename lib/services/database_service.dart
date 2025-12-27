// lib/services/database_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ==============================================================================
  // 1. SAVE USER PROFILE (Onboarding + Settings Updates)
  // ==============================================================================
  Future<void> saveUserProfile({
    required String uid,
    // Basic Info
    String? gender,
    int? age,
    double? weight,
    String? weightUnit,
    double? height,
    String? heightUnit,
    // Habits & Preferences
    String? goal,
    String? mealFrequency,
    String? snackHabit,
    String? weekendHabit,
    String? activityLevel,
    String? dietType, // 🥗 Added for DietaryScreen
    double? weeklyExerciseHours, // 🏃 Added for HabitsScreen
    // Calculated Targets
    Map<String, int>? dailyGoals,
  }) async {
    try {
      Map<String, dynamic> userData = {
        'onboarding_completed': true,
        'app_secret': 'FitLens_VIP_2025', // 🔒 Security Key
      };

      // Only add fields if they are not null (allows partial updates)
      if (gender != null) userData['gender'] = gender;
      if (age != null) userData['age'] = age;
      if (weight != null) userData['weight'] = weight;
      if (weightUnit != null) userData['weight_unit'] = weightUnit;
      if (height != null) userData['height'] = height;
      if (heightUnit != null) userData['height_unit'] = heightUnit;

      if (goal != null) userData['goal'] = goal;
      if (mealFrequency != null) userData['meal_frequency'] = mealFrequency;
      if (snackHabit != null) userData['snack_habit'] = snackHabit;
      if (weekendHabit != null) userData['weekend_habit'] = weekendHabit;
      if (activityLevel != null) userData['activity_level'] = activityLevel;

      if (dietType != null) userData['diet_type'] = dietType;
      if (weeklyExerciseHours != null) userData['weekly_exercise_hours'] = weeklyExerciseHours;

      // Update Targets if provided
      if (dailyGoals != null) {
        userData['target_calories'] = dailyGoals['calories'];
        userData['target_protein'] = dailyGoals['protein'];
        userData['target_carbs'] = dailyGoals['carb']; // or 'carbs'
        userData['target_fat'] = dailyGoals['fat'];
        userData['target_water'] = dailyGoals['water'];
      }

      // Use SetOptions(merge: true) so we don't delete existing data
      await _db.collection('users').doc(uid).set(userData, SetOptions(merge: true));
      print("User Profile Saved/Updated! ✅");

    } catch (e) {
      print("Error updating user profile: $e");
      throw Exception("Could not save profile.");
    }
  }

  // ==============================================================================
  // 2. SAVE MEAL (Handles Scan & History + Updates Home Bar)
  // ==============================================================================
  Future<void> saveMeal({
    required String uid,
    required List<dynamic> foodItems,
    String? imageUrl,
    required String mealType, // e.g. "Breakfast" or "Scanned Meal"
  }) async {
    try {
      // 1. Calculate the totals for this specific meal
      double mealCals = 0;
      double mealProt = 0;
      double mealCarbs = 0;
      double mealFat = 0;

      for (var item in foodItems) {
        // 🧠 CRITICAL LOGIC:
        // We look for 'user_serving_count' (from the +/- buttons).
        // If missing, default to 1.
        double serving = (item['user_serving_count'] ?? 1).toDouble();

        mealCals += (item['calories_per_serving'] ?? 0) * serving;
        mealProt += (item['protein_per_serving'] ?? 0) * serving;
        mealCarbs += (item['carbs_per_serving'] ?? 0) * serving;
        mealFat += (item['fat_per_serving'] ?? 0) * serving;
      }

      // 2. Prepare the Meal Document Data
      Map<String, dynamic> mealData = {
        'food_items': foodItems, // This includes the 'user_serving_count' inside it
        'image_url': imageUrl ?? "",
        'meal_type': mealType,
        'timestamp': FieldValue.serverTimestamp(),
        // Save the calculated totals for this meal history card
        'total_calories': mealCals,
        'total_protein': mealProt,
        'total_carbs': mealCarbs,
        'total_fat': mealFat,
        'app_secret': 'FitLens_VIP_2025',
      };

      // 3. ⚡ BATCH WRITE (Updates Meal History AND Daily Progress together)
      WriteBatch batch = _db.batch();

      // A. Add to 'meals' subcollection
      DocumentReference mealRef = _db.collection('users').doc(uid).collection('meals').doc();
      batch.set(mealRef, mealData);

      // B. Increment 'users' document (This makes the Home Screen Bar jump!)
      DocumentReference userRef = _db.collection('users').doc(uid);

      batch.update(userRef, {
        'current_calories': FieldValue.increment(mealCals),
        'current_protein': FieldValue.increment(mealProt),
        'current_carbs': FieldValue.increment(mealCarbs),
        'current_fat': FieldValue.increment(mealFat),
        'app_secret': 'FitLens_VIP_2025',
      });

      // 4. Commit (Fire!)
      await batch.commit();

      print("Meal Saved & Daily Progress Updated! 📈");

    } catch (e) {
      print("Error saving meal: $e");
      throw e;
    }
  }

  // ==============================================================================
  // 3. UPLOAD IMAGE (With Security Metadata)
  // ==============================================================================
  Future<String> uploadImage(File imageFile) async {
    try {
      // Create a unique filename based on time
      String fileName = 'meals/${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Get a reference to storage
      Reference ref = _storage.ref().child(fileName);

      // 🔐 ADD THE PASSWORD METADATA
      SettableMetadata metadata = SettableMetadata(
          customMetadata: {'app_secret': 'FitLens_VIP_2025'}
      );

      // Upload
      UploadTask task = ref.putFile(imageFile, metadata);
      TaskSnapshot snapshot = await task;

      // Get the permanent URL
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading image: $e");
      return ""; // Return empty string if failed (don't crash app)
    }
  }
}