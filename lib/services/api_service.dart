// lib/services/api_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  // KEEP YOUR .run.app LINKS HERE!
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

  // --- CHIEF 2: CORRECT ---
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
        return jsonDecode(response.body);
      } else {
        print("Correction Error: ${response.statusCode} - ${response.body}");
        throw Exception("Correction Error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Failed to correct item: $e");
    }
  }
}