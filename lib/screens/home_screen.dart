// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 1. Firebase Tools
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 2. Colors (From your Design)
  final Color cardDark = const Color(0xFF4A5F48);
  final Color cardLight = const Color(0xFF9AAC95).withOpacity(0.6);
  final Color waterCardColor = const Color(0xFF9AAC95).withOpacity(0.6);
  final Color progressGreen = const Color(0xFF00E676).withOpacity(1);
  final Color progressRed = const Color(0xFFFF5252).withOpacity(1);
  final Color trackColor = const Color(0xFF3E4E3C).withOpacity(0.6);

  // 3. Water Logic: Adds 250ml and updates DB
  Future<void> _addWater(String uid, int currentWater) async {
    // Add 250ml (1 cup)
    int newWater = currentWater + 250;

    await _db.collection('users').doc(uid).update({
      'current_water': newWater,
      'app_secret': 'FitLens_VIP_2025', // 🔒 Security Key
    });
  }

  // 4. Remove Water Logic (Optional, in case of mistake)
  Future<void> _removeWater(String uid, int currentWater) async {
    int newWater = currentWater - 250;
    if (newWater < 0) newWater = 0;

    await _db.collection('users').doc(uid).update({
      'current_water': newWater,
      'app_secret': 'FitLens_VIP_2025',
    });
  }

  void _openScanScreen(BuildContext context, String mealType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Opening Scanner for $mealType... 📸")),
    );
  }

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;
    if (user == null) return const Center(child: Text("Please login"));

    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;
    final double padding = screenWidth * 0.05;
    final double mainCardHeight = screenHeight * 0.28;

    // 📡 STREAM BUILDER: This makes the screen "Alive"
    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // --- EXTRACT REAL DATA ---
        var data = snapshot.data!.data() as Map<String, dynamic>?;

        // Targets (Safety net: 2000 if null)
        double targetCals = (data?['target_calories'] ?? 2000).toDouble();
        double targetWater = (data?['target_water'] ?? 2500).toDouble();

        // Macros Targets
        double targetProt = (data?['target_protein'] ?? 150).toDouble();
        double targetCarb = (data?['target_carbs'] ?? 250).toDouble();
        double targetFat = (data?['target_fat'] ?? 65).toDouble();

        // Current Progress
        double currentCals = (data?['current_calories'] ?? 0).toDouble();
        double currentWater = (data?['current_water'] ?? 0).toDouble();

        // Current Macros (Assuming you save these later, defaulting to 0 for now)
        double currentProt = (data?['current_protein'] ?? 0).toDouble();
        double currentCarb = (data?['current_carbs'] ?? 0).toDouble();
        double currentFat = (data?['current_fat'] ?? 0).toDouble();

        return Scaffold(
          body: Stack(
            children: [
              // --- BACKGROUND IMAGE ---
              Container(
                height: double.infinity,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/intro_back.jpg'),
                    opacity: .5,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // --- CONTENT ---
              SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(data?['first_name'] ?? "FitLens User"),
                      SizedBox(height: 20),

                      // Main Gauge Card (Now using Real Data)
                      _buildMainCalorieCard(mainCardHeight, screenWidth, currentCals, targetCals),
                      SizedBox(height: 20),

                      // Macros Row
                      IntrinsicHeight(
                        child: Row(
                          children: [
                            Expanded(child: _buildMacroCard("Carb", currentCarb, targetCarb)),
                            SizedBox(width: 10),
                            Expanded(child: _buildMacroCard("Protein", currentProt, targetProt)),
                            SizedBox(width: 10),
                            Expanded(child: _buildMacroCard("Fat", currentFat, targetFat)),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),

                      // Water Tracker (Now Alive 💧)
                      _buildWaterCard(screenWidth, currentWater, targetWater, user.uid),
                      SizedBox(height: 20),

                      // Meals List
                      const Text("Meals Today", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                      SizedBox(height: 10),

                      _buildMealTile(context, "Breakfast", "Recommended 300-500 kcal", "assets/egg.png"),
                      _buildMealTile(context, "Lunch", "Recommended 500-700 kcal", "assets/lunch_bowl.png"),
                      _buildMealTile(context, "Dinner", "Recommended 400-600 kcal", "assets/dinner.png"),
                      _buildMealTile(context, "Snack", "Recommended 100-200 kcal", "assets/snack.png"),

                      SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- WIDGETS ---

  Widget _buildHeader(String name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(backgroundColor: Colors.grey, radius: 20, child: Icon(Icons.person, color: Colors.white)),
            SizedBox(width: 10),
            Text(name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Row(
            children: [
              const Text("Today ", style: TextStyle(fontWeight: FontWeight.bold)),
              const Icon(Icons.calendar_today, size: 16, color: Colors.green),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildMainCalorieCard(double height, double width, double current, double target) {
    double percent = (current / target).clamp(0.0, 1.0);
    bool isOver = current > target;

    return Container(
      height: height,
      width: double.infinity,
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        children: [
          // Streak
          Positioned(
            top: 0, right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text("5 Day Streak", style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(5, (index) => Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: CircleAvatar(radius: 3, backgroundColor: progressGreen),
                  )),
                )
              ],
            ),
          ),

          // The Center Content (Gauge + Text)
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: height * 0.05),
                  SizedBox(
                    width: width * 0.6,
                    height: (width * 0.6) / 2,
                    child: CustomPaint(
                      // 🎨 USING YOUR CUSTOM PAINTER
                      painter: GaugeChartPainter(
                        percent: percent,
                        progressColor: isOver ? progressRed : progressGreen,
                        trackColor: trackColor,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Image.asset(
                              "assets/fire.png",
                              height: 30, width: 30,
                              errorBuilder: (c, o, s) => const Icon(Icons.local_fire_department, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: height * 0.03),

                  Text(
                    "${current.toInt()} kcal",
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    "of ${target.toInt()}",
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroCard(String label, double current, double target) {
    double percent = (current / target).clamp(0.0, 1.0);
    bool isOver = current > target;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      decoration: BoxDecoration(
        color: cardLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13)),
          SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.black12,
              valueColor: AlwaysStoppedAnimation<Color>(isOver ? progressRed : progressGreen),
              minHeight: 8,
            ),
          ),
          SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              "${current.toInt()} / ${target.toInt()}g",
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // 💧 UPDATED WATER CARD (Now using Real DB Data)
  Widget _buildWaterCard(double screenWidth, double currentWater, double targetWater, String uid) {
    // Math for UI
    double percent = (currentWater / targetWater).clamp(0.0, 1.0);
    String currentLiters = (currentWater / 1000).toStringAsFixed(1); // 1500 -> 1.5
    String targetLiters = (targetWater / 1000).toStringAsFixed(1);
    String percentText = "${(percent * 100).toInt()}%";

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: waterCardColor,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Water", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 5),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(text: "$currentLiters "),
                      TextSpan(text: "/ ${targetLiters}L", style: const TextStyle(fontSize: 14, color: Colors.black54)),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                Text("Hydration Level: $percentText", style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),

          Row(
            children: [
              Column(
                children: [
                  // PLUS BUTTON
                  InkWell(
                    onTap: () => _addWater(uid, currentWater.toInt()), // 🔗 Connects to Logic
                    child: _circleButton(Icons.add),
                  ),
                  SizedBox(height: 10),
                  // MINUS BUTTON
                  InkWell(
                    onTap: () => _removeWater(uid, currentWater.toInt()),
                    child: _circleButton(Icons.remove),
                  ),
                ],
              ),
              SizedBox(width: 15),

              // 🌊 THE BLUE BAR
              Container(
                width: 50, height: 100,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
                alignment: Alignment.bottomCenter,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: 50,
                  height: 100 * percent, // Dynamic Height
                  decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(25)),
                  alignment: Alignment.center,
                  child: percent > 0.3
                      ? Text(percentText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                      : null,
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon) {
    return Container(
      width: 35, height: 35,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: Icon(icon, size: 20, color: Colors.grey),
    );
  }

  Widget _buildMealTile(BuildContext context, String title, String subtitle, String assetPath) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardLight,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), shape: BoxShape.circle),
            padding: EdgeInsets.all(8),
            child: Image.asset(assetPath, fit: BoxFit.contain, errorBuilder: (c,o,s) => const Icon(Icons.fastfood, color: Colors.orange)),
          ),
          SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),

          InkWell(
            onTap: () => _openScanScreen(context, title),
            child: Container(
              width: 40, height: 40,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.add, size: 24, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

// =================================================================
// 🎨 YOUR ORIGINAL GAUGE PAINTER (No changes needed here!)
// =================================================================
class GaugeChartPainter extends CustomPainter {
  final double percent;
  final Color progressColor;
  final Color trackColor;

  GaugeChartPainter({required this.percent, required this.progressColor, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    const double startAngle = math.pi;
    const double sweepAngle = math.pi;

    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final strokeWidth = 30.0;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, trackPaint);

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle * percent, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}