// lib/screens/profile/habits_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/calculator.dart'; // 🧠 The Brain

class HabitsScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const HabitsScreen({super.key, required this.data});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  double _exerciseHours = 3.0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Load existing exercise hours or default to 3
    _exerciseHours = (widget.data['weekly_exercise_hours'] ?? 3.0).toDouble();
  }

  Future<void> _saveHabits() async {
    setState(() => _isSaving = true);
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      // 1. Get Weight (FIX: Cast to double, not int)
      double weight = (widget.data['weight'] ?? 70.0).toDouble();

      // 2. 🧠 Recalculate Water based on NEW Habits
      // We divide weekly hours by 7 to get "Daily Average Exercise" for the formula
      double dailyExercise = _exerciseHours / 7;

      double newWater = Calculator.calculateWater(
          weightKg: weight, // Now passing double
          exerciseHours: dailyExercise
      );

      // 3. Save to DB
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'weekly_exercise_hours': _exerciseHours,
        'target_water': (newWater * 1000).round(), // Convert L to mL
        'app_secret': 'FitLens_VIP_2025',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Water goals updated! 💧"), backgroundColor: Colors.blueAccent));
        Navigator.pop(context);
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text("HABITS", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveHabits,
            child: const Text("Save", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Weekly Exercise", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text("Hours per week: ${_exerciseHours.toStringAsFixed(1)} h", style: const TextStyle(color: Colors.grey)),

              const SizedBox(height: 20),

              // SLIDER
              Slider(
                value: _exerciseHours,
                min: 0,
                max: 20,
                divisions: 40, // Allows 0.5 increments
                activeColor: Colors.blueAccent,
                label: "${_exerciseHours} h",
                onChanged: (val) => setState(() => _exerciseHours = val),
              ),

              const SizedBox(height: 10),
              const Text("⚠️ Increasing exercise will increase your daily water recommendation.", style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      ),
    );
  }
}