import 'package:flutter/material.dart';
import 'package:flutter_ruler_picker/flutter_ruler_picker.dart';
import '../../widgets/onboarding_card.dart';
import 'onboarding_goal_screen.dart';

class OnboardingHeightScreen extends StatefulWidget {
  final String gender;
  final int age;
  final double weightVal;
  final String weightUnit;

  const OnboardingHeightScreen({
    super.key,
    required this.gender,
    required this.age,
    required this.weightVal,
    required this.weightUnit,
  });

  @override
  State<OnboardingHeightScreen> createState() => _OnboardingHeightScreenState();
}

class _OnboardingHeightScreenState extends State<OnboardingHeightScreen> {
  final Color mainTextColor = const Color(0xFF5F7E5B);
  final Color buttonColor = const Color(0xFFDFE2D1);

  RulerPickerController? _rulerPickerController;
  bool _isCm = true;
  double _currentHeightCm = 170.0;

  @override
  void initState() {
    super.initState();
    _rulerPickerController = RulerPickerController(value: _currentHeightCm);
  }

  // --- VALIDATION ---
  void _nextPage() {
    bool isValid = true;
    if (_currentHeightCm < 50 || _currentHeightCm > 300) {
      isValid = false;
    }

    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid height (50-300 cm or 1.6-9.8 ft)"), backgroundColor: Colors.red),
      );
      return;
    }

    double finalHeightVal;
    String finalHeightUnit;

    if (_isCm) {
      finalHeightVal = _currentHeightCm;
      finalHeightUnit = 'cm';
    } else {
      double inches = _currentHeightCm / 2.54;
      finalHeightVal = inches / 12; // Convert to feet
      finalHeightUnit = 'ft';
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OnboardingGoalScreen(
          gender: widget.gender,
          age: widget.age,
          weightVal: widget.weightVal,
          weightUnit: widget.weightUnit,
          heightVal: finalHeightVal,
          heightUnit: finalHeightUnit,
        ),
      ),
    );
  }

  void _toggleUnit(bool makingCm) {
    if (_isCm == makingCm) return;
    setState(() => _isCm = makingCm);
  }

  String _getFormattedHeight() {
    if (_isCm) {
      return _currentHeightCm.toStringAsFixed(0);
    } else {
      double totalInches = _currentHeightCm / 2.54;
      int feet = (totalInches / 12).floor();
      int inches = (totalInches % 12).round();
      return "$feet' $inches\"";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/intro_back.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.8),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: mainTextColor),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          OnboardingCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "How tall are you?",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 15),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildToggleButton("cm", _isCm, () => _toggleUnit(true)),
                      _buildToggleButton("ft", !_isCm, () => _toggleUnit(false)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: _getFormattedHeight(),
                        style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: mainTextColor),
                      ),
                      if (_isCm)
                        TextSpan(
                          text: " cm",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: mainTextColor),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // --- FIXED: SizedBox instead of Expanded & .toDouble() ---
                SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: RulerPicker(
                    controller: _rulerPickerController!,
                    onBuildRulerScaleText: (index, value) => value.toInt().toString(),
                    ranges: const [
                      RulerRange(begin: 0, end: 350, scale: 1),
                    ],
                    scaleLineStyleList: const [
                      ScaleLineStyle(color: Colors.grey, width: 1.5, height: 30, scale: 0),
                      ScaleLineStyle(color: Colors.grey, width: 1, height: 15, scale: 5),
                      ScaleLineStyle(color: Colors.grey, width: 1, height: 15, scale: -1),
                    ],
                    // 🛡️ FIX HERE: Cast 'num' to 'double'
                    onValueChanged: (value) {
                      setState(() => _currentHeightCm = value.toDouble());
                    },
                    width: MediaQuery.of(context).size.width,
                    height: 150,
                    rulerMarginTop: 8,
                    marker: Container(
                      width: 4,
                      height: 50,
                      decoration: BoxDecoration(
                        color: mainTextColor, // Use your Green color
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 2,
                    ),
                    child: const Text("Continue", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          boxShadow: isActive ? [const BoxShadow(color: Colors.black12, blurRadius: 5)] : [],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isActive ? mainTextColor : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}