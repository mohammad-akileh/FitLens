import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  bool isDarkMode = false; // Just a toggle for now

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F5F0),
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // 🌙 Dark Mode Switch
          ListTile(
            tileColor: Colors.white,
            leading: const Icon(Icons.dark_mode, color: Color(0xFF5F7E5B)),
            title: const Text("Dark Mode"),
            trailing: Switch(
              activeColor: const Color(0xFF5F7E5B),
              value: isDarkMode,
              onChanged: (val) {
                setState(() => isDarkMode = val);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Theme switching coming soon!")));
              },
            ),
          ),
          const Divider(),
          // 🚪 Logout Button
          ListTile(
            tileColor: Colors.white,
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Log Out", style: TextStyle(color: Colors.red)),
            onTap: () async {
              await AuthService().signOut(); // Calls our fixed logout!
            },
          ),
        ],
      ),
    );
  }
}