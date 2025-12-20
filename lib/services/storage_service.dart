// lib/services/storage_service.dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
// We no longer need path_provider or flutter_image_compress

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- THIS IS NOW A MUCH SIMPLER FUNCTION ---
  // It just uploads whatever file it is given.
  // The compression will now happen in the ScanScreen.
  Future<String> uploadMealImage(File imageFile) async {
    try {
      print('Uploading file size: ${await imageFile.length()} bytes');

      final String userId = _auth.currentUser!.uid;
      final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final String path = 'meals/$userId/$fileName.jpg';
      final Reference storageRef = _storage.ref().child(path);

      // Upload the file (it's already compressed!)
      final UploadTask uploadTask = storageRef.putFile(imageFile);

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;

    } catch (e) {
      print("Error uploading image: $e");
      throw Exception("Image upload failed.");
    }
  }
}