// lib/screens/tabs/home_tab.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:math' as math;

import '../../services/database_service.dart';
import '../../services/notification_service.dart'; // 🔔 1. IMPORT THIS!
import '../scan_screen.dart';
import '../profile/profile_screen.dart';
import '../meal_history_detail_screen.dart';

class HomeTab extends StatefulWidget {
  final DateTime currentDate;
  final Function(DateTime) onDateChanged;

  const HomeTab(
      {super.key, required this.currentDate, required this.onDateChanged});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final DatabaseService _dbService = DatabaseService();
  Timer? _midnightTimer;

  // 🔔 2. ADD THESE FLAGS (To stop notification spam)
  bool _alertCals = false;
  bool _alertCarbs = false;
  bool _alertFat = false;
  bool _alertProt = false;

  // Colors
  final Color cardDark = const Color(0xB34A5F48);
  final Color cardLight = const Color(0xFF9AAC95).withOpacity(0.6);
  final Color progressGreen = const Color(0xFF00E676).withOpacity(1);
  final Color progressRed = const Color(0xFFFF5252).withOpacity(1);
  final Color trackColor = const Color(0xFF3E4E3C).withOpacity(0.6);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupMidnightTimer();

    // 👇 ADD THIS LINE: Ask for permission immediately when Home loads!
    _requestPermission();
  }

  // 👇 ADD THIS FUNCTION
  Future<void> _requestPermission() async {
    // This connects to the Android-specific notification plugin
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
    FlutterLocalNotificationsPlugin().resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    // This pops up the system dialog "Allow FitLens to send notifications?"
    await androidImplementation?.requestNotificationsPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    super.dispose();
  }

  bool get _isToday {
    final now = DateTime.now();
    return widget.currentDate.year == now.year &&
        widget.currentDate.month == now.month &&
        widget.currentDate.day == now.day;
  }

  void _setupMidnightTimer() {
    DateTime now = DateTime.now();
    DateTime nextMidnight = DateTime(now.year, now.month, now.day + 1);
    Duration timeUntilMidnight = nextMidnight.difference(now);

    _midnightTimer = Timer(timeUntilMidnight, () {
      print("🕛 Midnight Timer Triggered!");

      // Reset Alert Flags for the new day
      setState(() {
        _alertCals = false;
        _alertCarbs = false;
        _alertFat = false;
        _alertProt = false;
      });

      _dbService.checkAndResetDailyStats(_auth.currentUser!.uid);
      widget.onDateChanged(DateTime.now());
      _setupMidnightTimer();
    });
  }

  // ... (Keep _pickDate and _addWater exactly as they were) ...
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.currentDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFF4A5F48),
            colorScheme: const ColorScheme.light(primary: Color(0xFF4A5F48)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      widget.onDateChanged(picked);
    }
  }

  Future<void> _addWater(String uid, Map<String, dynamic> data) async {
    if (!_isToday) return;

    String dbDate = data['last_active_date'] ?? "";
    String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (dbDate != todayStr) {
      await _dbService.checkAndResetDailyStats(uid);
      await _db.collection('users').doc(uid).update({
        'current_water': 250,
        'current_calories': 0,
        'current_protein': 0,
        'current_carbs': 0,
        'current_fat': 0,
        'last_active_date': todayStr,
        'app_secret': 'FitLens_VIP_2025',
      });
    } else {
      int currentWater = (data['current_water'] ?? 0).toInt();
      await _db.collection('users').doc(uid).update({
        'current_water': currentWater + 250,
        'app_secret': 'FitLens_VIP_2025',
      });
    }
  }

  void _openScanScreen(BuildContext context, String mealType) {
    if (!_isToday) return;
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ScanScreen(mealType: mealType)));
  }

  // 🔔 3. NEW HELPER FUNCTION: CHECK LIMITS
  void _checkExceededLimits(Map<String, dynamic> data) {
    double tCal = (data['target_calories'] ?? 2000).toDouble();
    double cCal = (data['current_calories'] ?? 0).toDouble();
    double tFat = (data['target_fat'] ?? 65).toDouble();
    double cFat = (data['current_fat'] ?? 0).toDouble();
    double tProt = (data['target_protein'] ?? 150).toDouble();
    double cProt = (data['current_protein'] ?? 0).toDouble();
    double tCarb = (data['target_carbs'] ?? 250).toDouble();
    double cCarb = (data['current_carbs'] ?? 0).toDouble();

    // Check Calories
    if (cCal > tCal && !_alertCals) {
      NotificationService.showWarning(
          "⚠️ Limit Reached!", "You've exceeded your daily calories.");
      _alertCals = true; // Set flag so we don't notify again this session
    }
    // Check Fat
    if (cFat > tFat && !_alertFat) {
      NotificationService.showWarning(
          "⚠️ Fat Limit Reached", "Watch your intake for the rest of the day.");
      _alertFat = true;
    }
    // Check Carbs
    if (cCarb > tCarb && !_alertCarbs) {
      NotificationService.showWarning(
          "⚠️ Carb Limit Reached", "You hit your carb limit.");
      _alertCarbs = true;
    }
    // Check Protein (Optional, usually exceeding protein is fine, but as requested)
    if (cProt > tProt && !_alertProt) {
      NotificationService.showWarning(
          "💪 Protein Goal Hit!", "Great job hitting your protein target.");
      _alertProt = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;
    if (user == null) return const Center(child: Text("Please login"));

    if (_isToday) {
      return StreamBuilder<DocumentSnapshot>(
        stream: _db.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          var data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          String dbDate = data['last_active_date'] ?? "";
          String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

          if (dbDate != todayStr) {
            data = {
              ...data,
              'current_calories': 0,
              'current_protein': 0,
              'current_carbs': 0,
              'current_fat': 0,
              'current_water': 0,
            };
          }

          // 🔔 4. CALL THE CHECK HERE!
          // We wrap it in addPostFrameCallback to avoid errors during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkExceededLimits(data);
          });

          return _buildDesignLayout(data, isHistory: false);
        },
      );
    } else {
      // ... (Keep History FutureBuilder exactly the same) ...
      return FutureBuilder<Map<String, dynamic>?>(
        key: ValueKey(widget.currentDate.toString()),
        future: _dbService.getHistoryForDate(user.uid, widget.currentDate),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          var data = snapshot.data ??
              {
                'calories': 0,
                'protein': 0,
                'carbs': 0,
                'fat': 0,
                'water': 0,
                'target_calories': 2000,
                'first_name': 'Besti'
              };
          return _buildDesignLayout(data, isHistory: true);
        },
      );
    }
  }

  // ... (The rest of your UI widgets: _buildDesignLayout, _buildHeader, etc. remain EXACTLY the same) ...
  // ... Paste the rest of your file here ...
  Widget _buildDesignLayout(Map<String, dynamic> data,
      {required bool isHistory}) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;
    final double padding = screenWidth * 0.05;
    final double mainCardHeight = screenHeight * 0.28;

    String firstName = data['first_name'] ?? data['name'] ?? "User";
    String? photoUrl = data['photo_url'];

    double targetCals = (data['target_calories'] ?? 2000).toDouble();
    double targetWater = (data['target_water'] ?? 2500).toDouble();
    double targetProt = (data['target_protein'] ?? 150).toDouble();
    double targetCarb = (data['target_carbs'] ?? 250).toDouble();
    double targetFat = (data['target_fat'] ?? 65).toDouble();

    double currentCals = isHistory
        ? (data['calories'] ?? 0).toDouble()
        : (data['current_calories'] ?? 0).toDouble();
    double currentWater = isHistory
        ? (data['water'] ?? 0).toDouble()
        : (data['current_water'] ?? 0).toDouble();
    double currentProt = isHistory
        ? (data['protein'] ?? 0).toDouble()
        : (data['current_protein'] ?? 0).toDouble();
    double currentCarb = isHistory
        ? (data['carbs'] ?? 0).toDouble()
        : (data['current_carbs'] ?? 0).toDouble();
    double currentFat = isHistory
        ? (data['fat'] ?? 0).toDouble()
        : (data['current_fat'] ?? 0).toDouble();

    return Scaffold(

      body: Stack(
        children: [
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                  image: AssetImage('assets/intro_back.jpg'),
                  opacity: .4,
                  fit: BoxFit.cover),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                children: [
                  _buildHeader(firstName, photoUrl, isHistory),
                  const SizedBox(height: 20),
                  _buildMainCalorieCard(
                      mainCardHeight, screenWidth, currentCals, targetCals),
                  const SizedBox(height: 20),
                  IntrinsicHeight(
                      child: Row(children: [
                    Expanded(
                        child:
                            _buildMacroCard("Carb", currentCarb, targetCarb)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _buildMacroCard(
                            "Protein", currentProt, targetProt)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _buildMacroCard("Fat", currentFat, targetFat)),
                  ])),
                  const SizedBox(height: 20),

                  _buildWaterCard(screenWidth, currentWater, targetWater,
                      _auth.currentUser!.uid, isHistory, data),

                  const SizedBox(height: 20),

                  // 🔽 HERE IS THE BACK TO TODAY BUTTON 🔽
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isHistory ? "Meals on this day" : "Meals Today",
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),

                      // 👇 THIS IS THE BUTTON YOU WANTED! 👇
                      if (isHistory)
                        GestureDetector(
                          onTap: () => widget.onDateChanged(DateTime.now()),
                          child: const Text("Back to Today",
                              style: TextStyle(
                                  color: Color(0xFF4A5F48),
                                  fontWeight: FontWeight.bold)),
                        )
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (isHistory)
                    _buildHistoryMealsList()
                  else
                    Column(children: [
                      _buildMealTile("Breakfast", "Recommended 300-500 kcal",
                          "assets/egg.png"),
                      _buildMealTile("Lunch", "Recommended 500-700 kcal",
                          "assets/lunch_bowl.png"),
                      _buildMealTile("Dinner", "Recommended 400-600 kcal",
                          "assets/dinner.png"),
                      _buildMealTile("Snack", "Recommended 100-200 kcal",
                          "assets/snack.png"),
                    ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET HELPERS
  Widget _buildHeader(String name, String? photoUrl, bool isHistory) {
    User? currentUser = FirebaseAuth.instance.currentUser;
    ImageProvider? imageProvider;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      imageProvider = NetworkImage(photoUrl);
    } else if (currentUser?.photoURL != null) {
      imageProvider = NetworkImage(currentUser!.photoURL!);
    }
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(children: [
        GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const ProfileScreen())),
            child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[300],
                backgroundImage: imageProvider,
                child: imageProvider == null
                    ? const Icon(Icons.person, color: Colors.grey)
                    : null)),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isHistory ? "History View" : "Hello,",
              style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(
              isHistory ? DateFormat('MMM d').format(widget.currentDate) : name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
        ])
      ]),
      Container(
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5), shape: BoxShape.circle),
          child: IconButton(
              icon: const Icon(Icons.calendar_month, color: Color(0xFF4A5F48)),
              onPressed: _pickDate))
    ]);
  }

  Widget _buildMainCalorieCard(
      double height, double width, double current, double target) {
    double percent = (current / target).clamp(0.0, 1.0);
    bool isOver = current > target;
    return Container(
        height: height,
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: cardDark, borderRadius: BorderRadius.circular(30)),
        child: Stack(children: [
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
                                painter: GaugeChartPainter(
                                    percent: percent,
                                    progressColor:
                                        isOver ? progressRed : progressGreen,
                                    trackColor: trackColor),
                                child: Center(
                                    child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                      Image.asset("assets/fire.png",
                                          height: 30,
                                          width: 30,
                                          errorBuilder: (c, o, s) => const Icon(
                                              Icons.local_fire_department,
                                              color: Colors.white70))
                                    ])))),
                        SizedBox(height: height * 0.03),
                        Text("${current.toInt()} kcal",
                            style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        Text("of ${target.toInt()}",
                            style: const TextStyle(
                                fontSize: 14, color: Colors.white70))
                      ])))
        ]));
  }

  Widget _buildMacroCard(String label, double current, double target) {
    double percent = (current / target).clamp(0.0, 1.0);
    bool isOver = current > target;
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        decoration: BoxDecoration(
            color: cardLight, borderRadius: BorderRadius.circular(20)),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: 13)),
              const SizedBox(height: 10),
              ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                      value: percent,
                      backgroundColor: Colors.black12,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          isOver ? progressRed : progressGreen),
                      minHeight: 8)),
              const SizedBox(height: 10),
              FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text("${current.toInt()} / ${target.toInt()}g",
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)))
            ]));
  }

  Widget _buildWaterCard(
      double screenWidth,
      double currentWater,
      double targetWater,
      String uid,
      bool isHistory,
      Map<String, dynamic> data) {
    double percent = (currentWater / targetWater).clamp(0.0, 1.0);
    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: const Color(0xC32C2C2C),
            borderRadius: BorderRadius.circular(25)),
        child: Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  const Icon(Icons.water_drop,
                      color: Colors.blueAccent, size: 18),
                  const SizedBox(width: 5),
                  Text("Water Intake",
                      style: TextStyle(fontSize: 14, color: Colors.grey[400]))
                ]),
                const SizedBox(height: 10),
                TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: currentWater),
                    duration: const Duration(seconds: 1),
                    builder: (context, value, child) {
                      return RichText(
                          text: TextSpan(
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold),
                              children: [
                            TextSpan(text: "${value.toInt()} "),
                            TextSpan(
                                text: "/ ${targetWater.toInt()} ml",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[500]))
                          ]));
                    }),
                const SizedBox(height: 20),
                if (!isHistory)
                  InkWell(
                      onTap: () => _addWater(uid, data),
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                              color: const Color(0xFF3E3E3E),
                              borderRadius: BorderRadius.circular(30)),
                          child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.add, color: Colors.white, size: 18),
                                SizedBox(width: 5),
                                Text("250 ml",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold))
                              ])))
              ])),
          const SizedBox(width: 10),
          _buildVisualCup(percent)
        ]));
  }

  Widget _buildVisualCup(double percent) {
    return SizedBox(
        width: 60,
        height: 90,
        child: Stack(alignment: Alignment.bottomCenter, children: [
          ClipPath(
              clipper: CupClipper(),
              child: Container(
                  color: Colors.grey[800],
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                      heightFactor: percent,
                      widthFactor: 1.0,
                      child: Container(
                          decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              boxShadow: [
                            BoxShadow(
                                color: Colors.blueAccent.withOpacity(0.5),
                                blurRadius: 10)
                          ]))))),
          ClipPath(
              clipper: CupClipper(),
              child: Container(
                  decoration: BoxDecoration(
                      border: Border.all(
                          color: Colors.white.withOpacity(0.1), width: 1),
                      gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.transparent
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight))))
        ]));
  }

  Widget _buildMealTile(String title, String subtitle, String assetPath) {
    return Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: cardLight, borderRadius: BorderRadius.circular(25)),
        child: Row(children: [
          Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5), shape: BoxShape.circle),
              padding: const EdgeInsets.all(8),
              child: Image.asset(assetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (c, o, s) =>
                      const Icon(Icons.fastfood, color: Colors.orange))),
          const SizedBox(width: 15),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
                Text(subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                    overflow: TextOverflow.ellipsis)
              ])),
          InkWell(
              onTap: () => _openScanScreen(context, title),
              child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                  child:
                      const Icon(Icons.add, size: 24, color: Colors.black87)))
        ]));
  }

  Widget _buildHistoryMealsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      key: ValueKey(widget.currentDate.toString()),
      stream: _dbService.getMealsForDate(
          _auth.currentUser!.uid, widget.currentDate),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        var meals = snapshot.data!;
        if (meals.isEmpty)
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("No meals recorded for this day.",
                      style: TextStyle(color: Colors.grey))));
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: meals.length,
          itemBuilder: (context, index) {
            var meal = meals[index];
            int cals = (meal['total_calories'] ?? 0).toInt();
            String? url = meal['image_url'];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: cardLight.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey[300]),
                    child: url != null && url.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(url, fit: BoxFit.cover))
                        : const Icon(Icons.fastfood, color: Colors.grey)),
                title: Text(meal['meal_type'] ?? 'Meal',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text("$cals kcal",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            MealHistoryDetailScreen(mealData: meal))),
              ),
            );
          },
        );
      },
    );
  }
}

class GaugeChartPainter extends CustomPainter {
  final double percent;
  final Color progressColor;
  final Color trackColor;

  GaugeChartPainter(
      {required this.percent,
      required this.progressColor,
      required this.trackColor});

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
    canvas.drawArc(
        rect, startAngle, sweepAngle * percent, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CupClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width * 0.15, size.height);
    path.lineTo(size.width * 0.85, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
