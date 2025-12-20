// lib/screens/meal_details_screen.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database_service.dart';
import '../../services/api_service.dart';
import 'main_screen.dart';

class MealDetailsScreen extends StatefulWidget {
  final String? imageUrl;
  final File? imageFile;
  final String aiResponse;

  const MealDetailsScreen({
    super.key,
    this.imageUrl,
    this.imageFile,
    required this.aiResponse,
  });

  @override
  State<MealDetailsScreen> createState() => _MealDetailsScreenState();
}

class _MealDetailsScreenState extends State<MealDetailsScreen> {
  List<dynamic> _foodItems = [];
  bool _isLoading = false;

  final Color mainTextColor = const Color(0xFF5F7E5B);
  final Color cardBgColor = const Color(0xFFF6F5F0);

  @override
  void initState() {
    super.initState();
    _parseResponse();
  }

  void _parseResponse() {
    try {
      print("RAW AI RESPONSE: ${widget.aiResponse}");
      String cleanJson = widget.aiResponse.replaceAll('```json', '').replaceAll('```', '').trim();
      dynamic decoded = jsonDecode(cleanJson);

      List<dynamic> initialItems = [];
      if (decoded is List) {
        initialItems = decoded;
      } else if (decoded is Map && decoded.containsKey('items')) {
        initialItems = decoded['items'];
      }

      // Initialize 'user_serving' AND UNIQUE ID for Dismissible
      for (var item in initialItems) {
        item['user_serving'] = 1.0;
        // Create a unique ID to prevent the Red Screen Error
        item['uuid'] = DateTime.now().microsecondsSinceEpoch.toString() + "_" + (item['food_name'] ?? "x");
      }

      setState(() => _foodItems = initialItems);

    } catch (e) {
      print("Error parsing: $e");
    }
  }

  // --- 1. SERVING LOGIC ---
  void _updateServing(int index, double change) {
    setState(() {
      double current = _foodItems[index]['user_serving'] ?? 1.0;
      double newServing = current + change;
      if (newServing < 0.5) newServing = 0.5; // Minimum 0.5 serving
      _foodItems[index]['user_serving'] = newServing;
    });
  }

  // --- 2. EDIT EXISTING ITEM ---
  void _editItem(int index) {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => _buildInputDialog(
        title: "Correct Item",
        hint: "What is it actually? (e.g. 'Avocado Toast')",
        controller: controller,
        onConfirm: () async {
          Navigator.pop(context);
          await _performCorrection(index, controller.text);
        },
      ),
    );
  }

  Future<void> _performCorrection(int index, String correction) async {
    setState(() => _isLoading = true);
    try {
      Map<String, dynamic> newResult = await ApiService().correctScan(
          widget.imageFile,
          _foodItems[index]['food_name'] ?? "Food",
          correction
      );

      // Preserve serving and UUID
      newResult['user_serving'] = _foodItems[index]['user_serving'] ?? 1.0;
      newResult['uuid'] = _foodItems[index]['uuid'];

      setState(() {
        _foodItems[index] = newResult;
        _isLoading = false;
      });
      _showSnack("Updated to $correction", Colors.green);

    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack("Failed to correct: $e", Colors.red);
    }
  }

  // --- 3. ADD MISSING ITEM ---
  void _addMissingItem() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => _buildInputDialog(
        title: "Add Missing Food",
        hint: "What did we miss? (e.g. 'Diet Coke')",
        controller: controller,
        onConfirm: () async {
          Navigator.pop(context);
          await _performAddItem(controller.text);
        },
      ),
    );
  }

  Future<void> _performAddItem(String name) async {
    setState(() => _isLoading = true);
    try {
      Map<String, dynamic> newItem = await ApiService().correctScan(
          widget.imageFile,
          "nothing",
          name
      );

      newItem['user_serving'] = 1.0;
      // Important: Add a unique ID for the new item too!
      newItem['uuid'] = DateTime.now().microsecondsSinceEpoch.toString();

      setState(() {
        _foodItems.add(newItem);
        _isLoading = false;
      });
      _showSnack("Added $name", Colors.green);

    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack("Failed to add: $e", Colors.red);
    }
  }

  // --- 4. SWIPE TO DELETE (Undo Feature) ---
  void _deleteItem(int index) {
    final deletedItem = _foodItems[index];
    setState(() {
      _foodItems.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Removed ${deletedItem['food_name']}"),
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: "UNDO",
          textColor: Colors.orange,
          onPressed: () {
            setState(() {
              _foodItems.insert(index, deletedItem);
            });
          },
        ),
      ),
    );
  }

  // --- 5. SAVE LOGIC ---
  void _saveMeal() async {
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        String permanentUrl = "";

        // Upload image
        if (widget.imageFile != null) {
          permanentUrl = await DatabaseService().uploadImage(widget.imageFile!);
        }

        // Save to DB
        await DatabaseService().saveMeal(
          uid: uid,
          foodItems: _foodItems,
          imageUrl: permanentUrl,
        );

        if (mounted) {
          _showSnack("Meal saved!", Colors.green);
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => MainScreen()), (route) => false);
        }
      }
    } catch (e) {
      if (mounted) _showSnack("Error: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- HELPERS ---
  Widget _buildInputDialog({required String title, required String hint, required TextEditingController controller, required VoidCallback onConfirm}) {
    return AlertDialog(
      title: Text(title),
      content: TextField(controller: controller, decoration: InputDecoration(hintText: hint, border: OutlineInputBorder())),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: TextStyle(color: Colors.grey))),
        ElevatedButton(onPressed: onConfirm, style: ElevatedButton.styleFrom(backgroundColor: mainTextColor), child: Text("Confirm", style: TextStyle(color: Colors.white))),
      ],
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text("Meal Breakdown"), backgroundColor: Colors.white, elevation: 0),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: mainTextColor))
          : Column(
        children: [
          // Image Preview
          Container(
            height: 200, width: double.infinity, color: Colors.grey[200],
            child: widget.imageFile != null ? Image.file(widget.imageFile!, fit: BoxFit.cover) : Icon(Icons.image),
          ),

          // List of Items
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _foodItems.length + 1, // +1 for the Add Button
              itemBuilder: (context, index) {
                // Add Button (Last Item)
                if (index == _foodItems.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 30),
                    child: TextButton.icon(
                      onPressed: _addMissingItem,
                      icon: Icon(Icons.add_circle, color: mainTextColor, size: 28),
                      label: Text("Add Missing Item", style: TextStyle(color: mainTextColor, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  );
                }

                // Food Card
                final item = _foodItems[index];
                // USE THE UUID AS THE KEY! (This fixes the red screen)
                final key = Key(item['uuid'] ?? "key_$index");

                return Dismissible(
                  key: key,
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: EdgeInsets.only(bottom: 15),
                    padding: EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(20)),
                    alignment: Alignment.centerRight,
                    child: Icon(Icons.delete, color: Colors.red, size: 30),
                  ),
                  onDismissed: (direction) => _deleteItem(index),
                  child: _buildFoodCard(item, index),
                );
              },
            ),
          ),

          // Save Button
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(
                onPressed: _saveMeal,
                style: ElevatedButton.styleFrom(backgroundColor: mainTextColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                child: Text("Save Meal", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodCard(Map<String, dynamic> item, int index) {
    double servingFactor = item['user_serving'] ?? 1.0;

    num baseCals = item['calories_per_serving'] ?? 0;
    num baseProt = item['protein_per_serving'] ?? 0;
    num baseCarbs = item['carbs_per_serving'] ?? 0;
    num baseFat = item['fat_per_serving'] ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT: Name & Controls (Expanded takes all remaining space)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + Edit Pencil
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                              item['food_name'] ?? "Unknown",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis
                          ),
                        ),
                        SizedBox(width: 5),
                        InkWell(
                          onTap: () => _editItem(index),
                          child: Padding(padding: const EdgeInsets.all(4.0), child: Icon(Icons.edit, size: 18, color: Colors.grey)),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),

                    // Compact Counter
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.withOpacity(0.3))),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                              onTap: () => _updateServing(index, -0.5),
                              child: Icon(Icons.remove_circle, size: 20, color: mainTextColor)
                          ),
                          SizedBox(width: 8),
                          Text(
                              "$servingFactor x",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                          ),
                          SizedBox(width: 8),
                          InkWell(
                              onTap: () => _updateServing(index, 0.5),
                              child: Icon(Icons.add_circle, size: 20, color: mainTextColor)
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: 8), // Small gap between left and right

              // RIGHT: Calories (Now Constrained!)
              // We wrap this in a constrained box so it never grows wider than 90px
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 90),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${(baseCals * servingFactor).toStringAsFixed(0)} kcal",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: mainTextColor),
                      textAlign: TextAlign.end,
                    ),
                    SizedBox(height: 5),
                    // This text caused the overflow. Now it will wrap safely.
                    Text(
                      "per ${item['serving_unit'] ?? 'srv'}",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.end,
                      maxLines: 2, // Allow it to wrap to 2 lines
                      overflow: TextOverflow.ellipsis, // Add "..." if still too long
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Divider(color: Colors.grey[300]),
          // MACROS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacro("Protein", "${(baseProt * servingFactor).toStringAsFixed(1)}g", Colors.blue[100]!),
              _buildMacro("Carbs", "${(baseCarbs * servingFactor).toStringAsFixed(1)}g", Colors.orange[100]!),
              _buildMacro("Fat", "${(baseFat * servingFactor).toStringAsFixed(1)}g", Colors.red[100]!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacro(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.3), borderRadius: BorderRadius.circular(10)),
      child: Column(children: [Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)), SizedBox(height: 2), Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))]),
    );
  }
}