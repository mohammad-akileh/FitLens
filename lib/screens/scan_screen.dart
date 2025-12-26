// lib/screens/scan_screen.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'meal_details_screen.dart';

class ScanScreen extends StatefulWidget {
  final String mealType;
  const ScanScreen({super.key,required this.mealType});

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

  // 1. Just pick the image, DON'T scan yet
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path); // Just show it!
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error picking image: $e")));
    }
  }

  // 2. NOW we scan (when user clicks button)
  Future<void> _analyzeMeal() async {
    if (_imageFile == null) return;

    setState(() => _isLoading = true);

    try {
      // Call the AI
      String result = await _apiService.analyzeImage(_imageFile!);

      if (mounted) {
        // Go to Results
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MealDetailsScreen(
              imageFile: _imageFile,
              aiResponse: result,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Scan ${widget.mealType}", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
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
                // --- SHOW IMAGE OR BUTTONS ---
                child: _imageFile != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.file(_imageFile!, fit: BoxFit.cover),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_rounded, size: 60, color: Colors.grey),
                    SizedBox(height: 20),
                    Text("Take a photo of your meal", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                  ],
                ),
              ),
            ),

            SizedBox(height: 30),

            // --- THE BUTTONS ---
            if (_imageFile == null) ...[
              // Option A: No Image yet -> Show Camera/Gallery Buttons
              Row(
                children: [
                  Expanded(child: _buildActionButton("Camera", Icons.camera, () => _pickImage(ImageSource.camera))),
                  SizedBox(width: 15),
                  Expanded(child: _buildActionButton("Gallery", Icons.photo_library, () => _pickImage(ImageSource.gallery))),
                ],
              ),
            ] else ...[
              // Option B: Image Selected -> Show "Retake" or "Analyze"
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _imageFile = null),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        side: BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: Text("Retake", style: TextStyle(color: Colors.grey[800], fontSize: 16)),
                    ),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _analyzeMeal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainTextColor,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: _isLoading
                          ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text("Analyze Meal", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: mainTextColor,
        padding: EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }
}