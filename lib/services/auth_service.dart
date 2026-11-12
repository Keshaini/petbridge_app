
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static const String roleCommunity = 'community';
  static const String roleShelter = 'shelter';

  static String? _cachedRole;
  static String? _cachedRoleUid;

  static String get currentUid => _auth.currentUser?.uid ?? 'guest';

  static bool get isLoggedIn => _auth.currentUser != null;

  static String roleForUserType(String userType) {
    return (userType == 'shelter' || userType == 'vet')
        ? roleShelter
        : roleCommunity;
  }

  static Future<void> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    String userType = 'owner',
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final role = roleForUserType(userType);

    await _firestore.collection('users').doc(cred.user!.uid).set({
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'userType': userType,
      'role': role,
      'trustScore': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _cachedRole = role;
    _cachedRoleUid = cred.user!.uid;
  }

  static Future<void> signIn(String email, String password) async {
    clearRoleCache();

    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Google authentication for Chrome and Android.
  ///
  /// New accounts receive the supplied user type.
  /// Existing Firestore profiles keep their current role.
  static Future<UserCredential?> signInWithGoogle({
    String userType = 'owner',
  }) async {
    clearRoleCache();

    UserCredential credential;

    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      provider.addScope('email');

      credential = await _auth.signInWithPopup(provider);
    } else {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      final GoogleSignInAccount? googleUser =
          await googleSignIn.signIn();

      // The user closed the Google account selection screen.
      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final oauthCredential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      credential = await _auth.signInWithCredential(
        oauthCredential,
      );
    }

    final user = credential.user;

    if (user == null) {
      throw Exception('Google authentication failed.');
    }

    await _createGoogleUserProfile(
      user: user,
      userType: userType,
    );

    return credential;
  }

  /// Create a Firestore profile only when one does not already exist.
  /// Existing user roles and profile information are preserved.
  static Future<void> _createGoogleUserProfile({
    required User user,
    required String userType,
  }) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    final userDoc = await userRef.get();

    if (userDoc.exists) {
      final data = userDoc.data() ?? {};

      String role = (data['role'] as String?) ?? roleCommunity;

      // Support older profiles that have userType but no role.
      if (data['role'] == null && data['userType'] is String) {
        role = roleForUserType(data['userType'] as String);

        await userRef.update({'role': role});
      }

      _cachedRole = role;
      _cachedRoleUid = user.uid;
      return;
    }

    final role = roleForUserType(userType);

    await userRef.set({
      'name': user.displayName ?? 'PetBridge User',
      'email': user.email ?? '',
      'phone': user.phoneNumber ?? '',
      'userType': userType,
      'role': role,
      'trustScore': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _cachedRole = role;
    _cachedRoleUid = user.uid;
  }

  static Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  static Future<void> signOut() async {
    clearRoleCache();

    if (!kIsWeb) {
      try {
        await GoogleSignIn().signOut();
      } catch (_) {
        // Firebase sign-out should still proceed.
      }
    }

    await _auth.signOut();
  }

  static Future<String> getRole() async {
    final uid = currentUid;

    if (uid == 'guest') return roleCommunity;

    if (_cachedRoleUid == uid && _cachedRole != null) {
      return _cachedRole!;
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      final data = doc.data() ?? {};

      String role = (data['role'] as String?) ?? roleCommunity;

      if (data['role'] == null && data['userType'] is String) {
        role = roleForUserType(data['userType'] as String);
      }

      _cachedRole = role;
      _cachedRoleUid = uid;

      return role;
    } catch (_) {
      return roleCommunity;
    }
  }

  static Future<bool> isShelter() async {
    return (await getRole()) == roleShelter;
  }

  static void clearRoleCache() {
    _cachedRole = null;
    _cachedRoleUid = null;
  }

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
        case 'popup-closed-by-user':
          return 'Google sign-in was cancelled.';
        case 'popup-blocked':
          return 'The Google sign-in popup was blocked. Please allow popups.';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled in Firebase.';
        default:
          return e.message ?? 'Something went wrong.';
      }
    }

    return 'Something went wrong. Please try again.';
  }
}
