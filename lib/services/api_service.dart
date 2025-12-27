// lib/services/api_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  // 🔗 REVERTED TO YOUR WORKING URLs (with '4', not 'f')
  final String _scanUrl = "https://generate-meal-data-xynwa4baqa-uc.a.run.app";
  final String _correctUrl = "https://correct-meal-item-xynwa4baqa-uc.a.run.app";

  // 🔒 THE SECRET
  final String _secretKey = "FitLens_VIP_2025";

  // --- CHIEF 1: SCAN ---
  Future<String> analyzeImage(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(_scanUrl));

      String? token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // 🔑 SEND THE SECRET
      request.headers['X-App-Secret'] = _secretKey;

      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return response.body;
      } else {
        print("Server Error: ${response.statusCode} - ${response.body}");
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Failed to connect to AI: $e");
    }
  }

  // --- CHIEF 2: CORRECT (With the "0 Fix") ---
  Future<Map<String, dynamic>> correctScan(File? imageFile, String wrongItem, String userCorrection) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(_correctUrl));

      String? token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // 🔑 SEND THE SECRET
      request.headers['X-App-Secret'] = _secretKey;

      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      }

      request.fields['wrong_item'] = wrongItem;
      request.fields['correction'] = userCorrection;

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // 🧠 THE FIX: MAP THE KEYS SAFELY
        // We accept EITHER "calories" OR "calories_per_serving"
        var decoded = jsonDecode(response.body);

        return {
          // If AI forgets the name, use what the user typed
          "food_name": decoded['food_name'] ?? decoded['item'] ?? userCorrection,
          "serving_unit": decoded['serving_unit'] ?? decoded['unit'] ?? "1 serving",

          // Safety Checks for numbers (Handles BOTH formats)
          "calories_per_serving": decoded['calories_per_serving'] ?? decoded['calories'] ?? 0,
          "protein_per_serving": decoded['protein_per_serving'] ?? decoded['protein'] ?? 0,
          "carbs_per_serving": decoded['carbs_per_serving'] ?? decoded['carbs'] ?? 0,
          "fat_per_serving": decoded['fat_per_serving'] ?? decoded['fat'] ?? 0,
        };

      } else {
        print("Correction Error: ${response.statusCode} - ${response.body}");
        throw Exception("Correction Error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Failed to correct item: $e");
    }
  }
}