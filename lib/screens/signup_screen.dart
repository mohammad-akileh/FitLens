// lib/screens/signup_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordObscured = true;
  bool _isLoading = false;

  // Colors
  final Color mainTextColor = const Color(0xFF5F7E5B);
  final Color buttonColor = const Color(0xFFF6F5F0);
  final Color screenBgColor = const Color(0xFFDFE2D1);

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // --- 🛡️ PROFESSIONAL EMAIL VALIDATOR ---
  String? _validateEmailSpecifics(String email) {
    if (email.isEmpty) return "Email address is required.";
    if (email.contains(' ')) return "Email address cannot contain spaces.";

    // 1. Check for '@'
    if (!email.contains('@')) return "Invalid format: Missing '@' symbol.";

    // Split into Local (before @) and Domain (after @)
    final parts = email.split('@');
    if (parts.length > 2) return "Invalid format: Multiple '@' symbols found.";

    final localPart = parts[0];
    final domainPart = parts.length > 1 ? parts[1] : "";

    // 2. Check Local Part
    if (localPart.isEmpty) return "Invalid format: Username before '@' is missing.";

    // 3. Check Domain Part
    if (domainPart.isEmpty) return "Invalid format: Domain after '@' is missing.";

    // 4. Check for dot '.' in domain
    if (!domainPart.contains('.')) return "Invalid domain: Missing a dot ('.') separator.";

    // 5. Check TLD (The part after the last dot, e.g., 'com', 'org', 'duck')
    final domainSegments = domainPart.split('.');
    final tld = domainSegments.last;
    if (tld.isEmpty || tld.length < 2) {
      return "Invalid domain: Top-level domain (e.g., .com) is incomplete.";
    }

    // 6. Final Regex Check for weird characters
    // Allows alphanumeric, dots, underscores, hyphens.
    // Example: user.name@domain-name.co.uk is valid.
    final RegExp emailRegex = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9-]+\.[a-zA-Z]+",
    );
    if (!emailRegex.hasMatch(email)) {
      return "Invalid email format. Please check for special characters.";
    }

    return null; // No error
  }

  void _signUp() async {
    setState(() { _isLoading = true; });

    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    // 1. Validate Name
    if (!RegExp(r'^[a-zA-Z]+$').hasMatch(name)) {
      _showErrorSnackBar("Name must be one word, letters only.");
      setState(() { _isLoading = false; });
      return;
    }

    // 2. 🛡️ NEW EMAIL CHECK
    String? emailError = _validateEmailSpecifics(email);
    if (emailError != null) {
      _showErrorSnackBar(emailError);
      setState(() { _isLoading = false; });
      return; // Stop here
    }

    // 3. Password Check
    RegExp strongPasswordRegex = RegExp(r'^(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#\$&*~]).{8,}$');
    if (!strongPasswordRegex.hasMatch(password)) {
      _showErrorSnackBar("Password must be 8+ chars, with 1 Uppercase, 1 Number & 1 Symbol (!@#\$&*)");
      setState(() { _isLoading = false; });
      return;
    }

    try {
      await _authService.signUpWithEmail(name, email, password);

      setState(() { _isLoading = false; });

      // 🔔 SHOW DIALOG INSTEAD OF JUST SNACKBAR
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Success! 📧", style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text(
              "We sent a verification email to your inbox.\n\n"
                  "⚠️ IMPORTANT: If you don't see it, please CHECK YOUR SPAM OR JUNK FOLDER.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to login
                },
                child: const Text("OK, I'll check"),
              ),
            ],
          ),
        );
      }

    } on FirebaseAuthException catch (e) {
      setState(() { _isLoading = false; });
      _showErrorSnackBar(e.message ?? "An error occurred.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: screenBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: mainTextColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  "Create Account",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
              SizedBox(height: 40),

              _buildModernTextField(
                controller: _nameController,
                hint: "Name",
                icon: Icons.person_outline,
                formatter: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]'))],
              ),
              SizedBox(height: 15),

              _buildModernTextField(
                controller: _emailController,
                hint: "Email Address",
                icon: Icons.email_outlined,
              ),
              SizedBox(height: 15),

              _buildModernTextField(
                controller: _passwordController,
                hint: "Password",
                icon: Icons.lock_outline,
                isObscured: _isPasswordObscured,
                suffixIcon: IconButton(
                  icon: Icon(_isPasswordObscured ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                  onPressed: () => setState(() => _isPasswordObscured = !_isPasswordObscured),
                ),
              ),

              SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF8B8BAE),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Sign Up", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isObscured = false,
    Widget? suffixIcon,
    List<TextInputFormatter>? formatter,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscured,
      inputFormatters: formatter,
      style: TextStyle(color: mainTextColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: mainTextColor.withOpacity(0.6), fontSize: 14),
        prefixIcon: Icon(icon, color: mainTextColor, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.black, width: 1),
        ),
      ),
    );
  }
}