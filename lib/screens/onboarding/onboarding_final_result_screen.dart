// lib/screens/onboarding/onboarding_final_result_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database_service.dart';
import '../../services/calculator_service.dart';
import '../home_screen.dart';
import '../../widgets/onboarding_card.dart';
import '../main_screen.dart';

class OnboardingFinalResultScreen extends StatefulWidget {
  final String gender;
  final int age;
  final double weightVal;
  final String weightUnit;
  final double heightVal;
  final String heightUnit;
  final String goal;
  final String mealFrequency;
  final String weekendHabit; // "Yes" or "No"
  final String weekendDays;  // "Fridays and Saturdays", etc.

  const OnboardingFinalResultScreen({
    super.key,
    required this.gender,
    required this.age,
    required this.weightVal,
    required this.weightUnit,
    required this.heightVal,
    required this.heightUnit,
    required this.goal,
    required this.mealFrequency,
    required this.weekendHabit,
    required this.weekendDays,
  });

  @override
  State<OnboardingFinalResultScreen> createState() => _OnboardingFinalResultScreenState();
}

class _OnboardingFinalResultScreenState extends State<OnboardingFinalResultScreen> {
  final Color mainTextColor = const Color(0xFF5F7E5B);
  final Color buttonColor = const Color(0xFFDFE2D1);
  final Color inactiveBarColor = Colors.grey[300]!;

  bool _isLoading = false;

  Future<void> _finishAndSave() async {
    setState(() => _isLoading = true);
    try {
      final String uid = FirebaseAuth.instance.currentUser!.uid;
      final CalculatorService calculator = CalculatorService();

      // 1. Convert units for math (Metric is standard for BMR formulas)
      double weightKg = widget.weightUnit == 'kg' ? widget.weightVal : widget.weightVal / 2.20462;
      double heightCm = widget.heightUnit == 'cm' ? widget.heightVal : widget.heightVal * 2.54;

      // 2. Calculate BMR (Base Metabolic Rate)
      double bmr = calculator.calculateBMR(
        gender: widget.gender,
        weightKg: weightKg,
        heightCm: heightCm,
        age: widget.age,
      );

      String activityLevel = "Moderate"; // Defaulting to Moderate for now

      // 3. Calculate Targets (The "Math" part!)
      // This creates the map: {'calories': 2200, 'protein': 150, ...}
      Map<String, int> dailyGoals = calculator.calculateDailyGoals(
        bmr: bmr,
        activityLevel: activityLevel,
        goal: widget.goal, // <--- PASS THE GOAL HERE!
      );

      // 4. Save EVERYTHING to Firestore
      await DatabaseService().saveUserProfile(
        uid: uid,
        gender: widget.gender,
        age: widget.age,
        weight: widget.weightVal,
        weightUnit: widget.weightUnit,
        height: widget.heightVal,
        heightUnit: widget.heightUnit,
        goal: widget.goal,
        mealFrequency: widget.mealFrequency,
        snackHabit: widget.weekendHabit,
        weekendHabit: widget.weekendDays,
        activityLevel: activityLevel,
        // --- THIS IS THE NEW PART ---
        dailyGoals: dailyGoals, // Passing the calculated targets to be saved!
      );

      // 5. Navigate to the Main Dashboard
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
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
              children: [
                Text(
                  "We'll tailor your plan!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                SizedBox(height: 10),
                Text(
                  "Based on your habits, here is how we structure your week.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                SizedBox(height: 40),

                // --- SMART CHART WIDGET ---
                _buildDynamicChart(),
                // --------------------------

                SizedBox(height: 40),

                Text(
                  "Your calorie budget will be flexibly adjusted for weekends so you can enjoy them guilt-free!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
                ),

                SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _finishAndSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.black)
                        : Text("Finish Setup", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- THE NEW LOGIC IS HERE ---
  Widget _buildDynamicChart() {
    // 1. Analyze the user's choice
    bool friHigh = widget.weekendDays.contains("Fridays");
    bool satHigh = widget.weekendDays.contains("Saturdays");
    bool sunHigh = widget.weekendDays.contains("Sundays");

    return Container(
      height: 180,
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildSingleBar("M", 0.6, false),
          _buildSingleBar("T", 0.6, false),
          _buildSingleBar("W", 0.6, false),
          _buildSingleBar("T", 0.6, false),

          // 2. Pass the True/False logic to the bars
          _buildSingleBar("F", friHigh ? 0.9 : 0.6, friHigh),
          _buildSingleBar("S", satHigh ? 1.0 : 0.6, satHigh),
          _buildSingleBar("S", sunHigh ? 1.0 : 0.6, sunHigh),
        ],
      ),
    );
  }

  Widget _buildSingleBar(String day, double heightFactor, bool isHighlight) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AnimatedContainer(
          duration: Duration(milliseconds: 500),
          height: 120 * heightFactor,
          width: 20,
          decoration: BoxDecoration(
            color: isHighlight ? mainTextColor : inactiveBarColor, // Highlight color logic
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        SizedBox(height: 10),
        Text(//m,26,72,180,gain,5,no,1
          day,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isHighlight ? mainTextColor : Colors.grey,
          ),
        ),
      ],
    );
  }
}