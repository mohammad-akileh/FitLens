// lib/screens/home_design_screen.dart
//#1
import 'package:flutter/material.dart';
import 'dart:math' as math;

class HomeDesignScreen extends StatelessWidget {
  final double currentCals, targetCals;
  final double currentProt, targetProt;
  final double currentCarb, targetCarb;
  final double currentFat, targetFat;

   HomeDesignScreen({
    super.key,
    required this.currentCals, required this.targetCals,
    required this.currentProt, required this.targetProt,
    required this.currentCarb, required this.targetCarb,
    required this.currentFat, required this.targetFat,
  });

  // =========================================================================
  // 🎨 COLOR & TRANSPARENCY CONTROL CENTER
  // =========================================================================

  // 1. The Main "Gauge" Card (Top Large Card)
  // 0xFF = 100% visible. 0xCC = 80%. 0x80 = 50%.
  final Color cardDark = const Color(0xFF4A5F48);

  // 2. The Macro Cards (Carb, Protein, Fat) AND Meal Cards (Breakfast, etc.)
  // I changed this to match the darker green you liked!
  final Color cardLight = const Color(0xFF9AAC95).withOpacity(0.6); // <--- Matches Meal Cards now

  // 3. The Water Card (Glassy Look)
  // withOpacity(0.5) makes it see-through so you can see the background image.
  final Color waterCardColor = const Color(0xFF9AAC95).withOpacity(0.6);

  // 4. Progress Bar Colors
  final Color progressGreen = const Color(0xFF00E676).withOpacity(0.6); // Normal
  final Color progressRed = const Color(0xFFFF5252).withOpacity(0.6);   // Over limit!
  final Color trackColor = const Color(0xFF3E4E3C).withOpacity(0.6);    // The empty part of the pipe

  // =========================================================================

  void _openScanScreen(BuildContext context, String mealType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Opening Scanner for $mealType... 📸")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    // Responsive Constants
    final double padding = screenWidth * 0.05;
    final double mainCardHeight = screenHeight * 0.28;

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
                  onError: (e, s) => print("BG Error: $e"),
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
                    _buildHeader(context),
                    SizedBox(height: 20),

                    // Main Gauge Card
                    _buildMainCalorieCard(context, mainCardHeight, screenWidth),
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

                    // Water Tracker
                    _buildWaterCard(screenWidth),
                    SizedBox(height: 20),

                    // Meals List
                    Text("Meals Today", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    SizedBox(height: 10),

                    _buildMealTile(context, "Breakfast", "Recommended 366-549 kcal", "assets/egg.png"),
                    _buildMealTile(context, "Lunch", "Recommended 549-732 kcal", "assets/lunch_bowl.png"),
                    _buildMealTile(context, "Dinner", "Recommended 400-600 kcal", "assets/dinner.png"),
                    _buildMealTile(context, "Snack", "Recommended 100-200 kcal", "assets/snack.png"),

                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        )
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(backgroundColor: Colors.grey, radius: 20, child: Icon(Icons.person, color: Colors.white)),
            SizedBox(width: 10),
            Text("Itami", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Row(
            children: [
              Text("Today ", style: TextStyle(fontWeight: FontWeight.bold)),
              Icon(Icons.calendar_today, size: 16, color: Colors.green),
            ],
          ),
        )
      ],
    );
  }
  // --- 🛠️ FIXED MAIN CARD (RESPONSIVE) ---
  Widget _buildMainCalorieCard(BuildContext context, double height, double width) {
    double percent = (currentCals / targetCals).clamp(0.0, 1.0);
    bool isOver = currentCals > targetCals;

    return Container(
      height: height,
      width: double.infinity,
      padding: EdgeInsets.all(15), // Reduced padding slightly to save space
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
                Text("5 Day Streak", style: TextStyle(color: Colors.white70, fontSize: 12)),
                SizedBox(height: 4),
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
          // 🛡️ THE FIX: Wrapped in FittedBox to prevent Overflow!
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown, // Shrinks content if it's too big
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min, // Keep it compact
                children: [
                  // Dynamic Spacing based on card height
                  SizedBox(height: height * 0.05),

                  SizedBox(
                    width: width * 0.6,
                    height: (width * 0.6) / 2,
                    child: CustomPaint(
                      painter: GaugeChartPainter(
                        percent: percent,
                        progressColor: isOver ? progressRed : progressGreen,
                        trackColor: trackColor,
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Image.asset(
                                "assets/fire.png",
                                height: 30, width: 30,
                                errorBuilder: (c, o, s) => Icon(Icons.local_fire_department, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: height * 0.03), // Dynamic Spacing

                  Text(
                    "${currentCals.toInt()} kcal",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    "of ${targetCals.toInt()}",
                    style: TextStyle(fontSize: 14, color: Colors.white70),
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
        color: cardLight, // <--- NOW MATCHES THE MEAL CARDS (Green)
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13)), // Darker text for better contrast on green
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
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterCard(double screenWidth) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: waterCardColor, // <--- Uses the Transparent/Glassy variable
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Water", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 5),
                RichText(
                  text: TextSpan(
                    style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(text: "1.9 "),
                      TextSpan(text: "/ 2.5L", style: TextStyle(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                Text("Last time 10:45 AM", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),

          Row(
            children: [
              Column(
                children: [
                  _circleButton(Icons.add),
                  SizedBox(height: 10),
                  _circleButton(Icons.remove),
                ],
              ),
              SizedBox(width: 15),
              Container(
                width: 50, height: 100,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: 50, height: 76,
                  decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(25)),
                  alignment: Alignment.center,
                  child: Text("76%", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: Icon(icon, size: 20, color: Colors.grey),
    );
  }

  Widget _buildMealTile(BuildContext context, String title, String subtitle, String assetPath) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardLight, // <--- NOW MATCHES THE MACRO CARDS
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), shape: BoxShape.circle),
            padding: EdgeInsets.all(8),
            child: Image.asset(assetPath, fit: BoxFit.contain, errorBuilder: (c,o,s) => Icon(Icons.fastfood, color: Colors.orange)),
          ),
          SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.black54), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),

          InkWell(
            onTap: () => _openScanScreen(context, title),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(Icons.add, size: 24, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

// =================================================================
// 🎨 THE CUSTOM GAUGE PAINTER (FIXED!)
// =================================================================
class GaugeChartPainter extends CustomPainter {
  final double percent;
  final Color progressColor;
  final Color trackColor;

  GaugeChartPainter({required this.percent, required this.progressColor, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Setup - Perfect Semi-Circle (Rainbow Shape)
    // Start at PI (180 degrees - Left)
    // Sweep PI (180 degrees - to Right)
    const double startAngle = math.pi;
    const double sweepAngle = math.pi;

    final center = Offset(size.width / 2, size.height); // Center bottom
    final radius = size.width / 2; // Radius is half width
    final rect = Rect.fromCircle(center: center, radius: radius);

    // 🛠️ CHART THICKNESS (Wider Pipe!)
    // Change this number to make it fatter or thinner
    final strokeWidth = 30.0;

    // 2. Draw the Dark Background Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round; // Use .butt if you want flat edges

    canvas.drawArc(rect, startAngle, sweepAngle, false, trackPaint);

    // 3. Draw the Colored Progress
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