// lib/screens/onboarding/onboarding_final_result_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database_service.dart';
import '../../utils/calculator.dart'; // ✅ Using the new Brain
import '../main_screen.dart';
import '../../widgets/onboarding_card.dart';

class OnboardingFinalResultScreen extends StatefulWidget {
  final String gender;
  final int age;
  final double weightVal;
  final String weightUnit;
  final double heightVal;
  final String heightUnit;
  final String goal;
  final String mealFrequency;
  final String weekendHabit;
  final String weekendDays;

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

      // 1. Convert units for math (Metric is standard for formulas)
      // If lb -> kg. If cm -> cm.
      int weightKg = widget.weightUnit == 'kg'
          ? widget.weightVal.round()
          : (widget.weightVal / 2.20462).round();

      int heightCm = widget.heightUnit == 'cm'
          ? widget.heightVal.round()
          : (widget.heightVal * 2.54).round();

      // 2. Calculate BMR (The Base)
      double bmr = Calculator.calculateBMR(
        gender: widget.gender,
        weightKg: weightKg,
        heightCm: heightCm,
        age: widget.age,
      );

      // 3. Activity Level
      // For now, we assume "Moderate" (1.375) as a safe start for everyone.
      // Later you can add a screen to ask this!
      double activityMultiplier = 1.375;

      // 4. Calculate Total Daily Calories
      double targetCalories = Calculator.calculateTargetCalories(
          bmr,
          activityMultiplier: activityMultiplier
      );

      // 5. Calculate Macros (Based on User Goal)
      // Goals: 'Gain Weight' -> 'muscle', 'Lose Weight' -> 'loss', else 'maintain'
      String macroGoal = 'maintain';
      if (widget.goal.toLowerCase().contains('gain')) macroGoal = 'muscle';
      if (widget.goal.toLowerCase().contains('lose')) macroGoal = 'loss';

      Map<String, double> macros = Calculator.calculateMacros(
          targetCalories,
          goal: macroGoal
      );

      // 6. Calculate Water Need
      double waterLiter = Calculator.calculateWater(
        weightKg: weightKg,
        exerciseHours: 0.5, // Assuming 30 mins average activity
      );

      // 7. Pack it all into a Map for the Database
      // Note: We round numbers to make them clean (e.g., 2200 instead of 2200.45)
      Map<String, int> dailyGoals = {
        'calories': targetCalories.round(),
        'protein': macros['protein']!.round(),
        'carb': macros['carb']!.round(),
        'fat': macros['fat']!.round(),
        'water': (waterLiter * 1000).round(), // Store as mL (e.g., 2500 ml)
      };

      // 8. Save EVERYTHING to Firestore
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
        activityLevel: "Moderate", // Saving the string for display
        dailyGoals: dailyGoals, // ✅ SAVING THE CALCULATED MATH!
      );

      // 9. Navigate to the Main Dashboard
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      print("Error saving profile: $e"); // Debug print
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

                _buildDynamicChart(),

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

  Widget _buildDynamicChart() {
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
            color: isHighlight ? mainTextColor : inactiveBarColor,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        SizedBox(height: 10),
        Text(
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