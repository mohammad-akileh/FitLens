// lib/screens/onboarding/onboarding_weekend_days_screen.dart
import 'package:flutter/material.dart';
import '../../widgets/onboarding_card.dart';
import 'onboarding_final_result_screen.dart'; // <-- POINTS TO FINAL SCREEN

class OnboardingWeekendDaysScreen extends StatefulWidget {
  // Pass ALL previous data
  final String gender;
  final int age;
  final double weightVal;
  final String weightUnit;
  final double heightVal;
  final String heightUnit;
  final String goal;
  final String mealFrequency;
  final String weekendHabit; // "Yes" or "No"

  const OnboardingWeekendDaysScreen({
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
  });

  @override
  State<OnboardingWeekendDaysScreen> createState() => _OnboardingWeekendDaysScreenState();
}

class _OnboardingWeekendDaysScreenState extends State<OnboardingWeekendDaysScreen> {
  final Color mainTextColor = const Color(0xFF5F7E5B);
  final Color buttonColor = const Color(0xFFDFE2D1);
  
  String? _selectedDays;
  final List<String> _options = [
    "Saturdays and Sundays",
    "Fridays, Saturdays and Sundays",
    "Fridays and Saturdays",
  ];

  @override
  void initState() {
    super.initState();
    // If they said "No" to weekend habit, we might want to skip or pre-select "None"
    // But per your flow, let's just let them pick or skip.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: BoxDecoration(image: DecorationImage(image: AssetImage('assets/intro_back.jpg'), fit: BoxFit.cover))),
          Positioned(top: 50, left: 20, child: CircleAvatar(backgroundColor: Colors.white.withOpacity(0.8), child: IconButton(icon: Icon(Icons.arrow_back, color: mainTextColor), onPressed: () => Navigator.pop(context)))),
          
          OnboardingCard(
            child: Column(
              children: [
                Text(
                  "On which days would you like to eat more?",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                SizedBox(height: 30),
                
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
                      if (_selectedDays != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OnboardingFinalResultScreen(
                              gender: widget.gender,
                              age: widget.age,
                              weightVal: widget.weightVal,
                              weightUnit: widget.weightUnit,
                              heightVal: widget.heightVal,
                              heightUnit: widget.heightUnit,
                              goal: widget.goal,
                              mealFrequency: widget.mealFrequency,
                              weekendHabit: widget.weekendHabit,
                              weekendDays: _selectedDays!, // Pass new data
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
    bool isSelected = _selectedDays == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedDays = label),
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
        child: Row(children: [
          // We can add icons if you have them, otherwise text is fine
          Icon(Icons.calendar_today, color: isSelected ? mainTextColor : Colors.grey),
          SizedBox(width: 15),
          Expanded(child: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87))),
        ]),
      ),
    );
  }
}
