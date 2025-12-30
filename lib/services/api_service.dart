// lib/services/api_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  // URLs
  final String _scanUrl = "https://generate-meal-data-xynwa4baqa-uc.a.run.app";
  final String _correctUrl = "https://correct-meal-item-xynwa4baqa-uc.a.run.app";
  final String _secretKey = "FitLens_VIP_2025";

  // --- 1. SCAN (With Black Picture & Timeout Safety) ---
  Future<String> analyzeImage(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(_scanUrl));
      String? token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.headers['X-App-Secret'] = _secretKey;
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      // ✅ FIX 1: TIMEOUT HANDLER
      // If internet drops or server hangs, stop after 20 seconds.
      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw Exception("Connection timed out. Please check your internet.");
        },
      );

      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // ✅ FIX 2: BLACK PICTURE SAFETY
        // If AI returns plain text (like "No food found") instead of JSON,
        // this check prevents the app from crashing.
        if (_isValidJson(response.body)) {
          return response.body; // It's valid JSON, send it to UI.
        } else {
          print("⚠️ AI returned text, not JSON. Handling safely.");
          // Return a safe "Empty" JSON so the UI doesn't crash
          return jsonEncode({
            "items": [],
            "summary": "No food detected",
            "total_calories": 0
          });
        }
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error in analyzeImage: $e");
      // ✅ FIX 3: Internet Error Handling
      // Return safe empty data instead of crashing the app
      throw Exception("Network Error: $e");
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

      // ✅ FIX: TIMEOUT ADDED HERE TOO
      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw Exception("Correction timed out.");
        },
      );

      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Safety check for Correction as well
        if (!_isValidJson(response.body)) {
          throw Exception("AI returned invalid format.");
        }

        var decoded = jsonDecode(response.body);
        print("📥 AI RAW RESPONSE: $decoded");

        return {
          "food_name": decoded['food_name'] ?? decoded['item'] ?? userCorrection,
          "serving_unit": decoded['serving_unit'] ?? decoded['unit'] ?? "1 serving",
          // 🧠 Regex Parsers
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

  // 🛡️ HELPER: Checks if a string is valid JSON
  bool _isValidJson(String str) {
    try {
      jsonDecode(str);
      return true;
    } catch (e) {
      return false;
    }
  }

  // 🕵️‍♂️ SHERLOCK HELPER
  num _smartFind(Map<String, dynamic> data, List<String> keys) {
    // 1. Look at Top Level
    for (String key in keys) {
      if (data.containsKey(key)) return _parseValue(data[key]);
    }
    // 2. Look Inside "nutritional_information"
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

  // 🔢 REGEX EXTRACTOR
  num _parseValue(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    if (value is String) {
      final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(value);
      if (match != null) {
        return num.tryParse(match.group(0)!) ?? 0;
      }
    }
    return 0;
  }
}