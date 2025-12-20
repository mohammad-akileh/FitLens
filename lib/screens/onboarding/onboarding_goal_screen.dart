// lib/screens/onboarding/onboarding_goal_screen.dart
import 'package:flutter/material.dart';
import '../../widgets/onboarding_card.dart';
import 'onboarding_meal_frequency_screen.dart'; // <-- POINTS TO NEXT SCREEN

class OnboardingGoalScreen extends StatefulWidget {
  final String gender;
  final int age;
  final double weightVal;
  final String weightUnit;
  final double heightVal;
  final String heightUnit;

  const OnboardingGoalScreen({
    super.key,
    required this.gender,
    required this.age,
    required this.weightVal,
    required this.weightUnit,
    required this.heightVal,
    required this.heightUnit,
  });

  @override
  State<OnboardingGoalScreen> createState() => _OnboardingGoalScreenState();
}

class _OnboardingGoalScreenState extends State<OnboardingGoalScreen> {
  final Color mainTextColor = const Color(0xFF5F7E5B);
  final Color buttonColor = const Color(0xFFDFE2D1);
  String? _selectedGoal;

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
                  "What goal do you have in mind?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "We'll use it to personalize your plan.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                SizedBox(height: 30),

                // Goal Buttons (Make sure these images are in assets!)
                _buildGoalButton("Lose weight", "assets/goal_lose.jpg"),
                SizedBox(height: 15),
                _buildGoalButton("Maintain weight", "assets/goal_maintain.jpg"),
                SizedBox(height: 15),
                _buildGoalButton("Gain weight", "assets/goal_gain.jpg"),

                SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_selectedGoal != null) {
                        // --- NAVIGATE TO MEAL FREQUENCY SCREEN ---
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OnboardingMealFrequencyScreen(
                              gender: widget.gender,
                              age: widget.age,
                              weightVal: widget.weightVal,
                              weightUnit: widget.weightUnit,
                              heightVal: widget.heightVal,
                              heightUnit: widget.heightUnit,
                              goal: _selectedGoal!, // Pass the new goal data
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Please select a goal"), backgroundColor: Colors.red),
                        );
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

  Widget _buildGoalButton(String label, String imagePath) {
    bool isSelected = _selectedGoal == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGoal = label;
        });
      },
      child: Container(
        height: 70,
        padding: EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? mainTextColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: mainTextColor.withOpacity(0.2), blurRadius: 8, offset: Offset(0, 4))]
              : [],
        ),
        child: Row(
          children: [
            // Ensure you have these assets or replace with Icons for testing
            Image.asset(imagePath, width: 40, height: 40),
            SizedBox(width: 20),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Spacer(),
            Container(
              height: 24,
              width: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? mainTextColor : Colors.grey[400]!,
                  width: 2,
                ),
                color: isSelected ? mainTextColor : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}