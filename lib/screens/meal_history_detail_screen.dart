// lib/screens/meal_history_detail_screen.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../services/api_service.dart'; // Ensure this is imported for Edit/Add features
import 'main_screen.dart'; // Ensure this is imported for navigation

class MealHistoryDetailScreen extends StatefulWidget {
  // We keep the constructor compatible with your App's flow
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
  State<MealHistoryDetailScreen> createState() => _MealHistoryDetailScreenState();
}

class _MealHistoryDetailScreenState extends State<MealHistoryDetailScreen> {
  List<dynamic> _foodItems = [];
  bool _isLoading = false;

  // Colors from your design
  final Color mainTextColor = const Color(0xFF5F7E5B);
  final Color cardBgColor = const Color(0xFFF6F5F0);

  @override
  void initState() {
    super.initState();
    _parseAndInitializeData();
  }

  // 🧠 THE ROBUST PARSER (New Logic) + UUID GENERATION (Old Design Requirement)
  void _parseAndInitializeData() {
    List<dynamic> initialItems = [];

    // 1. Determine Source (AI or History)
    if (widget.aiResponse != null) {
      // --- SCAN MODE ---
      try {
        print("RAW AI RESPONSE: ${widget.aiResponse}");
        String cleanJson = widget.aiResponse!.replaceAll('```json', '').replaceAll('```', '').trim();
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
      // --- HISTORY MODE ---
      initialItems = widget.mealData?['food_items'] ?? [];
    }

    // 2. Prepare Items for the UI (Add UUIDs and Servings)
    // We use 'user_serving' (double) to match your Old Design (0.5, 1.0, 1.5)
    List<dynamic> preparedItems = [];
    for (var item in initialItems) {
      Map<String, dynamic> newItem = Map.from(item);

      // Default serving to 1.0 if missing
      if (newItem['user_serving'] == null) {
        newItem['user_serving'] = (newItem['user_serving_count'] ?? 1).toDouble();
      }

      // Generate UUID for Dismissible if missing
      if (newItem['uuid'] == null) {
        newItem['uuid'] = DateTime.now().microsecondsSinceEpoch.toString() + "_" + (newItem['food_name'] ?? "x");
      }

      preparedItems.add(newItem);
    }

    setState(() => _foodItems = preparedItems);
  }

  // --- 1. SERVING LOGIC (0.5 increments from Old Design) ---
  void _updateServing(int index, double change) {
    setState(() {
      double current = (_foodItems[index]['user_serving'] ?? 1.0).toDouble();
      double newServing = current + change;
      if (newServing < 0.5) newServing = 0.5; // Minimum 0.5 serving
      _foodItems[index]['user_serving'] = newServing;
      // Sync strictly for DB compatibility
      _foodItems[index]['user_serving_count'] = newServing;
    });
  }

  // --- 2. EDIT EXISTING ITEM (Calls API) ---
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
      // We assume ApiService has correctScan. If not, this part will need adjustment.
      Map<String, dynamic> newResult = await ApiService().correctScan(
          widget.imageFile, // Might be null in history mode, handled by API?
          _foodItems[index]['food_name'] ?? "Food",
          correction
      );

      // Preserve serving and UUID
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
      _showSnack("Failed to correct (AI unavailable): $e", Colors.red);
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

  // --- 4. SWIPE TO DELETE (Undo Feature) ---
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

  // --- 5. SAVE LOGIC (Connects to DatabaseService) ---
  void _saveMeal() async {
    if (_foodItems.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        String permanentUrl = "";

        // Logic: Use existing URL if history, upload if new file
        if (widget.imageFile != null) {
          // Calls the DatabaseService upload we made earlier
          permanentUrl = await DatabaseService().uploadImage(widget.imageFile!);
        } else {
          permanentUrl = widget.mealData?['image_url'] ?? "";
        }

        // Save to DB
        await DatabaseService().saveMeal(
          uid: uid,
          foodItems: _foodItems,
          imageUrl: permanentUrl,
          mealType: "Scanned Meal",
        );

        if (mounted) {
          _showSnack("Meal saved!", Colors.green);
          // Navigate back to MainScreen to refresh
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MainScreen()), (route) => false);
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
      content: TextField(controller: controller, decoration: InputDecoration(hintText: hint, border: const OutlineInputBorder())),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
        ElevatedButton(onPressed: onConfirm, style: ElevatedButton.styleFrom(backgroundColor: mainTextColor), child: const Text("Confirm", style: TextStyle(color: Colors.white))),
      ],
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    // Determine Image to show
    Widget imageWidget;
    if (widget.imageFile != null) {
      imageWidget = Image.file(widget.imageFile!, fit: BoxFit.cover);
    } else if (widget.mealData != null && widget.mealData!['image_url'] != "") {
      imageWidget = Image.network(widget.mealData!['image_url'], fit: BoxFit.cover);
    } else {
      imageWidget = const Icon(Icons.image, size: 50, color: Colors.grey);
    }

    return Stack( // 👈 1. USE STACK
      children: [
        // 2. THE MAIN CONTENT (Your existing Scaffold)
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
              title: const Text("Meal Breakdown", style: TextStyle(color: Colors.black)),
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black)
          ),
          body: Column(
            children: [
              // Image
              Container(height: 200, width: double.infinity, color: Colors.grey[200], child: imageWidget),

              // List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _foodItems.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _foodItems.length) {
                      // Add Button
                      return Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 30),
                        child: TextButton.icon(
                          onPressed: _addMissingItem,
                          icon: Icon(Icons.add_circle, color: mainTextColor, size: 28),
                          label: Text("Add Missing Item", style: TextStyle(color: mainTextColor, fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      );
                    }
                    // Food Card (Existing logic)
                    final item = _foodItems[index];
                    final key = Key(item['uuid'] ?? "key_$index");
                    return Dismissible(
                      key: key,
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(20)),
                        alignment: Alignment.centerRight,
                        child: const Icon(Icons.delete, color: Colors.red, size: 30),
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
                    child: const Text("Save Meal", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 3. THE GLASS LOADER OVERLAY 🕵️‍♂️
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.5), // Semi-transparent black
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: mainTextColor),
                    const SizedBox(height: 15),
                    const Text("AI is thinking... 🧠", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
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
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis
                          ),
                        ),
                        const SizedBox(width: 5),
                        InkWell(
                          onTap: () => _editItem(index),
                          child: const Padding(padding: EdgeInsets.all(4.0), child: Icon(Icons.edit, size: 18, color: Colors.grey)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Compact Counter
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.withOpacity(0.3))),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                              onTap: () => _updateServing(index, -0.5),
                              child: Icon(Icons.remove_circle, size: 20, color: mainTextColor)
                          ),
                          const SizedBox(width: 8),
                          Text(
                              "$servingFactor x",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                          ),
                          const SizedBox(width: 8),
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

              const SizedBox(width: 8), // Small gap between left and right

              // RIGHT: Calories (Now Constrained!)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 90),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${(baseCals * servingFactor).toStringAsFixed(0)} kcal",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: mainTextColor),
                      textAlign: TextAlign.end,
                    ),
                    const SizedBox(height: 5),
                    // This text caused the overflow. Now it will wrap safely.
                    Text(
                      "per ${item['serving_unit'] ?? 'srv'}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.end,
                      maxLines: 2, // Allow it to wrap to 2 lines
                      overflow: TextOverflow.ellipsis, // Add "..." if still too long
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.3), borderRadius: BorderRadius.circular(10)),
      child: Column(children: [Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)), const SizedBox(height: 2), Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))]),
    );
  }
}