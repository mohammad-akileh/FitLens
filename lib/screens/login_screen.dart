// lib/screens/login_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordObscured = true;
  bool _rememberMe = true;

  // --- YOUR NEW COLORS ---
  final Color mainTextColor = const Color(0xFF5F7E5B); // Deep Sage
  final Color buttonColor = const Color(0xFFF6F5F0);   // Cream
  final Color screenBgColor = const Color(0xFFDFE2D1); // Light Sage

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _login() async {
    setState(() { _isLoading = true; });
    try {
      await _authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (mounted) setState(() { _isLoading = false; });
    } on FirebaseAuthException catch (e) {
      setState(() { _isLoading = false; });

      String errorMessage;
      // Check for the new generic error code 'invalid-credential'
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

  void _loginWithGoogle() async {
    setState(() { _isLoading = true; });
    try {
      await _authService.signInWithGoogle();
      if (mounted) setState(() { _isLoading = false; });
    } on FirebaseAuthException catch (e) {
      setState(() { _isLoading = false; });
      _showErrorSnackBar(e.message ?? "An error occurred.");
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
              SizedBox(height: 8),
              Center(
                child: Text(
                  "Ready to continue your health journey?",
                  style: TextStyle(fontSize: 14, color: mainTextColor.withOpacity(0.8)),
                ),
              ),
              SizedBox(height: 40),

              _buildModernTextField(
                controller: _emailController,
                hint: "Enter email",
                icon: Icons.email_outlined,
              ),
              SizedBox(height: 15),

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
                      SizedBox(width: 8),
                      Text("Remember me", style: TextStyle(fontSize: 13, color: mainTextColor)),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ForgotPasswordScreen()));
                    },
                    child: Text("Forgot password?", style: TextStyle(fontSize: 13, color: mainTextColor, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor, // #F6F5F0
                    foregroundColor: mainTextColor, // #5F7E5B
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: mainTextColor)
                      : Text("Log In", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),

              SizedBox(height: 30),

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

              SizedBox(height: 20),

              // Google Button
              Center(child: _buildSocialButton(onPressed: _loginWithGoogle, assetName: 'assets/google_icon.png')),

              SizedBox(height: 40),

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
      style: TextStyle(color: mainTextColor), // Input text color
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: mainTextColor.withOpacity(0.6), fontSize: 14), // Hint color
        prefixIcon: Icon(icon, color: mainTextColor, size: 20), // Icon color
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
          borderSide: BorderSide(color: mainTextColor, width: 1),
        ),
      ),
    );
  }

  Widget _buildSocialButton({required VoidCallback onPressed, required String assetName}) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 5))],
        ),
        child: Image.asset(assetName, height: 30, width: 30),
      ),
    );
  }
}