import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // 👈 ADD THIS
// --- NEW IMPORTS FOR TESTING ---
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
// -------------------------------

import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
// I assume 'flutterLocalNotificationsPlugin' is globally available in notification_service.dart
// If not, make sure it is exported or imported here.

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsTab> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
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

  // --- 🔴 NEW TEST FUNCTION ---
// In lib/screens/settings_tab.dart

  Future<void> _scheduleTestNotification() async {
    // Just call the service!
    await NotificationService.scheduleTestNotification();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Test Scheduled! Wait 10 seconds...")),
      );
    }
  }
  // -----------------------------

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });

    // Save to local memory (SharedPreferences)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);

    // 🔴 CONNECT TO FIREBASE (The Fix)
    if (value) {
      // If ON, Subscribe to the channel
      await FirebaseMessaging.instance.subscribeToTopic('daily_reminders');
      print("✅ Subscribed to daily_reminders");
    } else {
      // If OFF, Unsubscribe from the channel
      await FirebaseMessaging.instance.unsubscribeFromTopic('daily_reminders');
      print("🔕 Unsubscribed from daily_reminders");
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(value ? "Reminders Enabled" : "Reminders Disabled")),
      );
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _shareApp() async {
    String message = 'Check out FitLens! It counts calories from photos instantly using AI.';

    bool hasNet = await _hasInternet();
    if (!hasNet) {
      Share.share(message);
      return;
    }

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('general')
          .get();

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['app_secret'] == 'FitLens_VIP_2025') {
          String link = data['app_link'] ?? "";
          if (link.isNotEmpty) {
            message += "\n\n$link";
          }
        }
      }
      Share.share(message);
    } catch (e) {
      Share.share(message);
    }
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black87
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Delete Account", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text(
          "Are you sure? This will permanently delete your profile, meal history, and saved recipes. This action cannot be undone.",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              navigator.pop();

              bool hasNet = await _hasInternet();
              if (!hasNet) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text("⚠️ Internet connection required to delete account."),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              try {
                await AuthService().deleteAccount();
                navigator.popUntil((route) => route.isFirst);
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text("Security: Please log out and log in again to delete your account.")),
                  );
                }
              }
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Sign Out", style: TextStyle(color: Colors.red)),
        content: const Text("Are you sure you want to sign out?", style: TextStyle(color: Colors.black)),
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
    return Scaffold(
      backgroundColor: const Color(0xFFDFE2D1) ,
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          // 🔔 DAILY REMINDERS
          SwitchListTile(
            title: const Text("Daily Reminders"),
            subtitle: const Text("Receive notifications to log meals"),
            value: _notificationsEnabled,
            activeColor: Colors.green,
            onChanged: _toggleNotifications,
          ),

          // 🔴 TEST BUTTON (REMOVE AFTER FIXING)
          ListTile(
            leading: const Icon(Icons.timer, color: Colors.orange),
            title: const Text(
              "🔴 TEST NOTIFICATION (1 MIN)",
              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
            ),
            subtitle: const Text("Tap this, close app, wait 1 minute."),
            onTap: _scheduleTestNotification,
          ),
          // ------------------------------------

          const Divider(),
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
                      onPressed: () => _launchUrl("mailto:mohammad.akileh.815@gmail.com?subject=FitLens Feedback"),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: const FaIcon(
                          FontAwesomeIcons.github,
                          color: Colors.black,
                          size: 30
                      ),
                      onPressed: () => _launchUrl("https://github.com/mohammad-akileh"),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text("Privacy Policy"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showInfoDialog(
                "Privacy Policy",
                "Effective Date: January 2026\n\nAt FitLens, your privacy is our priority. This policy outlines how we handle your data.\n\n1. Data Collection\nWe collect your email for authentication and basic profile details. Food images are uploaded temporarily to analyze calories using AI.\n\n2. Image Usage\nYour food photos are processed securely. We do not sell your photos. Images are stored in your private history until you delete them.\n\n3. Security\nWe use Google Firebase Authentication and Firestore Security Rules to ensure only YOU can access your personal data.\n\n4. Contact\nIf you have questions about your data, please contact the developer via the email button."
            ),
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text("Help & FAQ"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showInfoDialog(
                "Help & FAQ",
                "1. How do I scan a meal?\nGo to the 'Home' tab and tap the '+' button or the 'Scan Meal' button. You can use your camera or pick a photo from your gallery.\n\n2. Is the calorie count 100% accurate?\nFitLens uses advanced AI to estimate calories. While highly accurate, it is an estimation. You can manually edit items if the AI misses something.\n\n3. How do I change my goals?\nGo to the 'Profile' tab and tap 'Personal details' to update your weight, height, or activity level. Your calorie targets will recalculate automatically.\n\n4. Can I delete a meal?\nYes. Go to the 'History' tab, find the meal in the list, and swipe left to delete it."
            ),
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text("Share App"),
            onTap: _shareApp,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.grey),
            title: const Text("Sign Out", style: TextStyle(color: Colors.grey)),
            onTap: _showSignOutDialog,
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text("Delete Account", style: TextStyle(color: Colors.red)),
            onTap: _showDeleteAccountDialog,
          ),
          const SizedBox(height: 20),
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