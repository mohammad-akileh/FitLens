// lib/screens/dummy_test_screen.dart
import 'package:flutter/material.dart';
import 'home_design_screen.dart'; // We will create this next

class DummyTestScreen extends StatefulWidget {
  const DummyTestScreen({super.key});

  @override
  State<DummyTestScreen> createState() => _DummyTestScreenState();
}

class _DummyTestScreenState extends State<DummyTestScreen> {
  // Default values (Modify these to test "Red" warnings!)
  final _calsController = TextEditingController(text: "1250");
  final _targetCalsController = TextEditingController(text: "1800");

  final _protController = TextEditingController(text: "110");
  final _targetProtController = TextEditingController(text: "135");

  final _carbController = TextEditingController(text: "54");
  final _targetCarbController = TextEditingController(text: "180");

  final _fatController = TextEditingController(text: "70"); // <--- Try making this higher than target to see Red!
  final _targetFatController = TextEditingController(text: "60");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Debug: Fake Data Input")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            Text("Enter Fake Data to Test Home Screen:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),

            _buildRow("Calories", _calsController, _targetCalsController),
            _buildRow("Protein", _protController, _targetProtController),
            _buildRow("Carbs", _carbController, _targetCarbController),
            _buildRow("Fat", _fatController, _targetFatController),

            SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: () {
                // Navigate to the New Home Design with this data
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeDesignScreen(
                      currentCals: double.parse(_calsController.text),
                      targetCals: double.parse(_targetCalsController.text),
                      currentProt: double.parse(_protController.text),
                      targetProt: double.parse(_targetProtController.text),
                      currentCarb: double.parse(_carbController.text),
                      targetCarb: double.parse(_targetCarbController.text),
                      currentFat: double.parse(_fatController.text),
                      targetFat: double.parse(_targetFatController.text),
                    ),
                  ),
                );
              },
              child: Text("LAUNCH HOME DESIGN 🚀", style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, TextEditingController current, TextEditingController target) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: TextField(controller: current, decoration: InputDecoration(labelText: "Current", border: OutlineInputBorder()))),
          SizedBox(width: 10),
          Expanded(child: TextField(controller: target, decoration: InputDecoration(labelText: "Target", border: OutlineInputBorder()))),
        ],
      ),
    );
  }
}