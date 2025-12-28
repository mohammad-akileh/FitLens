// lib/services/database_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ==============================================================================
  // 1. 🕛 THE MIDNIGHT RESET (The Logic)
  // ==============================================================================
  Future<void> checkAndResetDailyStats(String uid) async {
    final userRef = _db.collection('users').doc(uid);
    final userDoc = await userRef.get();

    if (!userDoc.exists) return;

    final data = userDoc.data()!;
    String lastActiveDate = data['last_active_date'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // 🚨 IF IT IS A NEW DAY:
    if (lastActiveDate != todayDate) {
      print("🕛 MIDNIGHT DETECTED! Archiving yesterday's data...");

      // 1. Archive the OLD data to 'history' collection (The File Cabinet)
      // We explicitly save targets here so we know what the goal was ON THAT DAY
      await userRef.collection('history').doc(lastActiveDate).set({
        'date': lastActiveDate,
        'calories': data['current_calories'] ?? 0,
        'protein': data['current_protein'] ?? 0,
        'carbs': data['current_carbs'] ?? 0,
        'fat': data['current_fat'] ?? 0,
        'water': data['current_water'] ?? 0,
        'target_calories': data['target_calories'] ?? 2000,
        'target_protein': data['target_protein'] ?? 150,
        'target_carbs': data['target_carbs'] ?? 250,
        'target_fat': data['target_fat'] ?? 65,
        'target_water': data['target_water'] ?? 2500,
        'app_secret': 'FitLens_VIP_2025', // 👈 ADDED!
      });

      // 2. Reset the MAIN User Document to 0 (Wipe the Desk)
      await userRef.update({
        'current_calories': 0,
        'current_protein': 0,
        'current_carbs': 0,
        'current_fat': 0,
        'current_water': 0,
        'last_active_date': todayDate, // ✅ Set today as the new active date
        'app_secret': 'FitLens_VIP_2025', // 👈 ADDED!
      });

      print("✅ Daily stats reset for $todayDate");
    }
  }

  // ==============================================================================
  // 2. 💾 SAVE USER PROFILE (The Organizer)
  // This function enforces the "Clean Structure" you asked for.
  // ==============================================================================
  Future<void> saveUserProfile({
    required String uid,
    String? name,
    String? email,
    String? gender,
    int? age,
    double? weight,
    String? weightUnit,
    double? height,
    String? heightUnit,
    String? goal,
    String? activityLevel,
    String? dietType,
    double? weeklyExerciseHours,
    Map<String, int>? dailyGoals,
  }) async {
    try {
      // Base Data Structure
      Map<String, dynamic> userData = {
        'onboarding_completed': true,
        'last_active_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'app_secret': 'FitLens_VIP_2025',
      };

      // Optional Fields (Only add if they are not null)
      if (name != null) userData['name'] = name;
      if (email != null) userData['email'] = email;
      if (gender != null) userData['gender'] = gender;
      if (age != null) userData['age'] = age;
      if (weight != null) userData['weight'] = weight;
      if (weightUnit != null) userData['weight_unit'] = weightUnit;
      if (height != null) userData['height'] = height;
      if (heightUnit != null) userData['height_unit'] = heightUnit;

      if (goal != null) userData['goal'] = goal;
      if (activityLevel != null) userData['activity_level'] = activityLevel;
      if (dietType != null) userData['diet_type'] = dietType;
      if (weeklyExerciseHours != null) userData['weekly_exercise_hours'] = weeklyExerciseHours;

      // Targets (If provided, otherwise defaults will be handled by UI)
      if (dailyGoals != null) {
        userData['target_calories'] = dailyGoals['calories'];
        userData['target_protein'] = dailyGoals['protein'];
        userData['target_carbs'] = dailyGoals['carb'];
        userData['target_fat'] = dailyGoals['fat'];
        userData['target_water'] = dailyGoals['water'];
      }

      // 🛡️ INITIALIZE COUNTERS IF MISSING
      // We use SetOptions(merge: true) so we don't erase existing progress
      // But we ensure these fields exist so your DB looks clean!
      final userDoc = await _db.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        userData['current_calories'] = 0;
        userData['current_protein'] = 0;
        userData['current_carbs'] = 0;
        userData['current_fat'] = 0;
        userData['current_water'] = 0;
      }

      await _db.collection('users').doc(uid).set(userData, SetOptions(merge: true));

    } catch (e) {
      print("Error updating user profile: $e");
      throw Exception("Could not save profile.");
    }
  }

  // ==============================================================================
  // 3. 🍱 SAVE MEAL (The Receipt Logic)
  // ==============================================================================
  Future<void> saveMeal({
    required String uid,
    required List<dynamic> foodItems,
    String? imageUrl,
    required String mealType,
  }) async {
    try {
      // 🛡️ SAFETY: Check reset before saving to avoid mixing days
      await checkAndResetDailyStats(uid);

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

      // The Meal Document (Goes into 'meals' subcollection)
      Map<String, dynamic> mealData = {
        'meal_type': mealType,
        'timestamp': FieldValue.serverTimestamp(),
        'food_items': foodItems,
        'total_calories': mealCals,
        'total_protein': mealProt,
        'total_carbs': mealCarbs,
        'total_fat': mealFat,
        'image_url': imageUrl ?? "",
        'app_secret': 'FitLens_VIP_2025',
      };

      WriteBatch batch = _db.batch();

      // 1. Save to Meals Subcollection
      DocumentReference mealRef = _db.collection('users').doc(uid).collection('meals').doc();
      batch.set(mealRef, mealData);

      // 2. Update the Dashboard (Main User Doc)
      DocumentReference userRef = _db.collection('users').doc(uid);
      batch.update(userRef, {
        'current_calories': FieldValue.increment(mealCals),
        'current_protein': FieldValue.increment(mealProt),
        'current_carbs': FieldValue.increment(mealCarbs),
        'current_fat': FieldValue.increment(mealFat),
        'last_active_date': DateFormat('yyyy-MM-dd').format(DateTime.now()), // Ensure date is today
        'app_secret': 'FitLens_VIP_2025', // 👈 ADDED!
      });

      await batch.commit();

    } catch (e) {
      print("Error saving meal: $e");
      throw e;
    }
  }

  // ==============================================================================
  // 4. 📸 GETTERS (For History & Home)
  // ==============================================================================

  // Get History for a specific date (From 'history' subcollection)
  Future<Map<String, dynamic>?> getHistoryForDate(String uid, DateTime date) async {
    String dateStr = DateFormat('yyyy-MM-dd').format(date);
    String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // If asking for TODAY, return null so the UI uses the live stream
    if (dateStr == todayStr) return null;

    final doc = await _db.collection('users').doc(uid).collection('history').doc(dateStr).get();

    if (doc.exists) {
      return doc.data();
    } else {
      return {
        'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0, 'water': 0,
        'target_calories': 2000,
      };
    }
  }

  // Get Meal List for a specific date (From 'meals' subcollection)
  Stream<List<Map<String, dynamic>>> getMealsForDate(String uid, DateTime date) {
    DateTime start = DateTime(date.year, date.month, date.day, 0, 0, 0);
    DateTime end = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _db.collection('users').doc(uid).collection('meals')
        .where('timestamp', isGreaterThanOrEqualTo: start)
        .where('timestamp', isLessThanOrEqualTo: end)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<String> uploadImage(File imageFile) async {
    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
      String fileName = 'meals/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = _storage.ref().child(fileName);
      SettableMetadata metadata = SettableMetadata(contentType: 'image/jpeg', customMetadata: {'app_secret': 'FitLens_VIP_2025'});
      UploadTask task = ref.putFile(imageFile, metadata);
      TaskSnapshot snapshot = await task;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      return "";
    }
  }
}