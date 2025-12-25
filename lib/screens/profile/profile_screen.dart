import 'dart:io'; // Needed for File
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Needed for Upload
import 'package:image_picker/image_picker.dart'; // 📦 The New Package
import '../../utils/calculator.dart'; // Import your Brain 🧠
import 'dietary_screen.dart'; // Add this
import 'habits_screen.dart'; // Add this
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool _isUploading = false; // To show spinner when uploading

// 📸 FUNCTION: Pick and Upload Image (Now with PASSWORD 🔐)
  Future<void> _uploadProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      String uid = _auth.currentUser!.uid;
      File file = File(image.path);

      // 1. Create Reference
      Reference ref = _storage.ref().child('profile_pics/$uid.jpg');

      // 2. 🔐 ADD THE PASSWORD METADATA 🔐
      // This is the key to open the Storage door!
      SettableMetadata metadata = SettableMetadata(
          customMetadata: {'app_secret': 'FitLens_VIP_2025'}
      );

      // 3. Upload with Metadata
      UploadTask task = ref.putFile(file, metadata);

      TaskSnapshot snapshot = await task;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // 4. Save URL to Firestore
      await _db.collection('users').doc(uid).update({
        'photo_url': downloadUrl,
        'app_secret': 'FitLens_VIP_2025', // DB Password
      });

      // 5. Update Local Auth (Helps UI update faster)
      await _auth.currentUser?.updatePhotoURL(downloadUrl);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile picture updated! 📸"), backgroundColor: Colors.green),
      );

    } catch (e) {
      print("Upload Error: $e"); // Check console if it fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isUploading = false);
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
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          // Data Extraction
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          // 1. NAME FIX: Check DB first, then Google Auth, then fallback
          String name = data['first_name'] ?? user.displayName ?? 'User';

          final int age = data['age'] ?? 0;
          final String? photoUrl = data['photo_url'];

          // 2. NUMBER FIX: Round the weight
          final double weight = (data['weight'] ?? 0.0).toDouble();
          final String displayWeight = weight.toStringAsFixed(1); // "69.7699" -> "69.8"

          final String weightUnit = data['weight_unit'] ?? 'kg';
          final String goal = data['goal'] ?? 'Maintain';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // --- Profile Header Card ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
                  ),
                  child: Row(
                    children: [
                      // PROFILE PICTURE STACK
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                            child: _isUploading
                                ? const CircularProgressIndicator()
                                : (photoUrl == null ? Icon(Icons.person, size: 40, color: Colors.grey[400]) : null),
                          ),

                          // THE GREEN PLUS BUTTON 🟢
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _isUploading ? null : _uploadProfilePicture, // 🔗 Connect the function!
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

                      // NAME AND AGE
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

                // --- Stats Row (Fixed Decimals) ---
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem("Current weight", "$displayWeight $weightUnit"), // Using fixed variable
                      _buildStatItem("Goal", goal.replaceAll('_', ' ').capitalize()),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
                const Align(alignment: Alignment.centerLeft, child: Text("CUSTOMIZATION", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                const SizedBox(height: 10),

                // --- Menu Options ---
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    children: [
                      _buildMenuItem(Icons.person, "Personal details", () {
                        // Pass the Name/Photo down to details so it matches
                        Navigator.push(context, MaterialPageRoute(builder: (context) => PersonalDetailsScreen(data: data, displayName: name)));
                      }),
                      _buildDivider(),
                      _buildMenuItem(Icons.restaurant_menu, "Dietary needs & preferences", () {
                        // This opens the new Dietary Screen!
                        Navigator.push(context, MaterialPageRoute(builder: (context) => DietaryScreen(data: data)));
                      }),
                      _buildDivider(),
                      _buildMenuItem(Icons.water_drop, "Set your habits", () {
                        // This opens the new Habits Screen!
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

  // ... (Helper widgets _buildStatItem, _buildMenuItem, _buildDivider remain same)
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

// Extension for capitalization
extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) return "";
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

// ---------------------------------------------------------
// ---------------------------------------------------------
// 🛠️ EDITABLE PERSONAL DETAILS SCREEN (Polished UI)
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

  // For the Dropdown
  String? _selectedActivityLevel;
  final List<String> _activityLevels = [
    "Sedentary",
    "Light",
    "Moderate",
    "Active",
    "Very Active"
  ];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.displayName);

    // Clean up initial numbers (remove .0 if it's an integer)
    double w = (widget.data['weight'] ?? 0).toDouble();
    double h = (widget.data['height'] ?? 0).toDouble();

    // Logic: If it's 80.0, show "80". If 80.5, show "80.5"
    _weightController = TextEditingController(
        text: w % 1 == 0 ? w.toInt().toString() : w.toString()
    );
    _heightController = TextEditingController(
        text: h % 1 == 0 ? h.toInt().toString() : h.toString()
    );

    // Set initial activity level (Default to Moderate if missing)
    String currentLevel = widget.data['activity_level'] ?? "Moderate";
    // Ensure the value from DB matches one of our list options (Capitalize if needed)
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

      // 1. Get the New Raw Data
      String newName = _nameController.text.trim();
      double newWeight = double.tryParse(_weightController.text.replaceAll(',', '.')) ?? 0.0;
      double newHeight = double.tryParse(_heightController.text.replaceAll(',', '.')) ?? 0.0;
      String newActivity = _selectedActivityLevel ?? "Moderate";

      // We need these old values for the math (Age/Gender didn't change on this screen)
      int age = widget.data['age'] ?? 20;
      String gender = widget.data['gender'] ?? 'male';
      String goalStr = widget.data['goal'] ?? 'Maintain';

      // ---------------------------------------------------------
      // 🧠 2. THE RE-CALCULATION (The Mechanism Update)
      // ---------------------------------------------------------

      // A. Calculate BMR
      double bmr = Calculator.calculateBMR(
        heightCm: newHeight.toInt(),
        weightKg: newWeight.toInt(),
        age: age,
        gender: gender,
      );

      // B. Map Activity String to Number (1.2, 1.375, etc)
      // (You might want to add a helper for this in Calculator class later)
      double activityMultiplier = 1.2;
      if (newActivity == "Light") activityMultiplier = 1.375;
      if (newActivity == "Moderate") activityMultiplier = 1.55;
      if (newActivity == "Active") activityMultiplier = 1.725;
      if (newActivity == "Very Active") activityMultiplier = 1.9;

      // C. Get New Calories
      double newTargetCals = Calculator.calculateTargetCalories(bmr, activityMultiplier: activityMultiplier);

      // D. Get New Macros
      String macroGoal = 'maintain';
      if (goalStr.toLowerCase().contains('gain')) macroGoal = 'muscle';
      if (goalStr.toLowerCase().contains('lose')) macroGoal = 'loss';

      Map<String, double> newMacros = Calculator.calculateMacros(newTargetCals, goal: macroGoal);

      // E. Get New Water
      // (Simple logic: Base water. You can add exercise hours logic later if needed)
      double newWater = Calculator.calculateWater(weightKg: newWeight.toInt());

      // ---------------------------------------------------------
      // 💾 3. SAVE EVERYTHING TO DB
      // ---------------------------------------------------------

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        // Profile Data
        'first_name': newName,
        'weight': newWeight,
        'height': newHeight,
        'activity_level': newActivity,

        // 🎯 UPDATED TARGETS (This fixes your concern!)
        'target_calories': newTargetCals.round(),
        'target_protein': newMacros['protein']!.round(),
        'target_carbs': newMacros['carb']!.round(),
        'target_fat': newMacros['fat']!.round(),
        'target_water': (newWater * 1000).round(), // Convert L to mL

        'app_secret': 'FitLens_VIP_2025',
      });

      // Update Auth Name
      await FirebaseAuth.instance.currentUser?.updateDisplayName(newName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile & Goals Updated! 🎯"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      // ... error handling
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
              // ✏️ EDITABLE FIELDS (Now look like inputs!)
              _buildEditableItem("First name", _nameController),
              _buildDivider(),
              _buildEditableItem("Current weight (kg)", _weightController, isNumber: true),
              _buildDivider(),
              _buildEditableItem("Height (cm)", _heightController, isNumber: true),
              _buildDivider(),

              // 🔽 DROPDOWN FOR ACTIVITY
              _buildDropdownItem("Activity Level"),
              _buildDivider(),

              // 🔒 READ ONLY FIELDS
              _buildReadOnlyItem("Age", "${widget.data['age']}"),
              _buildDivider(),
              _buildReadOnlyItem("Gender", widget.data['gender'] ?? '-'),
            ],
          ),
        ),
      ),
    );
  }

  // 🎨 UPDATED: Looks like an input box now
  Widget _buildEditableItem(String label, TextEditingController controller, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(width: 10), // Spacer
          // The Input Box
          SizedBox(
            width: 160,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100], // 🎨 Light background
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[300]!), // Subtle border
              ),
              child: TextField(
                controller: controller,
                keyboardType: isNumber ? TextInputType.numberWithOptions(decimal: true) : TextInputType.name,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "Enter value",
                  suffixIcon: Icon(Icons.edit, size: 14, color: Colors.grey[400]), // ✏️ Tiny Pencil
                  suffixIconConstraints: BoxConstraints(maxHeight: 20, minWidth: 25),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                style: TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔽 NEW: Dropdown for Activity
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
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)), // Grey title for read-only
          Text(value, style: TextStyle(fontSize: 16, color: Colors.grey[600])), // Grey text for read-only
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 20, endIndent: 20);
  }
}