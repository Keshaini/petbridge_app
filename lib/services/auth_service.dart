import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Real user ID, or 'guest' if nobody is logged in.
  static String get currentUid => _auth.currentUser?.uid ?? 'guest';

  static bool get isLoggedIn => _auth.currentUser != null;

  /// CREATE: register a user and save their profile in Firestore.
  static Future<void> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await FirebaseFirestore.instance
        .collection('users')
        .doc(cred.user!.uid)
        .set({
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'trustScore': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// READ: log in.
  static Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Turns Firebase error codes into readable messages.
  static String message(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'That email is already registered.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'Password must be at least 6 characters.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'network-request-failed':
          return 'No internet connection.';
        default:
          return e.message ?? 'Something went wrong.';
      }
    }
    return 'Something went wrong.';
  }
}