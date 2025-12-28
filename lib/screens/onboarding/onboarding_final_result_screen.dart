// lib/screens/onboarding/onboarding_final_result_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Needed for direct updates
import 'package:intl/intl.dart'; // 📦 Run 'flutter pub add intl' if missing!

import '../../services/database_service.dart';
import '../../utils/calculator.dart';
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
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final String uid = user.uid;

      // 1. Convert units for math (Metric is standard for formulas)
      int weightKg = widget.weightUnit == 'kg'
          ? widget.weightVal.round()
          : (widget.weightVal / 2.20462).round();

      int heightCm = widget.heightUnit == 'cm'
          ? widget.heightVal.round()
          : (widget.heightVal * 2.54).round();

      // 2. Calculate BMR
      double bmr = Calculator.calculateBMR(
        gender: widget.gender,
        weightKg: weightKg,
        heightCm: heightCm,
        age: widget.age,
      );

      // 3. Activity Level (Default Moderate)
      double activityMultiplier = 1.375;

      // 4. Calculate Total Daily Calories
      double targetCalories = Calculator.calculateTargetCalories(
          bmr,
          activityMultiplier: activityMultiplier
      );

      // 5. Calculate Macros
      String macroGoal = 'maintain';
      if (widget.goal.toLowerCase().contains('gain')) macroGoal = 'muscle';
      if (widget.goal.toLowerCase().contains('lose')) macroGoal = 'loss';

      Map<String, double> macros = Calculator.calculateMacros(
          targetCalories,
          goal: macroGoal
      );

      // 6. Calculate Water
      double waterLiter = Calculator.calculateWater(
        weightKg: weightKg,
        exerciseHours: 0.5,
      );

      // 7. Pack Targets for Database
      Map<String, int> dailyGoals = {
        'calories': targetCalories.round(),
        'protein': macros['protein']!.round(),
        'carb': macros['carb']!.round(),
        'fat': macros['fat']!.round(),
        'water': (waterLiter * 1000).round(),
      };

      // 8. Save Profile Logic
      // This saves the "Static" info (Age, Gender, Targets)
      await DatabaseService().saveUserProfile(
        uid: uid,
        gender: widget.gender,
        age: widget.age,
        weight: widget.weightVal,
        weightUnit: widget.weightUnit,
        height: widget.heightVal,
        heightUnit: widget.heightUnit,
        goal: widget.goal,
        // Passing these habits to save them, even if DatabaseService doesn't explicitly name them,
        // we will ensure they are saved in the extra update below just in case.
        dailyGoals: dailyGoals,
      );

      // 9. 🛡️ THE SAFETY LOCK (Force Clean Database Structure)
      // This ensures the Home Screen has exactly what it needs to start.
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'onboarding_completed': true,
        'app_secret': 'FitLens_VIP_2025',

        // 📅 THE ANCHOR: Set "Last Active" to TODAY
        'last_active_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),

        // ⚡ LIVE COUNTERS: Start at 0
        'current_calories': 0,
        'current_protein': 0,
        'current_carbs': 0,
        'current_fat': 0,
        'current_water': 0,

        // Habits (Saving them here to be 100% sure they exist)
        'meal_frequency': widget.mealFrequency,
        'weekend_habit': widget.weekendHabit,
        'weekend_days': widget.weekendDays,
      }, SetOptions(merge: true)); // Merge so we don't delete what saveUserProfile just saved

      // 10. Navigate to Main Screen
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      print("Error saving profile: $e");
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
              children: [
                const Text(
                  "We'll tailor your plan!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 10),
                Text(
                  "Based on your habits, here is how we structure your week.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 40),

                _buildDynamicChart(),

                const SizedBox(height: 40),

                const Text(
                  "Your calorie budget will be flexibly adjusted for weekends so you can enjoy them guilt-free!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
                ),

                const SizedBox(height: 40),

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
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text("Finish Setup", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
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
      padding: const EdgeInsets.symmetric(horizontal: 10),
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
          duration: const Duration(milliseconds: 500),
          height: 120 * heightFactor,
          width: 20,
          decoration: BoxDecoration(
            color: isHighlight ? mainTextColor : inactiveBarColor,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 10),
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