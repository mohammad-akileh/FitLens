// lib/screens/onboarding/onboarding_weekend_habit_screen.dart
import 'package:flutter/material.dart';
import '../../widgets/onboarding_card.dart';
import 'onboarding_weekend_days_screen.dart'; // Next Screen

class OnboardingWeekendHabitScreen extends StatefulWidget {
  // Pass all previous data... (I'll keep this short, but you need ALL variables)
  final String gender;
  final int age;
  final double weightVal;
  final String weightUnit;
  final double heightVal;
  final String heightUnit;
  final String goal;
  final String mealFrequency;

  const OnboardingWeekendHabitScreen({
    super.key,
    required this.gender,
    required this.age,
    required this.weightVal,
    required this.weightUnit,
    required this.heightVal,
    required this.heightUnit,
    required this.goal,
    required this.mealFrequency,
  });

  @override
  State<OnboardingWeekendHabitScreen> createState() =>
      _OnboardingWeekendHabitScreenState();
}

class _OnboardingWeekendHabitScreenState
    extends State<OnboardingWeekendHabitScreen> {
  final Color mainTextColor = const Color(0xFF5F7E5B);
  final Color buttonColor = const Color(0xFFDFE2D1);
  String? _selectedHabit; // "Yes" or "No"

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
              decoration: BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage('assets/intro_back.jpg'),
                      fit: BoxFit.cover))),
          Positioned(
              top: 50,
              left: 20,
              child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.8),
                  child: IconButton(
                      icon: Icon(Icons.arrow_back, color: mainTextColor),
                      onPressed: () => Navigator.pop(context)))),
          OnboardingCard(
            child: Column(
              children: [
                Text("Do you eat a bit more on weekends?",
                    textAlign: TextAlign.center,
                    style:
                TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 30),
                _buildOptionButton("Yes", Icons.check_circle_outline),
                SizedBox(height: 15),
                _buildOptionButton("No", Icons.cancel_outlined),
                SizedBox(height: 30),
                SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_selectedHabit != null) {
                          // Logic: If Yes -> Ask Which Days. If No -> Skip to Finish?
                          // For now, let's assume we go to the Days screen regardless, or you can add logic here.
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      OnboardingWeekendDaysScreen(
                                        // Pass all data...
                                        gender: widget.gender,
                                        age: widget.age,
                                        weightVal: widget.weightVal,
                                        weightUnit: widget.weightUnit,
                                        heightVal: widget.heightVal,
                                        heightUnit: widget.heightUnit,
                                        goal: widget.goal,
                                        mealFrequency: widget.mealFrequency,
                                        weekendHabit: _selectedHabit!,
                                      )));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30))),
                      child: Text("Continue",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(String label, IconData icon) {
    bool isSelected = _selectedHabit == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedHabit = label),
      child: Container(
        height: 70,
        padding: EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
                color: isSelected ? mainTextColor : Colors.grey[300]!,
                width: 2)),
        child: Row(children: [
          Icon(icon, color: isSelected ? mainTextColor : Colors.grey, size: 30),
          SizedBox(width: 15),
          Text(label,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}
