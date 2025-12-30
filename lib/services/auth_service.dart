// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get user => _auth.authStateChanges();

  // --- SIGN UP WITH EMAIL ---
  Future<void> signUpWithEmail(String name, String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'name': name,
          'email': email,
          'created_at': FieldValue.serverTimestamp(),
          'app_secret': 'FitLens_VIP_2025',
        });
        await user.sendEmailVerification();
      }
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw e;
    }
  }

  // --- SIGN IN WITH EMAIL ---
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message: 'Please verify your email before logging in.',
        );
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw e;
    }
  }

  // --- GOOGLE SIGN IN (Self-Healing) ---
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'name': user.displayName ?? 'Google User',
            'email': user.email,
            'created_at': FieldValue.serverTimestamp(),
            'app_secret': 'FitLens_VIP_2025',
          });
        }
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Error: ${e.message}");
      throw e;
    } catch (e) {
      print("General Error: $e");
      rethrow;
    }
  }

  // --- SIGN OUT ---
  Future<void> signOut() async {
    try {
      try {
        await _googleSignIn.disconnect();
      } catch (e) {
        // Ignore errors if not logged in with Google
      }
      await _auth.signOut();
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  // --- 🔴 DELETE ACCOUNT (Fixes the Google Loop) ---
  Future<void> deleteAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // 1. Delete Firestore Data
        await _firestore.collection('users').doc(user.uid).delete();

        // 2. Disconnect Google
        // This is the MAGIC LINE. It forces the account picker to appear next time.
        try {
          await _googleSignIn.disconnect();
        } catch (e) {
          print("Google disconnect warning: $e");
        }

        // 3. Delete Auth Account
        await user.delete();
      }
    } on FirebaseAuthException catch (e) {
      // If error is "requires-recent-login", the UI needs to handle it
      throw e;
    } catch (e) {
      throw e;
    }
  }

  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}