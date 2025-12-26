// lib/screens/scan_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // 📦 You added this earlier!

class ScanScreen extends StatefulWidget {
  final String mealType; // e.g., "Breakfast", "Lunch"

  const ScanScreen({super.key, required this.mealType});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false; // To show loading spinner later

  // 📸 Function to Pick Image
  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  // 🧠 Placeholder for Gemini Logic (We will do this later)
  void _analyzeFood() {
    if (_selectedImage == null) return;

    setState(() => _isAnalyzing = true);

    // Simulate a delay for now (Just to show the UI works)
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("AI Analysis Started! (Logic coming soon)")),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Scan ${widget.mealType}",
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          // --- 1. THE IMAGE PREVIEW AREA ---
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: _selectedImage == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_rounded, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        Text("No food selected", style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(19), // Match container border
                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                    ),
            ),
          ),

          const SizedBox(height: 30),

          // --- 2. THE BUTTONS ---
          Container(
            padding: const EdgeInsets.all(30),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                if (_selectedImage == null) ...[
                  // Option A: Buttons to Pick Image
                  Row(
                    children: [
                      Expanded(
                        child: _buildOptionButton(
                          icon: Icons.camera_alt,
                          label: "Camera",
                          onTap: () => _pickImage(ImageSource.camera),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildOptionButton(
                          icon: Icons.photo_library,
                          label: "Gallery",
                          onTap: () => _pickImage(ImageSource.gallery),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Option B: Analyze Button (When image is selected)
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isAnalyzing ? null : _analyzeFood,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5F7E5B), // Your Primary Green
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: _isAnalyzing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Analyze Food 🔍", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => setState(() => _selectedImage = null),
                    child: const Text("Retake Photo", style: TextStyle(color: Colors.grey)),
                  )
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7F2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF5F7E5B).withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: const Color(0xFF5F7E5B)),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}
