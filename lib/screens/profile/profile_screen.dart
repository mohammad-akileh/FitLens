import 'dart:io'; // Needed for File
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Needed for Upload
import 'package:image_picker/image_picker.dart'; // 📦 The New Package

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
                        // Placeholder for now
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Coming in Phase 2!")));
                      }),
                      _buildDivider(),
                      _buildMenuItem(Icons.water_drop, "Set your habits", () {
                        // Placeholder for now
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Coming in Phase 2!")));
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
// 🛠️ EDITABLE PERSONAL DETAILS SCREEN
// ---------------------------------------------------------
// ---------------------------------------------------------
// 🛠️ EDITABLE PERSONAL DETAILS SCREEN (Fixed Constructor)
// ---------------------------------------------------------
class PersonalDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final String displayName; // ✅ Added this line to accept the name

  const PersonalDetailsScreen({
    super.key,
    required this.data,
    required this.displayName // ✅ Added this line to require it
  });

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  // We need controllers to capture text input
  late TextEditingController _nameController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // ✅ FIX: Use the 'displayName' passed from the previous screen
    // This ensures the box is pre-filled with "User" or their Google name
    _nameController = TextEditingController(text: widget.displayName);

    _weightController = TextEditingController(text: (widget.data['weight'] ?? 0).toString());
    _heightController = TextEditingController(text: (widget.data['height'] ?? 0).toString());
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

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'first_name': _nameController.text.trim(),
        'weight': double.tryParse(_weightController.text) ?? 0.0,
        'height': double.tryParse(_heightController.text) ?? 0.0,
        'app_secret': 'FitLens_VIP_2025', // 🔐 DB Password
      });

      // Also update the Auth Display Name for consistency
      await FirebaseAuth.instance.currentUser?.updateDisplayName(_nameController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Details Saved! ✅"), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Go back to profile
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
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
          // SAVE BUTTON
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
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            children: [
              _buildEditableItem("First name", _nameController),
              _buildDivider(),
              _buildEditableItem("Current weight (kg)", _weightController, isNumber: true),
              _buildDivider(),
              _buildEditableItem("Height (cm)", _heightController, isNumber: true),
              _buildDivider(),
              // Non-editable fields (Read only)
              _buildReadOnlyItem("Age", "${widget.data['age']}"),
              _buildDivider(),
              _buildReadOnlyItem("Gender", widget.data['gender'] ?? '-'),
              _buildDivider(),
              _buildReadOnlyItem("Activity Level", widget.data['activity_level'] ?? '-'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableItem(String label, TextEditingController controller, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(
            width: 150,
            child: TextField(
              controller: controller,
              keyboardType: isNumber ? TextInputType.number : TextInputType.name,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(border: InputBorder.none, hintText: "Enter value"),
              style: TextStyle(fontSize: 16, color: Colors.grey[800]),
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
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 20, endIndent: 20);
  }
}