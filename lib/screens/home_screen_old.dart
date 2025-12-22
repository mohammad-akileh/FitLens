// // lib/screens/home_screen.dart
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import '../services/auth_service.dart';
// import '../auth_gate.dart'; // <-- MAKE SURE THIS IS HERE
// import 'scan_screen.dart';
// import 'profile_screen.dart';
// import 'meal_details_screen.dart'; // For your test button
//
// class HomeScreen extends StatefulWidget {
//   HomeScreen({super.key});
//
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> {
//   final AuthService _authService = AuthService();
//   DateTime? _lastPressed;
//
//   // --- THE NUCLEAR SIGN OUT ---
//   void _signOut() async {
//     await _authService.signOut();
//     if (mounted) {
//       Navigator.of(context).pushAndRemoveUntil(
//         MaterialPageRoute(builder: (context) => AuthGate()),
//             (route) => false,
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return PopScope(
//       canPop: false,
//       onPopInvoked: (didPop) {
//         if (didPop) return;
//         final now = DateTime.now();
//         final bool shouldExit = _lastPressed != null &&
//             now.difference(_lastPressed!) < Duration(seconds: 2);
//         if (shouldExit) {
//           SystemNavigator.pop();
//         } else {
//           _lastPressed = now;
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Press back again to exit'),
//               duration: Duration(seconds: 2),
//             ),
//           );
//         }
//       },
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text('Home Dashboard'),
//           automaticallyImplyLeading: false, // No back button here
//           actions: [
//             IconButton(
//               icon: Icon(Icons.logout),
//               onPressed: _signOut, // Calls our nuclear function
//             )
//           ],
//         ),
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: <Widget>[
//               const Text(
//                 'Welcome to your Fitness App!',
//                 style: TextStyle(fontSize: 20),
//               ),
//               const SizedBox(height: 40),
//
//               // Scan Button
//               ElevatedButton(
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => const ScanScreen()),
//                   );
//                 },
//                 style: ElevatedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
//                 ),
//                 child: const Text(
//                   'Scan a Meal',
//                   style: TextStyle(fontSize: 18),
//                 ),
//               ),
//
//               const SizedBox(height: 20),
//
//               // Profile Button
//               ElevatedButton(
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => const ProfileScreen()),
//                   );
//                 },
//                 style: ElevatedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
//                 ),
//                 child: const Text(
//                   'View Profile',
//                   style: TextStyle(fontSize: 18),
//                 ),
//               ),
//               /*
//               const SizedBox(height: 20),
//
//               // DEBUG BUTTON (Delete later)
//               ElevatedButton(
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => MealDetailsScreen(
//                         imageUrl: "https://via.placeholder.com/300",
//                         aiResponse: """
//                         [
//                           {
//                             "food_name": "Mashawe",
//                             "serving_unit": "1 Skewer",
//                             "calories_per_serving": 250
//                           },
//                           {
//                             "food_name": "Shanina",
//                             "serving_unit": "1 Cup",
//                             "calories_per_serving": 120
//                           }
//                         ]
//                         """,
//                       ),
//                     ),
//                   );
//                 },
//                 child: Text("DEBUG: Test Edit UI"),
//                 style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//               ),
//               * */
//
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }