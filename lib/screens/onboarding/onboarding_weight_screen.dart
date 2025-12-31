// lib/screens/onboarding/onboarding_weight_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_ruler_picker/flutter_ruler_picker.dart';
import '../../widgets/onboarding_card.dart';
import 'onboarding_height_screen.dart';

class OnboardingWeightScreen extends StatefulWidget {
  final String gender;
  final int age;
  const OnboardingWeightScreen({super.key, required this.gender, required this.age});

  @override
  State<OnboardingWeightScreen> createState() => _OnboardingWeightScreenState();
}

class _OnboardingWeightScreenState extends State<OnboardingWeightScreen> {
  final Color mainTextColor = const Color(0xFF5F7E5B);
  final Color buttonColor = const Color(0xFFDFE2D1);

  RulerPickerController? _rulerPickerController;
  bool _isKg = true;
  double _currentWeightVal = 60.0;

  @override
  void initState() {
    super.initState();
    _rulerPickerController = RulerPickerController(value: _currentWeightVal);
  }

  // --- VALIDATION ---
  void _nextPage() {
    bool isValid = true;
    if (_isKg) {
      if (_currentWeightVal < 30 || _currentWeightVal > 300) isValid = false;
    } else {
      if (_currentWeightVal < 66 || _currentWeightVal > 660) isValid = false;
    }

    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a valid weight (${_isKg ? '30-300 kg' : '66-660 lbs'})"), backgroundColor: Colors.red),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OnboardingHeightScreen(
          gender: widget.gender,
          age: widget.age,
          weightVal: _currentWeightVal,
          weightUnit: _isKg ? 'kg' : 'lbs',
        ),
      ),
    );
  }

  void _toggleUnit(bool makingKg) {
    if (_isKg == makingKg) return;
    setState(() {
      _isKg = makingKg;
      if (_isKg) {
        _currentWeightVal = _currentWeightVal * 0.453592; // Lbs -> Kg
      } else {
        _currentWeightVal = _currentWeightVal * 2.20462; // Kg -> Lbs
      }
    });
    // Update ruler position safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_rulerPickerController != null) {
        _rulerPickerController!.value = _currentWeightVal;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFE2D1),
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
              mainAxisSize: MainAxisSize.min, // shrink to fit children
              children: [
                const Text(
                  "What's your weight?",
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
                      _buildToggleButton("Kg", _isKg, () => _toggleUnit(true)),
                      _buildToggleButton("Lbs", !_isKg, () => _toggleUnit(false)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: _currentWeightVal.toStringAsFixed(1),
                        style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: mainTextColor),
                      ),
                      TextSpan(
                        text: " ${_isKg ? 'Kg' : 'Lbs'}",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: mainTextColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // --- FIXED: SizedBox instead of Expanded & Custom Marker ---
                SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: RulerPicker(
                    controller: _rulerPickerController!,
                    onBuildRulerScaleText: (index, value) => value.toInt().toString(),
                    ranges: const [
                      RulerRange(begin: 0, end: 700, scale: 1),
                    ],
                    scaleLineStyleList: const [
                      ScaleLineStyle(color: Colors.grey, width: 1.5, height: 30, scale: 0),
                      ScaleLineStyle(color: Colors.grey, width: 1, height: 15, scale: 5),
                      ScaleLineStyle(color: Colors.grey, width: 1, height: 15, scale: -1),
                    ],
                    onValueChanged: (value) {
                      setState(() => _currentWeightVal = value.toDouble());
                    },
                    width: MediaQuery.of(context).size.width,
                    height: 150,
                    rulerMarginTop: 8,
                    // 🎨 CUSTOM GREEN MARKER ADDED HERE
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