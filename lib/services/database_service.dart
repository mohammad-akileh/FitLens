// lib/services/database_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 1. Midnight Reset Logic
  Future<void> checkAndResetDailyStats(String uid) async {
    final userRef = _db.collection('users').doc(uid);
    final userDoc = await userRef.get();

    if (!userDoc.exists) return;

    final data = userDoc.data()!;
    String lastActiveDate = data['last_active_date'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (lastActiveDate != todayDate) {
      print("🕛 MIDNIGHT DETECTED! Archiving yesterday's data...");
      await userRef.collection('history').doc(lastActiveDate).set({
        'date': lastActiveDate,
        'calories': data['current_calories'] ?? 0,
        'protein': data['current_protein'] ?? 0,
        'carbs': data['current_carbs'] ?? 0,
        'fat': data['current_fat'] ?? 0,
        'water': data['current_water'] ?? 0,
        'target_calories': data['target_calories'] ?? 2000,
        'app_secret': 'FitLens_VIP_2025',
      });

      await userRef.update({
        'current_calories': 0,
        'current_protein': 0,
        'current_carbs': 0,
        'current_fat': 0,
        'current_water': 0,
        'last_active_date': todayDate,
        'app_secret': 'FitLens_VIP_2025',
      });
    }
  }

  // 2. Save User Profile
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
      Map<String, dynamic> userData = {
        'onboarding_completed': true,
        'last_active_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'app_secret': 'FitLens_VIP_2025',
      };

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

      if (dailyGoals != null) {
        userData['target_calories'] = dailyGoals['calories'];
        userData['target_protein'] = dailyGoals['protein'];
        userData['target_carbs'] = dailyGoals['carb'];
        userData['target_fat'] = dailyGoals['fat'];
        userData['target_water'] = dailyGoals['water'];
      }

      await _db.collection('users').doc(uid).set(userData, SetOptions(merge: true));
    } catch (e) {
      print("Error updating user profile: $e");
      throw Exception("Could not save profile.");
    }
  }

  // 3. Save Meal
  Future<void> saveMeal({
    required String uid,
    required List<dynamic> foodItems,
    String? imageUrl,
    required String mealType,
  }) async {
    try {
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
      DocumentReference mealRef = _db.collection('users').doc(uid).collection('meals').doc();
      batch.set(mealRef, mealData);

      DocumentReference userRef = _db.collection('users').doc(uid);
      batch.update(userRef, {
        'current_calories': FieldValue.increment(mealCals),
        'current_protein': FieldValue.increment(mealProt),
        'current_carbs': FieldValue.increment(mealCarbs),
        'current_fat': FieldValue.increment(mealFat),
        'last_active_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'app_secret': 'FitLens_VIP_2025',
      });

      await batch.commit();
    } catch (e) {
      print("Error saving meal: $e");
      throw e;
    }
  }

  // --- 4. 🔴 ADDED MISSING FUNCTION: UPDATE WATER INTAKE ---
  Future<void> updateWaterIntake(String uid, int glasses) async {
    try {
      // Assuming 1 glass = 250ml
      // If you are passing total ML, remove the * 250
      await _db.collection('users').doc(uid).update({
        'current_water': glasses * 250, // Save as ML
      });
    } catch (e) {
      // If doc doesn't exist, create it (Safety)
      await _db.collection('users').doc(uid).set({
        'current_water': glasses * 250,
      }, SetOptions(merge: true));
    }
  }

  Future<Map<String, dynamic>?> getHistoryForDate(String uid, DateTime date) async {
    String dateStr = DateFormat('yyyy-MM-dd').format(date);
    String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (dateStr == todayStr) return null;
    final doc = await _db.collection('users').doc(uid).collection('history').doc(dateStr).get();
    if (doc.exists) {
      return doc.data();
    } else {
      return {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0, 'water': 0, 'target_calories': 2000};
    }
  }

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