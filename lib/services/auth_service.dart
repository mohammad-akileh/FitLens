// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- IMPORT FIRESTORE

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // <-- ADD FIRESTORE

  Stream<User?> get user => _auth.authStateChanges();

  // --- UPDATED SIGN UP METHOD ---
  Future<void> signUpWithEmail(String name, String email, String password) async {
    try {
      // 1. Create the user in Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        // 2. IMMEDIATELY create their user document in Firestore
        //    This is where we save the name!
        await _firestore.collection('users').doc(user.uid).set({
          'name': name,
          'email': email,
          'created_at': FieldValue.serverTimestamp(),
        });

        // 3. Send verification email
        await user.sendEmailVerification();
      }

      // 4. Sign them out (so they have to verify to log in)
      await _auth.signOut();

    } on FirebaseAuthException catch (e) {
      throw e;
    }
  }

  // --- UPDATED SIGN IN METHOD ---
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
          message: 'Please verify your email before logging in. We sent a link to $email',
        );
      }

      return userCredential;

    } on FirebaseAuthException catch (e) {
      throw e;
    }
  }

  // --- UPDATED GOOGLE SIGN IN METHOD ---
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // User canceled
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // 3. Check if this is a NEW Google user
        final bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

        if (isNewUser) {
          // 4. If they are new, create their Firestore document
          //    This is where we get their Google Name!
          await _firestore.collection('users').doc(user.uid).set({
            'name': user.displayName ?? 'Google User', // Use Google name
            'email': user.email,
            'created_at': FieldValue.serverTimestamp(),
          });
        }
      }

      return userCredential;

    } on FirebaseAuthException catch (e) {
      throw e;
    }
  }

  // --- (Your sendPasswordResetEmail and signOut functions stay the same) ---

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw e;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}