// lib/screens/scan_screen.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../screens/meal_history_detail_screen.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class ScanScreen extends StatefulWidget {
  final String mealType;
  const ScanScreen({super.key, required this.mealType});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  final Color mainTextColor = const Color(0xFF5F7E5B);
  final Color buttonColor = const Color(0xFFF6F5F0);

  // 1. Pick Image
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      String niceMessage = "Could not open camera.";
      if (e.toString().toLowerCase().contains("permission") ||
          e.toString().toLowerCase().contains("access") ||
          e.toString().toLowerCase().contains("denied")) {
        niceMessage = "Camera permission is needed to scan your meal 📸";
      }

      _showBeautifulError(niceMessage, isWarning: true);
    }
  }

  // 2. Analyze & Navigate
  Future<void> _analyzeMeal() async {
    // Basic connectivity check
    bool result = await InternetConnection().hasInternetAccess;
    if (!result) {
      _showBeautifulError("No Internet! Please check your connection 📶");
      return;
    }
    if (_imageFile == null) return;

    setState(() => _isLoading = true);

    try {
      String result = await _apiService.analyzeImage(_imageFile!);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MealHistoryDetailScreen(
              imageFile: _imageFile,
              aiResponse: result,
            ),
          ),
        );
      }
    } catch (e) {
      // 🎨 HERE IS THE BEAUTIFUL EXCEPTION
      String message = e.toString();

      // If the message is super long, shorten it
      if (message.length > 100) {
        message = "Something went wrong. Please try again.";
      }

      _showBeautifulError(message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🎨 BEAUTIFUL ERROR HELPER
  void _showBeautifulError(String message, {bool isWarning = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
                isWarning ? Icons.warning_amber_rounded : Icons.wifi_off_rounded,
                color: Colors.white
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        backgroundColor: isWarning ? Colors.orange : Colors.red.shade400,
        behavior: SnackBarBehavior.floating, // Floating looks much better
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Scan ${widget.mealType}",
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: buttonColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withOpacity(0.3), width: 2),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.file(_imageFile!, fit: BoxFit.cover),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt_rounded,
                        size: 60, color: Colors.grey),
                    const SizedBox(height: 20),
                    Text("Take a photo of your meal",
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 16)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Buttons Logic
            if (_imageFile == null) ...[
              Row(
                children: [
                  Expanded(
                      child: _buildActionButton("Camera", Icons.camera,
                              () => _pickImage(ImageSource.camera))),
                  const SizedBox(width: 15),
                  Expanded(
                      child: _buildActionButton("Gallery", Icons.photo_library,
                              () => _pickImage(ImageSource.gallery))),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _imageFile = null),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                      ),
                      child: Text("Retake",
                          style: TextStyle(color: Colors.grey[800], fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _analyzeMeal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainTextColor,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                          : const Text("Analyze Meal",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
      label: Text(label,
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: mainTextColor,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }
}