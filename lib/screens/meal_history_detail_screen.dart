// lib/screens/meal_history_detail_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth_gate.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';
//import 'main_screen.dart';

class MealHistoryDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? mealData;
  final File? imageFile;
  final String? aiResponse;

  const MealHistoryDetailScreen({
    super.key,
    this.mealData,
    this.imageFile,
    this.aiResponse,
  });

  @override
  State<MealHistoryDetailScreen> createState() =>
      _MealHistoryDetailScreenState();
}

class _MealHistoryDetailScreenState extends State<MealHistoryDetailScreen> {
  List<dynamic> _foodItems = [];
  bool _isLoading = false;

  // Colors
  final Color mainTextColor = const Color(0xFF5F7E5B);
  final Color cardBgColor = const Color(0xFFF6F5F0);

  @override
  void initState() {
    super.initState();
    _parseAndInitializeData();
  }

  void _parseAndInitializeData() {
    List<dynamic> initialItems = [];

    if (widget.aiResponse != null) {
      try {
        String cleanJson = widget.aiResponse!
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        dynamic decoded = jsonDecode(cleanJson);

        if (decoded is List) {
          initialItems = decoded;
        } else if (decoded is Map && decoded.containsKey('food_items')) {
          initialItems = decoded['food_items'];
        } else if (decoded is Map && decoded.containsKey('items')) {
          initialItems = decoded['items'];
        }
      } catch (e) {
        print("Error parsing AI: $e");
        initialItems = [];
      }
    } else {
      initialItems = widget.mealData?['food_items'] ?? [];
    }

    List<dynamic> preparedItems = [];
    for (var item in initialItems) {
      Map<String, dynamic> newItem = Map.from(item);

      if (newItem['user_serving'] == null) {
        newItem['user_serving'] =
            (newItem['user_serving_count'] ?? 1).toDouble();
      }

      if (newItem['uuid'] == null) {
        newItem['uuid'] = DateTime.now().microsecondsSinceEpoch.toString() +
            "_" +
            (newItem['food_name'] ?? "x");
      }

      preparedItems.add(newItem);
    }

    setState(() => _foodItems = preparedItems);
  }

  // --- SERVING LOGIC ---
  void _updateServing(int index, double change) {
    setState(() {
      double current = (_foodItems[index]['user_serving'] ?? 1.0).toDouble();
      double newServing = current + change;
      if (newServing < 0.5) newServing = 0.5;
      _foodItems[index]['user_serving'] = newServing;
      _foodItems[index]['user_serving_count'] = newServing;
    });
  }

  // --- EDIT ITEM ---
  void _editItem(int index) {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => _buildInputDialog(
        title: "Correct Item",
        hint: "What is it actually?",
        controller: controller,
        onConfirm: () async {
          Navigator.pop(context);
          await _performCorrection(index, controller.text);
        },
      ),
    );
  }

  Future<void> _performCorrection(int index, String correction) async {
    setState(() => _isLoading = true); // This triggers the generic loader
    try {
      Map<String, dynamic> newResult = await ApiService().correctScan(
          widget.imageFile,
          _foodItems[index]['food_name'] ?? "Food",
          correction);

      newResult['user_serving'] = _foodItems[index]['user_serving'] ?? 1.0;
      newResult['user_serving_count'] = newResult['user_serving'];
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

  // --- ADD MISSING ITEM ---
  void _addMissingItem() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => _buildInputDialog(
        title: "Add Missing Food",
        hint: "What did we miss?",
        controller: controller,
        onConfirm: () async {
          Navigator.pop(context);
          await _performAddItem(controller.text);
        },
      ),
    );
  }

  Future<void> _performAddItem(String name) async {
    setState(() => _isLoading = true); // This triggers the generic loader
    try {
      Map<String, dynamic> newItem =
      await ApiService().correctScan(widget.imageFile, "nothing", name);

      newItem['user_serving'] = 1.0;
      newItem['user_serving_count'] = 1.0;
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

  // --- DELETE ITEM ---
  void _deleteItem(int index) {
    final deletedItem = _foodItems[index];
    setState(() {
      _foodItems.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Removed ${deletedItem['food_name']}"),
        duration: const Duration(seconds: 3),
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

  // --- SAVE MEAL (THE FIX 🛡️) ---
  void _saveMeal() async {
    // 1. Validation
    if (_foodItems.isEmpty) return;

    // 🛑 NO setState here. We show a BEAUTIFUL Dialog instead.

    // 2. 🎨 BEAUTIFUL UI DIALOG (The White Card)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Beautiful Green Spinner
              CircularProgressIndicator(color: Color(0xFF5F7E5B)),
              SizedBox(height: 25),
              // THE TEXT YOU WANTED
              Text(
                "Saving your meal...",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        String permanentUrl = "";

        if (widget.imageFile != null) {
          permanentUrl = await DatabaseService().uploadImage(widget.imageFile!);
        } else {
          permanentUrl = widget.mealData?['image_url'] ?? "";
        }

        await DatabaseService().saveMeal(
          uid: uid,
          foodItems: _foodItems,
          imageUrl: permanentUrl,
          mealType: "Scanned Meal",
        );

        if (mounted) {
          Navigator.pop(context); // Close the Beautiful Dialog
          _showSnack("Meal saved!", Colors.green);
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) =>  AuthGate()),
                  (route) => false);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close Dialog if error
        _showSnack("Error: $e", Colors.red);
      }
    }
  }

  // --- HELPERS ---
  Widget _buildInputDialog(
      {required String title,
        required String hint,
        required TextEditingController controller,
        required VoidCallback onConfirm}) {
    return AlertDialog(
      title: Text(title),
      content: TextField(
          controller: controller,
          decoration: InputDecoration(
              hintText: hint, border: const OutlineInputBorder())),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
        ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(backgroundColor: mainTextColor),
            child:
            const Text("Confirm", style: TextStyle(color: Colors.white))),
      ],
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (widget.imageFile != null) {
      imageWidget = Image.file(widget.imageFile!, fit: BoxFit.cover);
    } else if (widget.mealData != null && widget.mealData!['image_url'] != "") {
      imageWidget =
          Image.network(widget.mealData!['image_url'], fit: BoxFit.cover);
    } else {
      imageWidget = const Icon(Icons.image, size: 50, color: Colors.grey);
    }

    return Stack(
      children: [
        // 1. MAIN UI
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
              title: const Text("Meal Breakdown",
                  style: TextStyle(color: Colors.black)),
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black)),
          body: Column(
            children: [
              Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: imageWidget),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _foodItems.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _foodItems.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 30),
                        child: TextButton.icon(
                          onPressed: _addMissingItem,
                          icon: Icon(Icons.add_circle,
                              color: mainTextColor, size: 28),
                          label: Text("Add Missing Item",
                              style: TextStyle(
                                  color: mainTextColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                        ),
                      );
                    }
                    final item = _foodItems[index];
                    final key = Key(item['uuid'] ?? "key_$index");
                    return Dismissible(
                      key: key,
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(20)),
                        alignment: Alignment.centerRight,
                        child: const Icon(Icons.delete,
                            color: Colors.red, size: 30),
                      ),
                      onDismissed: (direction) => _deleteItem(index),
                      child: _buildFoodCard(item, index),
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _saveMeal,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: mainTextColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30))),
                    child: const Text("Save Meal",
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 2. GENERIC LOADER (For Editing only)
        // I CHANGED THE TEXT HERE SO "CONSULTING AI" IS GONE FOREVER 🚫
        if (_isLoading)
          Positioned.fill(
            child: Stack(
              children: [
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                  ),
                ),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 15,
                            offset: Offset(0, 5))
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                            color: Color(0xFF5F7E5B)),
                        const SizedBox(height: 20),
                        // 👇 TEXT CHANGED! "AI" IS GONE!
                        const Text(
                          "Processing Data...",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFoodCard(Map<String, dynamic> item, int index) {
    double servingFactor = (item['user_serving'] ?? 1.0).toDouble();
    num baseCals = item['calories_per_serving'] ?? 0;
    num baseProt = item['protein_per_serving'] ?? 0;
    num baseCarbs = item['carbs_per_serving'] ?? 0;
    num baseFat = item['fat_per_serving'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(item['food_name'] ?? "Unknown",
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 5),
                        InkWell(
                          onTap: () => _editItem(index),
                          child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.edit,
                                  size: 18, color: Colors.grey)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border:
                          Border.all(color: Colors.grey.withOpacity(0.3))),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                              onTap: () => _updateServing(index, -0.5),
                              child: Icon(Icons.remove_circle,
                                  size: 20, color: mainTextColor)),
                          const SizedBox(width: 8),
                          Text("$servingFactor x",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(width: 8),
                          InkWell(
                              onTap: () => _updateServing(index, 0.5),
                              child: Icon(Icons.add_circle,
                                  size: 20, color: mainTextColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 90),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${(baseCals * servingFactor).toStringAsFixed(0)} kcal",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: mainTextColor),
                      textAlign: TextAlign.end,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "per ${item['serving_unit'] ?? 'srv'}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.end,
                      maxLines: 2,
                      overflow:
                      TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey[300]),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacro(
                  "Protein",
                  "${(baseProt * servingFactor).toStringAsFixed(1)}g",
                  Colors.blue[100]!),
              _buildMacro(
                  "Carbs",
                  "${(baseCarbs * servingFactor).toStringAsFixed(1)}g",
                  Colors.orange[100]!),
              _buildMacro(
                  "Fat",
                  "${(baseFat * servingFactor).toStringAsFixed(1)}g",
                  Colors.red[100]!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacro(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: color.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text(label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))
      ]),
    );
  }
}