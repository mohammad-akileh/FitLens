// lib/screens/onboarding/onboarding_final_result_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/database_service.dart';
import '../../utils/calculator.dart';
import '../../auth_gate.dart';
// Note: We don't need to import onboarding_card.dart here since we use MacroCard

class OnboardingFinalResultScreen extends StatefulWidget {
  final String gender;
  final int age;
  final double weightVal;
  final String weightUnit;
  final double heightVal;
  final String heightUnit;
  final String goal;

  // New Params
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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  final Color primaryGreen = const Color(0xFF5F7E5B);
  final Color bgCream = const Color(0xFFF6F5F0);

  int _targetCalories = 0;
  int _targetProtein = 0;
  int _targetCarbs = 0;
  int _targetFat = 0;

  @override
  void initState() {
    super.initState();
    _calculateValues();
  }

  void _calculateValues() {
    // 1. Convert to Metric
    double weightKg = widget.weightUnit.toLowerCase() == 'kg'
        ? widget.weightVal
        : widget.weightVal * 0.453592;

    double heightCm = widget.heightUnit.toLowerCase() == 'cm'
        ? widget.heightVal
        : widget.heightVal * 30.48;

    // 2. Calculate BMR
    double bmr = Calculator.calculateBMR(
      isMale: widget.gender == 'Male',
      weightKg: weightKg,
      heightCm: heightCm,
      age: widget.age,
    );

    // 3. Default Activity (1.375)
    double activityMultiplier = 1.375;

    double tdee = bmr * activityMultiplier;
    double adjusted = tdee;

    if (widget.goal == "Lose Weight") adjusted -= 500;
    if (widget.goal == "Gain Muscle") adjusted += 500;

    _targetCalories = adjusted.round();
    _targetProtein = ((_targetCalories * 0.30) / 4).round();
    _targetCarbs = ((_targetCalories * 0.35) / 4).round();
    _targetFat = ((_targetCalories * 0.35) / 9).round();
  }

  Future<void> _finishAndSave() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Prepare metric values for saving
        double weightKg = widget.weightUnit.toLowerCase() == 'kg'
            ? widget.weightVal
            : widget.weightVal * 0.453592;

        double heightCm = widget.heightUnit.toLowerCase() == 'cm'
            ? widget.heightVal
            : widget.heightVal * 30.48;

        // 💾 SAVE EVERYTHING TO FIRESTORE (Including Units!)
        await _firestore.collection('users').doc(user.uid).update({
          'gender': widget.gender,
          'age': widget.age,
          'weight': weightKg,
          'weight_unit': widget.weightUnit, // 🟢 SAVING UNIT
          'height': heightCm,
          'height_unit': widget.heightUnit, // 🟢 SAVING UNIT
          'goal': widget.goal,
          'activity_level': 1.375, // Default activity number

          'meal_frequency': widget.mealFrequency,
          'weekend_habit': widget.weekendHabit,
          'weekend_days': widget.weekendDays,

          'target_calories': _targetCalories,
          'target_protein': _targetProtein,
          'target_carbs': _targetCarbs,
          'target_fat': _targetFat,

          'onboarding_completed': true,
          'updated_at': FieldValue.serverTimestamp(),
        });

        await DatabaseService().updateWaterIntake(user.uid, 0);
      }

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => AuthGate()),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text("Your Personal Plan", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF5F7E5B))),
              const SizedBox(height: 10),
              const Text("Based on your details, here is your daily target:", style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 30),

              // Calorie Bubble
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Column(
                  children: [
                    Text("$_targetCalories", style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: primaryGreen)),
                    const Text("kcal / day", style: TextStyle(fontSize: 16, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Macros
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  MacroCard(title: "Protein", value: "${_targetProtein}g", icon: Icons.fitness_center),
                  MacroCard(title: "Carbs", value: "${_targetCarbs}g", icon: Icons.rice_bowl),
                  MacroCard(title: "Fats", value: "${_targetFat}g", icon: Icons.opacity),
                ],
              ),

              const Spacer(),

              // Finish Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _finishAndSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 5,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Start My Journey", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// --- LOCAL WIDGET ---
class MacroCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const MacroCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF5F7E5B), size: 28),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}