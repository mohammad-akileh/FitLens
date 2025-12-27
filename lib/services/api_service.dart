// lib/services/api_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  final String _scanUrl = "https://generate-meal-data-xynwa4baqa-uc.a.run.app";
  final String _correctUrl = "https://correct-meal-item-xynwa4baqa-uc.a.run.app";
  final String _secretKey = "FitLens_VIP_2025";

  // --- 1. SCAN ---
  Future<String> analyzeImage(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(_scanUrl));
      String? token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.headers['X-App-Secret'] = _secretKey;
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Failed to connect to AI: $e");
    }
  }

  // --- 2. CORRECT (THE GREEDY FIX) ---
  Future<Map<String, dynamic>> correctScan(File? imageFile, String wrongItem, String userCorrection) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(_correctUrl));
      String? token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.headers['X-App-Secret'] = _secretKey;

      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      }

      request.fields['wrong_item'] = wrongItem;
      request.fields['correction'] = userCorrection;

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var decoded = jsonDecode(response.body);
        print("📥 AI RAW RESPONSE: $decoded"); // Look at logs if it fails again!

        // 🧠 GREEDY PARSER: It checks EVERY possible name for the value
        return {
          "food_name": decoded['food_name'] ?? decoded['item'] ?? userCorrection,
          "serving_unit": decoded['serving_unit'] ?? decoded['unit'] ?? "1 serving",

          // Helper function checks "calories", "Calories", "kcal", etc.
          "calories_per_serving": _getNum(decoded, ['calories_per_serving', 'calories', 'kcal', 'cal']),
          "protein_per_serving": _getNum(decoded, ['protein_per_serving', 'protein', 'prot', 'p']),
          "carbs_per_serving": _getNum(decoded, ['carbs_per_serving', 'carbs', 'carb', 'c']),
          "fat_per_serving": _getNum(decoded, ['fat_per_serving', 'fat', 'f']),
        };
      } else {
        throw Exception("Correction Error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Failed to correct item: $e");
    }
  }

  // 🧹 Helper to find numbers in messy JSON
  // 🧹 Robust Helper to find numbers
  num _getNum(Map<String, dynamic> data, List<String> keys) {
    for (String key in keys) {
      if (data.containsKey(key) && data[key] != null) {
        var value = data[key];
        // Handle String numbers (e.g., "15.5")
        if (value is String) {
          return num.tryParse(value) ?? 0;
        }
        // Handle actual numbers
        if (value is num) {
          return value;
        }
      }
    }
    return 0;
  }
}