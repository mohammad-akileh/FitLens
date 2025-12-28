// lib/services/api_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  // URLs (Verified correct from your logs)
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

  // --- 2. CORRECT (SMART REGEX VERSION 🧠) ---
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
        print("📥 AI RAW RESPONSE: $decoded");

        return {
          "food_name": decoded['food_name'] ?? decoded['item'] ?? userCorrection,
          "serving_unit": decoded['serving_unit'] ?? decoded['unit'] ?? "1 serving",

          // 🧠 THESE USE REGEX TO STRIP "kcal" AND "g" AND LOOK DEEP
          "calories_per_serving": _smartFind(decoded, ['calories_per_serving', 'calories', 'kcal']),
          "protein_per_serving": _smartFind(decoded, ['protein_per_serving', 'protein', 'prot']),
          "carbs_per_serving": _smartFind(decoded, ['carbs_per_serving', 'carbohydrates', 'carbs', 'carb']),
          "fat_per_serving": _smartFind(decoded, ['fat_per_serving', 'fat']),
        };
      } else {
        throw Exception("Correction Error: ${response.statusCode}");
      }
    } catch (e) {
      print("ERROR IN API: $e");
      throw Exception("Failed to correct item: $e");
    }
  }

  // 🕵️‍♂️ SHERLOCK HELPER
  // Finds the number whether it's at the top, nested, or mixed with text!
  num _smartFind(Map<String, dynamic> data, List<String> keys) {
    // 1. Look at Top Level
    for (String key in keys) {
      if (data.containsKey(key)) return _parseValue(data[key]);
    }
    // 2. Look Inside "nutritional_information" (Common AI pattern)
    if (data.containsKey('nutritional_information')) {
      var nested = data['nutritional_information'];
      if (nested is Map<String, dynamic>) {
        for (String key in keys) {
          if (nested.containsKey(key)) return _parseValue(nested[key]);
        }
      }
    }
    return 0;
  }

  // 🔢 REGEX EXTRACTOR: Turns "320 kcal" into 320
  num _parseValue(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value; // It's already a number!
    if (value is String) {
      // Find the first number (integer or decimal) in the string
      // This ignores "kcal", "g", "approx", etc.
      final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(value);
      if (match != null) {
        return num.tryParse(match.group(0)!) ?? 0;
      }
    }
    return 0;
  }
}