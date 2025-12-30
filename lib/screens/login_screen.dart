// lib/screens/login_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Loading state for Email login
  bool _isLoading = false;
  // Loading state for Google login
  bool _isGoogleLoading = false;

  bool _isPasswordObscured = true;
  bool _rememberMe = true;
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

  // --- Email Login Logic ---
  void _login() async {
    setState(() { _isLoading = true; });

    // 1. 🛡️ VALIDATE EMAIL FIRST
    String? emailError = _validateEmailSpecifics(_emailController.text.trim());
    if (emailError != null) {
      _showErrorSnackBar(emailError);
      setState(() { _isLoading = false; });
      return;
    }

    try {
      await _authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      // AuthGate handles navigation. Just stop spinner if still mounted.
      if (mounted) setState(() { _isLoading = false; });
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() { _isLoading = false; });
      String errorMessage;
      if (e.code == 'invalid-credential' || e.code == 'user-not-found' || e.code == 'wrong-password') {
        errorMessage = "Incorrect email or password.";
      } else if (e.code == 'email-not-verified') {
        errorMessage = e.message ?? "Please verify your email.";
      } else {
        errorMessage = e.message ?? "An error occurred.";
      }
      _showErrorSnackBar(errorMessage);
    }
  }

  // --- Google Login Logic ---
  void _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    try {
      await AuthService().signInWithGoogle();
      // AuthGate handles navigation.
    } catch (e) {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
        _showErrorSnackBar("Google Login Failed: ${e.toString()}");
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: screenBgColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  "Welcome Back",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: mainTextColor),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  "Ready to continue your health journey?",
                  style: TextStyle(fontSize: 14, color: mainTextColor.withOpacity(0.8)),
                ),
              ),
              const SizedBox(height: 40),

              _buildModernTextField(
                controller: _emailController,
                hint: "Enter email",
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 15),

              _buildModernTextField(
                controller: _passwordController,
                hint: "Password",
                icon: Icons.lock_outline,
                isObscured: _isPasswordObscured,
                suffixIcon: IconButton(
                  icon: Icon(_isPasswordObscured ? Icons.visibility_off : Icons.visibility, color: mainTextColor),
                  onPressed: () => setState(() => _isPasswordObscured = !_isPasswordObscured),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _rememberMe,
                          activeColor: mainTextColor,
                          checkColor: buttonColor,
                          side: BorderSide(color: mainTextColor),
                          onChanged: (val) => setState(() => _rememberMe = val!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text("Remember me", style: TextStyle(fontSize: 13, color: mainTextColor)),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()));
                    },
                    child: Text("Forgot password?", style: TextStyle(fontSize: 13, color: mainTextColor, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Login Button (Email)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: mainTextColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: mainTextColor)
                      : const Text("Log In", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 30),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: mainTextColor.withOpacity(0.5))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text("Sign in with", style: TextStyle(color: mainTextColor, fontSize: 12)),
                  ),
                  Expanded(child: Divider(color: mainTextColor.withOpacity(0.5))),
                ],
              ),

              const SizedBox(height: 20),

              // --- Google Button ---
              Center(
                child: _isGoogleLoading
                    ? const CircularProgressIndicator()
                    : _buildSocialButton(
                    onPressed: _handleGoogleSignIn,
                    assetName: 'assets/google_icon.png'
                ),
              ),

              const SizedBox(height: 40),

              // Sign Up Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ", style: TextStyle(color: mainTextColor)),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpScreen()));
                    },
                    child: Text("Sign Up", style: TextStyle(color: mainTextColor, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                  ),
                ],
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
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscured,
      style: TextStyle(color: mainTextColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: mainTextColor.withOpacity(0.6), fontSize: 14),
        prefixIcon: Icon(icon, color: mainTextColor, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: mainTextColor, width: 1),
        ),
      ),
    );
  }

  Widget _buildSocialButton({required VoidCallback onPressed, required String assetName}) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Image.asset(assetName, height: 30, width: 30),
      ),
    );
  }
}