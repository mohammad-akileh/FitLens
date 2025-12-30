// lib/screens/forgot_password_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  // --- YOUR NEW COLORS ---
  final Color mainTextColor = const Color(0xFF5F7E5B);
  final Color buttonColor = const Color(0xFFF6F5F0);
  final Color screenBgColor = const Color(0xFFDFE2D1);

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
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

    // 5. Check TLD (The part after the last dot)
    final domainSegments = domainPart.split('.');
    final tld = domainSegments.last;
    if (tld.isEmpty || tld.length < 2) {
      return "Invalid domain: Top-level domain (e.g., .com) is incomplete.";
    }

    // 6. Final Regex Check
    final RegExp emailRegex = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9-]+\.[a-zA-Z]+",
    );
    if (!emailRegex.hasMatch(email)) {
      return "Invalid email format. Please check for special characters.";
    }

    return null; // No error
  }

  void _sendResetLink() async {
    setState(() { _isLoading = true; });

    // 1. 🛡️ VALIDATE EMAIL FIRST
    String? emailError = _validateEmailSpecifics(_emailController.text.trim());
    if (emailError != null) {
      _showSnackBar(emailError, isError: true);
      setState(() { _isLoading = false; });
      return;
    }

    try {
      await _authService.sendPasswordResetEmail(_emailController.text.trim());
      _showSnackBar("Password reset link sent! Check your inbox.");
      if (mounted) Navigator.pop(context); // Go back to login
    } on FirebaseAuthException catch (e) {
      String errorMessage = "No user found for that email.";
      _showSnackBar(errorMessage, isError: true);
    } finally {
      if (mounted) setState(() { _isLoading = false; });
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
            children: [
              Text(
                "Reset Password",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 15),
              Text(
                "Enter your email and we'll send you a link to reset your password.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: mainTextColor.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 40),

              // Email Field
              TextField(
                controller: _emailController,
                style: TextStyle(color: mainTextColor),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "Enter email",
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[400], size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: mainTextColor, width: 1),
                  ),
                ),
              ),

              SizedBox(height: 30),

              // Send Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _sendResetLink,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF8B8BAE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                    "Send Reset Link",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}