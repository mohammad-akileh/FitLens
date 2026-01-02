// lib/screens/onboarding/onboarding_age_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'onboarding_weight_screen.dart';

class OnboardingAgeScreen extends StatefulWidget {
  final String gender;
  const OnboardingAgeScreen({super.key, required this.gender});

  @override
  State<OnboardingAgeScreen> createState() => _OnboardingAgeScreenState();
}

class _OnboardingAgeScreenState extends State<OnboardingAgeScreen> {
  int _selectedAge = 22;

  // Colors
  final Color mainTextColor = const Color(0xFF5F7E5B);
  final Color buttonColor = const Color(0xFFDFE2D1);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
        // 1. Background Image
        Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/intro_back.jpg'),
            fit: BoxFit.cover,
          ),
        ),
      ),

      // 2. Back Button (Top Left)
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

      // 3. White Card
      Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          height: screenHeight * 0.55,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(40),
              topRight: Radius.circular(40),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(30, 40, 30, 30),
            child: Column(
              children: [
                // Title
                Text(
                  "What's your Age?",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "We'll use it to personalize your plan.",
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),

                SizedBox(height: 30),

                // --- SCROLLABLE AGE PICKER ---
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // The "Highlighter" Box in the middle
                      Container(
                        height: 60,
                        width: 120,
                        decoration: BoxDecoration(
                          color: mainTextColor.withOpacity(0.1), // Light green highlight
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),

                      // The Scrolling Numbers
                      ListWheelScrollView.useDelegate(
                        itemExtent: 60,
                        perspective: 0.005,
                        diameterRatio: 1.2,
                        physics: FixedExtentScrollPhysics(),
                        controller: FixedExtentScrollController(initialItem: _selectedAge - 10),
                        onSelectedItemChanged: (index) {
                          setState(() {
                            _selectedAge = index + 10;
                          });
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: 91, // Ages 10 to 100
                          builder: (context, index) {
                            int age = index + 10;
                            bool isSelected = _selectedAge == age;

                            return Center(
                              child: Text(
                                "$age",
                                style: TextStyle(
                                  fontSize: isSelected ? 32 : 24,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,

                                  // --- COLOR FIX ---
                                  color: isSelected ? mainTextColor : Colors.grey[400],
                                  // ----------------
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // -----------------------------

                SizedBox(height: 20),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OnboardingWeightScreen(
                            gender: widget.gender,
                            age: _selectedAge,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      "Continue",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ],
    ),
    );
  }
}