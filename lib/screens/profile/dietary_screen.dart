import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/calculator.dart'; // 🧠 The Brain

class DietaryScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const DietaryScreen({super.key, required this.data});

  @override
  State<DietaryScreen> createState() => _DietaryScreenState();
}

class _DietaryScreenState extends State<DietaryScreen> {
  String _selectedDiet = 'Standard';
  bool _isSaving = false;

  final List<String> _dietOptions = ['Standard', 'Keto', 'High Protein', 'Vegan'];

  @override
  void initState() {
    super.initState();
    // Load existing preference or default to Standard
    _selectedDiet = widget.data['diet_type'] ?? 'Standard';
  }

  Future<void> _saveDietaryPrefs() async {
    setState(() => _isSaving = true);
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      
      // 1. Get current Calories (we aren't changing calories here, just the SPLIT)
      double currentCals = (widget.data['target_calories'] ?? 2000).toDouble();

      // 2. 🧠 Recalculate Macros based on NEW Diet
      Map<String, double> newMacros = Calculator.calculateMacros(
        currentCals, 
        dietType: _selectedDiet
      );

      // 3. Save to DB
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'diet_type': _selectedDiet,
        'target_protein': newMacros['protein']!.round(),
        'target_carbs': newMacros['carb']!.round(),
        'target_fat': newMacros['fat']!.round(),
        'app_secret': 'FitLens_VIP_2025',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Macros updated for your diet! 🥑"), backgroundColor: Colors.green));
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
        title: const Text("DIETARY PREFERENCES", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveDietaryPrefs,
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
              const Text("Select your active diet:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              ..._dietOptions.map((diet) => RadioListTile<String>(
                title: Text(diet),
                subtitle: Text(_getDietDescription(diet)),
                value: diet,
                groupValue: _selectedDiet,
                activeColor: Colors.green,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _selectedDiet = val!),
              )),
            ],
          ),
        ),
      ),
    );
  }

  String _getDietDescription(String diet) {
    switch (diet) {
      case 'Keto': return "High fat, very low carbs.";
      case 'High Protein': return "Best for building muscle.";
      case 'Vegan': return "Plant-based, higher carbs.";
      default: return "Balanced mix of all nutrients.";
    }
  }
}
