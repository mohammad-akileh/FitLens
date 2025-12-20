// lib/screens/onboarding/onboarding_meal_frequency_screen.dart
import 'package:flutter/material.dart';
import '../../widgets/onboarding_card.dart';
import 'onboarding_weekend_habit_screen.dart'; // <-- POINTS TO NEXT SCREEN

class OnboardingMealFrequencyScreen extends StatefulWidget {
  // Receive ALL previous data
  final String gender;
  final int age;
  final double weightVal;
  final String weightUnit;
  final double heightVal;
  final String heightUnit;
  final String goal;

  const OnboardingMealFrequencyScreen({
    super.key,
    required this.gender,
    required this.age,
    required this.weightVal,
    required this.weightUnit,
    required this.heightVal,
    required this.heightUnit,
    required this.goal,
  });

  @override
  State<OnboardingMealFrequencyScreen> createState() => _OnboardingMealFrequencyScreenState();
}

class _OnboardingMealFrequencyScreenState extends State<OnboardingMealFrequencyScreen> {
  final Color mainTextColor = const Color(0xFF5F7E5B);
  final Color buttonColor = const Color(0xFFDFE2D1);

  String? _selectedFrequency;
  final List<String> _options = [
    "2 meals per day",
    "3 meals per day",
    "4 meals per day",
    "5 meals per day",
    "6 meals per day",
  ];

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
            top: 50, left: 20,
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
                  "How many meals do you eat in a typical day?",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                SizedBox(height: 30),

                // Generate List of Options
                ..._options.map((option) => Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: _buildOptionButton(option),
                )).toList(),

                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_selectedFrequency != null) {
                        // --- NAVIGATE TO WEEKEND HABIT SCREEN ---
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OnboardingWeekendHabitScreen(
                              gender: widget.gender,
                              age: widget.age,
                              weightVal: widget.weightVal,
                              weightUnit: widget.weightUnit,
                              heightVal: widget.heightVal,
                              heightUnit: widget.heightUnit,
                              goal: widget.goal,
                              mealFrequency: _selectedFrequency!, // Pass new data
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please select an option"), backgroundColor: Colors.red));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 2,
                    ),
                    child: Text("Continue", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(String label) {
    bool isSelected = _selectedFrequency == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFrequency = label),
      child: Container(
        height: 60,
        padding: EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? mainTextColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [BoxShadow(color: mainTextColor.withOpacity(0.2), blurRadius: 8, offset: Offset(0, 4))] : [],
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
        ),
      ),
    );
  }
}