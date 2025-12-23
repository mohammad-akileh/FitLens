import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) return const Scaffold(body: Center(child: Text("Please login")));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2), // Off-white background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("PROFILE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Settings Coming Soon!")));
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Something went wrong"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.data() == null) return const Center(child: Text("No user data found"));

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String name = data['first_name'] ?? 'User';
          final int age = data['age'] ?? 0;
          final String? photoUrl = data['photo_url'];
          final double weight = data['weight']?.toDouble() ?? 0.0;
          final String weightUnit = data['weight_unit'] ?? 'kg';
          final String goal = data['goal'] ?? 'Maintain';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
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
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                            child: photoUrl == null
                                ? Icon(Icons.person, size: 40, color: Colors.grey[400])
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                              child: const Icon(Icons.add, color: Colors.white, size: 20),
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

                // --- Stats Row ---
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem("Current weight", "$weight $weightUnit"),
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
                        Navigator.push(context, MaterialPageRoute(builder: (context) => PersonalDetailsScreen(data: data)));
                      }),
                      _buildDivider(),
                      _buildMenuItem(Icons.restaurant_menu, "Dietary needs & preferences", () {}),
                      _buildDivider(),
                      _buildMenuItem(Icons.water_drop, "Set your habits", () {}),
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

// Define a simple extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

// --- A Simple "Personal Details" Screen ---
class PersonalDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const PersonalDetailsScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: const Text("PERSONAL DETAILS", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            children: [
              _buildDetailItem("First name", data['first_name'] ?? '-'),
              _buildDivider(),
              _buildDetailItem("Current weight", "${data['weight']} ${data['weight_unit']}"),
              _buildDivider(),
              _buildDetailItem("Height", "${data['height']} ${data['height_unit']}"),
              _buildDivider(),
              _buildDetailItem("Age", "${data['age']}"),
              _buildDivider(),
              _buildDetailItem("Gender", data['gender'] ?? '-'),
              _buildDivider(),
              _buildDetailItem("Activity Level", data['activity_level'] ?? '-'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
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
