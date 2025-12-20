// lib/screens/onboarding/onboarding_height_screen.dart
import 'package:flutter/material.dart';
import '../../widgets/onboarding_card.dart'; // Using the shared widget
import 'onboarding_goal_screen.dart'; // <-- POINTS TO GOAL

class OnboardingHeightScreen extends StatefulWidget {
  final String gender;
  final int age;
  final double weightVal;
  final String weightUnit;

  const OnboardingHeightScreen({
    super.key,
    required this.gender,
    required this.age,
    required this.weightVal,
    required this.weightUnit,
  });

  @override
  State<OnboardingHeightScreen> createState() => _OnboardingHeightScreenState();
}

class _OnboardingHeightScreenState extends State<OnboardingHeightScreen> {
  final Color mainTextColor = const Color(0xFF5F7E5B);
  final Color buttonColor = const Color(0xFFDFE2D1);

  bool _isCm = true;
  double _currentHeightCm = 170.0;
  final double _itemWidth = 10.0;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToValue(_currentHeightCm));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double get _minCm => 100.0;
  double get _maxCm => 250.0;
  int get _totalTicks => (_maxCm - _minCm).round();

  void _jumpToValue(double val) {
    double offset = (val - _minCm) * _itemWidth;
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(offset);
    }
  }

  void _toggleUnit(bool makingCm) {
    if (_isCm == makingCm) return;
    setState(() {
      _isCm = makingCm;
    });
    _currentHeightCm = _currentHeightCm.clamp(_minCm, _maxCm);
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToValue(_currentHeightCm));
  }

  String _getFormattedHeight() {
    if (_isCm) {
      return _currentHeightCm.toStringAsFixed(0);
    } else {
      double totalInches = _currentHeightCm / 2.54;
      int feet = (totalInches / 12).floor();
      int inches = (totalInches % 12).round();
      return "$feet' $inches\"";
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double horizontalPadding = screenWidth / 2 - _itemWidth / 2;

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/intro_back.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Back Button
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

          // Card
          OnboardingCard(
            child: Column(
              children: [
                Text(
                  "How tall are you?",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                SizedBox(height: 20),

                // Toggle
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildToggleButton("cm", _isCm, () => _toggleUnit(true)),
                      _buildToggleButton("ft", !_isCm, () => _toggleUnit(false)),
                    ],
                  ),
                ),

                SizedBox(height: 30),

                // Value Display
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: _getFormattedHeight(),
                        style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: mainTextColor),
                      ),
                      if (_isCm)
                        TextSpan(
                          text: " cm",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: mainTextColor),
                        ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Ruler
                SizedBox(
                  height: 150, // Matches Weight Screen
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      NotificationListener<ScrollNotification>(
                        onNotification: (scrollInfo) {
                          if (scrollInfo is ScrollUpdateNotification) {
                            setState(() {
                              _currentHeightCm = _minCm + (scrollInfo.metrics.pixels / _itemWidth);
                              _currentHeightCm = _currentHeightCm.clamp(_minCm, _maxCm);
                            });
                          }
                          return true;
                        },
                        child: ListView.builder(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          physics: BouncingScrollPhysics(),
                          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                          itemCount: _totalTicks + 1,
                          itemBuilder: (context, index) {
                            int value = _minCm.round() + index;
                            bool isMajor = value % 10 == 0;
                            bool isMedium = value % 5 == 0 && !isMajor;
                            double tickHeight = isMajor ? 50.0 : (isMedium ? 35.0 : 20.0);
                            double tickThickness = isMajor ? 2.5 : 1.5;

                            return Container(
                              width: _itemWidth,
                              alignment: Alignment.bottomCenter,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (isMajor)
                                    Text(
                                      "$value",
                                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                    ),
                                  SizedBox(height: 5),
                                  Container(
                                    height: tickHeight,
                                    width: tickThickness,
                                    color: Colors.grey[400],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Container(
                        height: 75,
                        width: 4,
                        decoration: BoxDecoration(color: mainTextColor, borderRadius: BorderRadius.circular(2)),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 40),

                // Continue Button (Leading to Goal)
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      // Prepare height data
                      double finalHeightVal;
                      String finalHeightUnit;
                      if (_isCm) {
                        finalHeightVal = _currentHeightCm;
                        finalHeightUnit = 'cm';
                      } else {
                        finalHeightVal = _currentHeightCm / 2.54;
                        finalHeightUnit = 'inches';
                      }

                      // --- NAVIGATE TO GOAL SCREEN ---
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OnboardingGoalScreen(
                            gender: widget.gender,
                            age: widget.age,
                            weightVal: widget.weightVal,
                            weightUnit: widget.weightUnit,
                            heightVal: finalHeightVal,
                            heightUnit: finalHeightUnit,
                          ),
                        ),
                      );
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

  Widget _buildToggleButton(String text, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 30),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          boxShadow: isActive ? [BoxShadow(color: Colors.black12, blurRadius: 5)] : [],
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