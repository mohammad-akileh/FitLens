// lib/screens/profile/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/calculator.dart';
import 'dietary_screen.dart';
import 'habits_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _ensureDatabaseExists();
  }

  Future<void> _ensureDatabaseExists() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    final docRef = _db.collection('users').doc(user.uid);
    final docSnap = await docRef.get();

    if (!docSnap.exists) {
      await docRef.set({
        'email': user.email,
        'first_name': user.displayName ?? 'Besti',
        'created_at': FieldValue.serverTimestamp(),
        'target_calories': 2000,
        'target_protein': 150,
        'target_carbs': 250,
        'target_fat': 65,
        'target_water': 2500,
        'app_secret': 'FitLens_VIP_2025',
      }, SetOptions(merge: true));
      if (mounted) setState(() {});
    }
  }

  Future<void> _uploadProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      String uid = _auth.currentUser!.uid;
      File file = File(image.path);
      Reference ref = _storage.ref().child('profile_pics/$uid.jpg');
      SettableMetadata metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'app_secret': 'FitLens_VIP_2025'}
      );

      UploadTask task = ref.putFile(file, metadata);
      TaskSnapshot snapshot = await task;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      await _db.collection('users').doc(uid).update({
        'photo_url': downloadUrl,
        'app_secret': 'FitLens_VIP_2025',
      });

      await _auth.currentUser?.updatePhotoURL(downloadUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile picture updated! 📸"), backgroundColor: Colors.green),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Please login")));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("PROFILE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _db.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Something went wrong"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          String name = data['first_name'] ?? user.displayName ?? 'User';
          final int age = data['age'] ?? 0;
          final String? photoUrl = data['photo_url'];

          // --- INTELLIGENT UNIT DISPLAY ---
          final double rawWeight = (data['weight'] ?? 0.0).toDouble();
          final String unitPref = data['weight_unit'] ?? 'kg';

          String displayWeight;
          if (unitPref.toLowerCase() == 'lbs') {
            displayWeight = (rawWeight * 2.20462).toStringAsFixed(1);
          } else {
            displayWeight = rawWeight.toStringAsFixed(1);
          }

          final String goal = data['goal'] ?? 'Maintain';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
                  ),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: photoUrl != null
                                ? NetworkImage(photoUrl)
                                : (user.photoURL != null ? NetworkImage(user.photoURL!) : null),
                            child: _isUploading
                                ? const CircularProgressIndicator()
                                : (photoUrl == null && user.photoURL == null
                                ? Icon(Icons.person, size: 40, color: Colors.grey[400])
                                : null),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _isUploading ? null : _uploadProfilePicture,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                                child: const Icon(Icons.add, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          Text("$age years old", style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem("Current weight", "$displayWeight $unitPref"),
                      _buildStatItem("Goal", goal.replaceAll('_', ' ').capitalize()),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                const Align(alignment: Alignment.centerLeft, child: Text("CUSTOMIZATION", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    children: [
                      _buildMenuItem(Icons.person, "Personal details", () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => PersonalDetailsScreen(data: data, displayName: name)));
                      }),
                      _buildDivider(),
                      _buildMenuItem(Icons.restaurant_menu, "Dietary needs & preferences", () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => DietaryScreen(data: data)));
                      }),
                      _buildDivider(),
                      _buildMenuItem(Icons.water_drop, "Set your habits", () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => HabitsScreen(data: data)));
                      }),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 60, endIndent: 20);
  }
}

extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) return "";
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

// ---------------------------------------------------------
// 🛠️ EDITABLE PERSONAL DETAILS SCREEN
// ---------------------------------------------------------
class PersonalDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final String displayName;

  const PersonalDetailsScreen({
    super.key,
    required this.data,
    required this.displayName
  });

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;

  String? _selectedActivityLevel;
  final List<String> _activityLevels = ["Sedentary", "Light", "Moderate", "Active", "Very Active"];
  bool _isSaving = false;

  bool _isLbs = false;
  bool _isFt = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.displayName);

    double weightKg = (widget.data['weight'] ?? 70.0).toDouble();
    double heightCm = (widget.data['height'] ?? 170.0).toDouble();

    String wUnit = widget.data['weight_unit'] ?? 'kg';
    String hUnit = widget.data['height_unit'] ?? 'cm';

    // 1. SETUP WEIGHT
    if (wUnit.toLowerCase() == 'lbs') {
      _isLbs = true;
      double lbs = weightKg * 2.20462;
      _weightController = TextEditingController(text: lbs.toStringAsFixed(1));
    } else {
      _isLbs = false;
      _weightController = TextEditingController(text: weightKg.toStringAsFixed(1));
    }

    // 2. SETUP HEIGHT
    if (hUnit.toLowerCase() == 'ft') {
      _isFt = true;
      double ft = heightCm / 30.48;
      _heightController = TextEditingController(text: ft.toStringAsFixed(2));
    } else {
      _isFt = false;
      _heightController = TextEditingController(text: heightCm.toStringAsFixed(1));
    }

    // 🔴 3. FIX: HANDLE BOTH STRING AND DOUBLE FOR ACTIVITY LEVEL (THE RED SCREEN FIX)
    var rawLevel = widget.data['activity_level'];
    String currentLevel = "Moderate"; // Default fallback

    if (rawLevel is num) {
      // If DB has a number (e.g. 1.375), convert back to name
      if (rawLevel <= 1.2) currentLevel = "Sedentary";
      else if (rawLevel <= 1.375) currentLevel = "Light";
      else if (rawLevel <= 1.55) currentLevel = "Moderate";
      else if (rawLevel <= 1.725) currentLevel = "Active";
      else currentLevel = "Very Active";
    } else if (rawLevel is String) {
      // If DB has a string, use it
      currentLevel = rawLevel;
    }

    // Ensure value exists in list (Case insensitive check)
    _selectedActivityLevel = _activityLevels.firstWhere(
            (level) => level.toLowerCase() == currentLevel.toLowerCase(),
        orElse: () => "Moderate"
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      String newName = _nameController.text.trim();
      double inputWeight = double.tryParse(_weightController.text.replaceAll(',', '.')) ?? 0.0;
      double inputHeight = double.tryParse(_heightController.text.replaceAll(',', '.')) ?? 0.0;
      String newActivity = _selectedActivityLevel ?? "Moderate";

      // Convert back to Metric for saving
      double metricWeight = _isLbs ? (inputWeight * 0.453592) : inputWeight;
      double metricHeight = _isFt ? (inputHeight * 30.48) : inputHeight;

      if (metricWeight < 20 || metricWeight > 500) {
        throw "Weight must be between 20kg (44lbs) and 500kg (1100lbs).";
      }
      if (metricHeight < 50 || metricHeight > 300) {
        throw "Height must be between 50cm (1.6ft) and 300cm (9.8ft).";
      }

      int age = widget.data['age'] ?? 20;
      String genderStr = widget.data['gender'] ?? 'Male';
      String goalStr = widget.data['goal'] ?? 'Maintain';

      double bmr = Calculator.calculateBMR(
        heightCm: metricHeight,
        weightKg: metricWeight,
        age: age,
        isMale: genderStr.toLowerCase() == 'male',
      );

      double activityMultiplier = 1.2;
      if (newActivity == "Light") activityMultiplier = 1.375;
      if (newActivity == "Moderate") activityMultiplier = 1.55;
      if (newActivity == "Active") activityMultiplier = 1.725;
      if (newActivity == "Very Active") activityMultiplier = 1.9;

      double newTargetCals = Calculator.calculateTargetCalories(bmr, activityMultiplier: activityMultiplier);

      String macroGoal = 'maintain';
      if (goalStr.toLowerCase().contains('gain')) macroGoal = 'muscle';
      if (goalStr.toLowerCase().contains('lose')) macroGoal = 'loss';

      Map<String, double> newMacros = Calculator.calculateMacros(newTargetCals, goal: macroGoal);
      double newWater = Calculator.calculateWater(weightKg: metricWeight);

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'first_name': newName,
        'weight': metricWeight,
        'height': metricHeight,
        'activity_level': newActivity, // Saves the String Name now
        'target_calories': newTargetCals.round(),
        'target_protein': newMacros['protein']!.round(),
        'target_carbs': newMacros['carb']!.round(),
        'target_fat': newMacros['fat']!.round(),
        'target_water': (newWater * 1000).round(),
        'app_secret': 'FitLens_VIP_2025',
      });

      await FirebaseAuth.instance.currentUser?.updateDisplayName(newName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile & Goals Updated! 🎯"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(e.toString().replaceAll("Exception:", "")),
                backgroundColor: Colors.red
            )
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
            onPressed: () => Navigator.pop(context)
        ),
        title: const Text("EDIT DETAILS", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveChanges,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text("Save", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            children: [
              _buildEditableItem("Name", _nameController),
              _buildDivider(),
              _buildEditableItem("Current weight (${_isLbs ? 'lbs' : 'kg'})", _weightController, isNumber: true),
              _buildDivider(),
              _buildEditableItem("Height (${_isFt ? 'ft' : 'cm'})", _heightController, isNumber: true),
              _buildDivider(),
              _buildDropdownItem("Activity Level"),
              _buildDivider(),
              _buildReadOnlyItem("Age", "${widget.data['age']}"),
              _buildDivider(),
              _buildReadOnlyItem("Gender", widget.data['gender'] ?? '-'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableItem(String label, TextEditingController controller, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160, minWidth: 80),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: controller,
                  keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.name,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Enter value",
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownItem(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedActivityLevel,
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.green),
                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 16),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedActivityLevel = newValue!;
                  });
                },
                items: _activityLevels.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
          Text(value, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 20, endIndent: 20);
  }
}