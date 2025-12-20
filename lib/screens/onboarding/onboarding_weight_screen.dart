// lib/screens/onboarding/onboarding_weight_screen.dart
import 'package:flutter/material.dart';
import '../../widgets/onboarding_card.dart';
import 'onboarding_height_screen.dart'; // <-- POINTS TO HEIGHT

class OnboardingWeightScreen extends StatefulWidget {
  final String gender;
  final int age;
  const OnboardingWeightScreen({super.key, required this.gender, required this.age});

  @override
  State<OnboardingWeightScreen> createState() => _OnboardingWeightScreenState();
}

class _OnboardingWeightScreenState extends State<OnboardingWeightScreen> {
  final Color mainTextColor = const Color(0xFF5F7E5B);
  final Color buttonColor = const Color(0xFFDFE2D1);

  bool _isKg = true;
  double _currentWeightVal = 60.0;
  final double _itemWidth = 10.0;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToValue(_currentWeightVal));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double get _minWeight => _isKg ? 30.0 : 66.0;
  double get _maxWeight => _isKg ? 200.0 : 440.0;
  int get _totalTicks => (_maxWeight - _minWeight).round();

  void _jumpToValue(double val) {
    double offset = (val - _minWeight) * _itemWidth;
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(offset);
    }
  }

  void _toggleUnit(bool makingKg) {
    if (_isKg == makingKg) return;
    setState(() {
      _isKg = makingKg;
      if (_isKg) {
        _currentWeightVal = _currentWeightVal / 2.20462;
      } else {
        _currentWeightVal = _currentWeightVal * 2.20462;
      }
      _currentWeightVal = _currentWeightVal.clamp(_minWeight, _maxWeight);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToValue(_currentWeightVal));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double horizontalPadding = screenWidth / 2 - _itemWidth / 2;

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
                  "What's your weight?",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildToggleButton("Kg", _isKg, () => _toggleUnit(true)),
                      _buildToggleButton("Lbs", !_isKg, () => _toggleUnit(false)),
                    ],
                  ),
                ),
                SizedBox(height: 30),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: _currentWeightVal.toStringAsFixed(0),
                        style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: mainTextColor),
                      ),
                      TextSpan(
                        text: " ${_isKg ? 'Kg' : 'Lbs'}",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: mainTextColor),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      NotificationListener<ScrollNotification>(
                        onNotification: (scrollInfo) {
                          if (scrollInfo is ScrollUpdateNotification) {
                            setState(() {
                              _currentWeightVal = _minWeight + (scrollInfo.metrics.pixels / _itemWidth);
                              _currentWeightVal = _currentWeightVal.clamp(_minWeight, _maxWeight);
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
                            int value = _minWeight.round() + index;
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
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      // --- NAVIGATE TO HEIGHT SCREEN ---
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OnboardingHeightScreen(
                            gender: widget.gender,
                            age: widget.age,
                            weightVal: _currentWeightVal,
                            weightUnit: _isKg ? 'kg' : 'lbs',
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