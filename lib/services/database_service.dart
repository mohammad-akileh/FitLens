// lib/services/database_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart'; // Ensure you have intl package

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ==============================================================================
  // 1. 🕛 THE MIDNIGHT RESET (Run this when App Opens)
  // ==============================================================================
  Future<void> checkAndResetDailyStats(String uid) async {
    final userRef = _db.collection('users').doc(uid);
    final userDoc = await userRef.get();

    if (!userDoc.exists) return;

    final data = userDoc.data()!;
    // Get the last date the app was active (or default to today if missing)
    String lastActiveDate = data['last_active_date'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // 🚨 IF IT IS A NEW DAY:
    if (lastActiveDate != todayDate) {
      print("🕛 MIDNIGHT DETECTED! Archiving yesterday's data...");

      // 1. Archive the OLD data to 'history' collection
      await userRef.collection('history').doc(lastActiveDate).set({
        'date': lastActiveDate,
        'calories': data['current_calories'] ?? 0,
        'protein': data['current_protein'] ?? 0,
        'carbs': data['current_carbs'] ?? 0,
        'fat': data['current_fat'] ?? 0,
        'water': data['current_water'] ?? 0,
        // Save targets too, in case they change later!
        'target_calories': data['target_calories'] ?? 2000,
        'target_protein': data['target_protein'] ?? 150,
        'target_carbs': data['target_carbs'] ?? 250,
        'target_fat': data['target_fat'] ?? 65,
        'target_water': data['target_water'] ?? 2500,
      });

      // 2. Reset the MAIN User Document to 0
      await userRef.update({
        'current_calories': 0,
        'current_protein': 0,
        'current_carbs': 0,
        'current_fat': 0,
        'current_water': 0,
        'last_active_date': todayDate, // ✅ Set today as the new active date
      });

      print("✅ Daily stats reset for $todayDate");
    } else {
      print("📅 Same day. No reset needed.");
    }
  }

  // ==============================================================================
  // 2. 🕰️ GET HISTORY FOR A SPECIFIC DATE
  // ==============================================================================
  Future<Map<String, dynamic>?> getHistoryForDate(String uid, DateTime date) async {
    String dateStr = DateFormat('yyyy-MM-dd').format(date);

    // 1. Check if it's "Today" (Return null so UI uses Live Stream)
    String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (dateStr == todayStr) return null;

    // 2. Fetch Archived Data
    final doc = await _db.collection('users').doc(uid).collection('history').doc(dateStr).get();

    if (doc.exists) {
      return doc.data();
    } else {
      // No history for this day (User didn't log in?)
      return {
        'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0, 'water': 0,
        'target_calories': 2000, // defaults
      };
    }
  }

  // ==============================================================================
  // 3. 📸 GET MEALS FOR A SPECIFIC DATE (For the History Pictures)
  // ==============================================================================
  Stream<List<Map<String, dynamic>>> getMealsForDate(String uid, DateTime date) {
    // Create Start/End timestamps for the query
    DateTime start = DateTime(date.year, date.month, date.day, 0, 0, 0);
    DateTime end = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _db.collection('users').doc(uid).collection('meals')
        .where('timestamp', isGreaterThanOrEqualTo: start)
        .where('timestamp', isLessThanOrEqualTo: end)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // ... (Keep your existing saveUserProfile, saveMeal, uploadImage functions here EXACTLY as they were) ...
  // [PASTE THE REST OF YOUR EXISTING FUNCTIONS FROM ALL3.TXT HERE]
  Future<void> saveUserProfile({
    required String uid,
    String? gender,
    int? age,
    double? weight,
    String? weightUnit,
    double? height,
    String? heightUnit,
    String? goal,
    String? mealFrequency,
    String? snackHabit,
    String? weekendHabit,
    String? activityLevel,
    String? dietType,
    double? weeklyExerciseHours,
    Map<String, int>? dailyGoals,
  }) async {
    try {
      Map<String, dynamic> userData = {
        'onboarding_completed': true,
        'app_secret': 'FitLens_VIP_2025',
      };

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

      if (dailyGoals != null) {
        userData['target_calories'] = dailyGoals['calories'];
        userData['target_protein'] = dailyGoals['protein'];
        userData['target_carbs'] = dailyGoals['carb'];
        userData['target_fat'] = dailyGoals['fat'];
        userData['target_water'] = dailyGoals['water'];
      }

      // Initialize counters if they don't exist (important for the reset logic!)
      // We use merge so we don't overwrite existing progress if this is called later
      userData['last_active_date'] = DateFormat('yyyy-MM-dd').format(DateTime.now());

      await _db.collection('users').doc(uid).set(userData, SetOptions(merge: true));

    } catch (e) {
      print("Error updating user profile: $e");
      throw Exception("Could not save profile.");
    }
  }

  Future<void> saveMeal({
    required String uid,
    required List<dynamic> foodItems,
    String? imageUrl,
    required String mealType,
  }) async {
    try {
      double mealCals = 0;
      double mealProt = 0;
      double mealCarbs = 0;
      double mealFat = 0;

      for (var item in foodItems) {
        double serving = (item['user_serving_count'] ?? 1).toDouble();
        mealCals += (item['calories_per_serving'] ?? 0) * serving;
        mealProt += (item['protein_per_serving'] ?? 0) * serving;
        mealCarbs += (item['carbs_per_serving'] ?? 0) * serving;
        mealFat += (item['fat_per_serving'] ?? 0) * serving;
      }

      Map<String, dynamic> mealData = {
        'food_items': foodItems,
        'image_url': imageUrl ?? "",
        'meal_type': mealType,
        'timestamp': FieldValue.serverTimestamp(),
        'total_calories': mealCals,
        'total_protein': mealProt,
        'total_carbs': mealCarbs,
        'total_fat': mealFat,
        'app_secret': 'FitLens_VIP_2025',
      };

      WriteBatch batch = _db.batch();
      DocumentReference mealRef = _db.collection('users').doc(uid).collection('meals').doc();
      batch.set(mealRef, mealData);

      DocumentReference userRef = _db.collection('users').doc(uid);

      batch.update(userRef, {
        'current_calories': FieldValue.increment(mealCals),
        'current_protein': FieldValue.increment(mealProt),
        'current_carbs': FieldValue.increment(mealCarbs),
        'current_fat': FieldValue.increment(mealFat),
        'app_secret': 'FitLens_VIP_2025',
        // Update active date on save just to be sure
        'last_active_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      });

      await batch.commit();

    } catch (e) {
      print("Error saving meal: $e");
      throw e;
    }
  }

  Future<String> uploadImage(File imageFile) async {
    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
      String fileName = 'meals/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = _storage.ref().child(fileName);

      SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'app_secret': 'FitLens_VIP_2025'},
      );

      UploadTask task = ref.putFile(imageFile, metadata);
      TaskSnapshot snapshot = await task;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      return "";
    }
  }
}