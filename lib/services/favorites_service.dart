
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitlens/services/recipe_service.dart';


class FavoritesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;


  // 1. Add to Favorites (Red Star)
// 1. Add to Favorites (Red Star)
  Future<void> addFavorite(Recipe recipe) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    // 1. Get the normal recipe data
    Map<String, dynamic> data = recipe.toJson();

    // 2. 🔑 INSERT THE VIP PASSWORD HERE
    // The database will reject the save if this specific line is missing!
    data['app_secret'] = "FitLens_VIP_2025";

    // 3. Save to Firebase
    await _db
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(recipe.title)
        .set(data); // ✅ We save 'data' (which now includes the secret)
  }
  // 2. Remove from Favorites (Empty Star)
  Future<void> removeFavorite(String recipeTitle) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(recipeTitle)
        .delete();
  }

  // 3. Check if Recipe is Favorite (For coloring the star)
  Future<bool> isFavorite(String recipeTitle) async {
    User? user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _db
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(recipeTitle)
        .get();

    return doc.exists;
  }

  // 4. Get All Favorites (For the Favorites Page)
  Stream<List<Recipe>> getFavoritesStream() {
    User? user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Recipe.fromJson(doc.data()))
        .toList());
  }
}