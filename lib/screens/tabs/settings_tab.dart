// lib/screens/tabs/settings_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  bool isDarkMode = false; // Just a dummy switch for now

  // 👇 FUNCTION TO FORCE PERMISSION & SHOW NOTIFICATION
  Future<void> _testNotification() async {
    // 1. Force ask permission (even if denied before, this tries to wake it up)
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
    FlutterLocalNotificationsPlugin().resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.requestNotificationsPermission();

    // 2. Fire the test!
    await NotificationService.showWarning(
        "🦅 Test Successful!",
        "If you can read this, notifications are working perfectly."
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F5F0), // Cream background
      appBar: AppBar(
        title: const Text(
            "Settings",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Preferences", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // 🌙 Dark Mode (Visual Only)
            _buildSettingTile(
              icon: Icons.dark_mode,
              color: Colors.purple,
              title: "Dark Mode",
              trailing: Switch(
                activeColor: const Color(0xFF5F7E5B),
                value: isDarkMode,
                onChanged: (val) {
                  setState(() => isDarkMode = val);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Theme switching coming soon!"))
                  );
                },
              ),
            ),

            const SizedBox(height: 30),
            const Text("Debugging", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // 🔔 TEST NOTIFICATION BUTTON (THE ONE YOU WANTED)
            _buildSettingTile(
              icon: Icons.notifications_active,
              color: Colors.orange,
              title: "Test Notification",
              subtitle: "Click to verify alerts work",
              onTap: _testNotification, // 👈 Calls our function
            ),

            const SizedBox(height: 30),
            const Text("Account", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // 🚪 Logout
            _buildSettingTile(
              icon: Icons.logout,
              color: Colors.red,
              title: "Log Out",
              onTap: () async {
                await AuthService().signOut();
              },
            ),

            const SizedBox(height: 10),

            // 🗑️ Delete Account (Placeholder)
            _buildSettingTile(
              icon: Icons.delete_forever,
              color: Colors.grey,
              title: "Delete Account",
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Contact support to delete account."))
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to make tiles look beautiful
  Widget _buildSettingTile({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
          ]
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}