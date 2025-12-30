import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart'; // Needed for Dark Mode
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart'; // Optional: for real version checking

import '../../services/auth_service.dart';
import '../../services/theme_provider.dart'; // Ensure this path is correct

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsTab> {
  bool _notificationsEnabled = true;
  String _version = "1.0.0 (Beta)";

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value ? "Notifications Enabled" : "Notifications Disabled")),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  // --- 🔗 SMART SHARE FUNCTION ---
  Future<void> _shareApp() async {
    try {
      // 1. Get the link from your Database
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('general')
          .get();

      String link = "";
      if (doc.exists && doc.data() != null) {
        link = (doc.data() as Map<String, dynamic>)['app_link'] ?? "";
      }

      // 2. Share the message
      // If link is empty, it just sends the text.
      Share.share('Check out FitLens! It counts calories from photos instantly using AI. \n\n$link');

    } catch (e) {
      // Fallback if DB fails
      Share.share('Check out FitLens! It counts calories from photos instantly.');
    }
  }

  // --- 📝 PROFESSIONAL TEXT DIALOGS ---
  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Adapts to Dark Mode
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  // --- 🔴 DELETE ACCOUNT (THE NUCLEAR OPTION) ---
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Delete Account", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text(
          "Are you sure? This will permanently delete your profile, meal history, and saved recipes. This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              // 1. Capture Navigator
              final navigator = Navigator.of(context);

              // 2. Show loading / Close dialog
              navigator.pop();

              try {
                User? user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  // A. Delete Firestore Data
                  await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();

                  // B. Delete Auth Account
                  await user.delete();

                  // C. Navigate to Login
                  navigator.popUntil((route) => route.isFirst);
                }
              } catch (e) {
                // Handle "Requires Recent Login" error
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Security: Please log out and log in again to delete your account.")),
                );
              }
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- SIGN OUT DIALOG ---
  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Sign Out", style: TextStyle(color: Colors.red)),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              navigator.pop();
              await AuthService().signOut();
              navigator.popUntil((route) => route.isFirst);
            },
            child: const Text("Sign Out", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          // 1. Dark Mode
          SwitchListTile(
            title: const Text("Dark Mode"),
            subtitle: const Text("Easier on the eyes"),
            value: themeProvider.isDarkMode,
            activeColor: Colors.green,
            onChanged: (value) {
              final provider = Provider.of<ThemeProvider>(context, listen: false);
              provider.toggleTheme(value);
            },
          ),

          // 2. Notifications
          SwitchListTile(
            title: const Text("Notifications"),
            subtitle: const Text("Receive daily reminders"),
            value: _notificationsEnabled,
            activeColor: Colors.green,
            onChanged: _toggleNotifications,
          ),

          const Divider(),

          // 3. Contact Developer (Untouched as requested)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Contact Developer", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.email, color: Colors.red, size: 30),
                      onPressed: () => _launchUrl("mailto:your_email@gmail.com?subject=FitLens Feedback"),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.github, color: Colors.black, size: 30),
                      onPressed: () => _launchUrl("https://github.com/your_username"),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),

          // 4. Privacy Policy (Updated Text)
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text("Privacy Policy"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showInfoDialog(
                "Privacy Policy",
                "Effective Date: January 2026\n\n"
                    "At FitLens, your privacy is our priority. This policy outlines how we handle your data.\n\n"
                    "1. Data Collection\n"
                    "We collect your email for authentication and basic profile details (height, weight, age) to calculate your health metrics. Food images are uploaded temporarily to analyze calories using AI.\n\n"
                    "2. Image Usage\n"
                    "Your food photos are processed securely. We do not sell your photos to third parties. Images are stored in your private history until you delete them.\n\n"
                    "3. Security\n"
                    "We use Google Firebase Authentication and Firestore Security Rules to ensure only YOU can access your personal data.\n\n"
                    "4. Contact\n"
                    "If you have questions about your data, please contact the developer via the email button."
            ),
          ),

          // 5. Help & FAQ (Updated Text)
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text("Help & FAQ"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showInfoDialog(
                "Help & FAQ",
                "1. How do I scan a meal?\n"
                    "Go to the 'Home' tab and tap the '+' button or the 'Scan Meal' button. You can use your camera or pick a photo from your gallery.\n\n"
                    "2. Is the calorie count 100% accurate?\n"
                    "FitLens uses advanced AI to estimate calories. While highly accurate, it is an estimation. You can manually edit items if the AI misses something.\n\n"
                    "3. How do I change my goals?\n"
                    "Go to the 'Profile' tab and tap 'Personal details' to update your weight, height, or activity level. Your calorie targets will recalculate automatically.\n\n"
                    "4. Can I delete a meal?\n"
                    "Yes. Go to the 'History' tab, find the meal in the list, and swipe left to delete it."
            ),
          ),

          // 6. Share App (Dynamic Link)
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text("Share App"),
            onTap: _shareApp,
          ),

          const Divider(),

          // 7. Sign Out
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.grey),
            title: const Text("Sign Out", style: TextStyle(color: Colors.grey)),
            onTap: _showSignOutDialog,
          ),

          // 8. Delete Account (New)
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text("Delete Account", style: TextStyle(color: Colors.red)),
            onTap: _showDeleteAccountDialog,
          ),

          const SizedBox(height: 20),

          // 9. Version
          Center(
            child: Text(
              "Version $_version",
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}