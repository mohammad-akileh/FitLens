import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get user => _auth.authStateChanges();

  // --- SIGN UP WITH EMAIL (Keep as is) ---
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

  // --- SIGN IN WITH EMAIL (Keep as is) ---
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

  // --- 🔴 UPDATED SELF-HEALING GOOGLE SIGN IN ---
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User canceled

      // 2. Obtain the auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 3. Sign in to Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      // 4. 🛡️ SELF-HEALING DATABASE LOGIC
      // Instead of relying on "isNewUser", we explicitly check the database.
      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();

        if (!userDoc.exists) {
          // If the document is missing (because internet failed last time), create it now!
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

  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}