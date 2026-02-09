import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/user_model.dart';
import 'shared_prefs_service.dart';

class AuthService with ChangeNotifier {
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Services
  final SharedPrefsService _sharedPrefs = SharedPrefsService();

  // Current user state
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isAuthenticating = false;

  // =========================
  // GETTERS
  // =========================
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticating => _isAuthenticating;

  // Raw Firebase user
  User? get firebaseUser => _auth.currentUser;
  String? get userId => _auth.currentUser?.uid;
  String? get userEmail => _auth.currentUser?.email;

  // ✅ New: Unified user getter as UserModel
  UserModel? get user {
    if (_currentUser != null) return _currentUser;

    final fbUser = _auth.currentUser;
    if (fbUser != null) {
      return UserModel(
        uid: fbUser.uid,
        email: fbUser.email ?? '',
        name: fbUser.displayName ?? 'Fitness Pro',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    return null;
  }

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // =========================
  // 🔹 INITIALIZE SERVICE
  // =========================
  Future<void> initialize() async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_auth.currentUser != null) {
        await _loadCurrentUser(_auth.currentUser!.uid);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('AuthService initialization error: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // =========================
  // 🔹 SIGN UP
  // =========================
  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      _isAuthenticating = true;
      notifyListeners();

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) throw Exception('Failed to create user');

      final user = UserModel(
        uid: firebaseUser.uid,
        email: email.trim(),
        name: name.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(firebaseUser.uid).set(user.toMap());
      
      // ✅ Force Sign Out after creation to match "Signup -> Login" flow requirement
      await _auth.signOut();
      await _sharedPrefs.setLoggedIn(false);
      
      _isAuthenticating = false;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      _isAuthenticating = false;
      notifyListeners();
      return _getErrorMessage(e);
    } catch (e) {
      _isAuthenticating = false;
      notifyListeners();
      return 'An unexpected error occurred. Please try again.';
    }
  }

  // =========================
  // 🔹 LOGIN
  // =========================
  Future<String?> login({required String email, required String password}) async {
    try {
      _isAuthenticating = true;
      notifyListeners();

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) throw Exception('Failed to sign in user');

      await _loadCurrentUser(firebaseUser.uid);
      await _sharedPrefs.setLoggedIn(true);

      _isAuthenticating = false;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      _isAuthenticating = false;
      notifyListeners();
      return _getErrorMessage(e);
    } catch (e) {
      _isAuthenticating = false;
      notifyListeners();
      return 'An unexpected error occurred. Please try again.';
    }
  }

  // =========================
  // 🔹 SIGN OUT
  // =========================
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _auth.signOut();
      await _sharedPrefs.setLoggedIn(false);
      await _sharedPrefs.clearUserProfile();

      _currentUser = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error signing out: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // =========================
  // 🔹 LOAD CURRENT USER
  // =========================
  Future<void> _loadCurrentUser(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      _currentUser = UserModel.fromDocument(doc);
    } else {
      _currentUser = UserModel(
        uid: userId,
        email: _auth.currentUser?.email ?? '',
        name: _auth.currentUser?.displayName ?? 'Fitness Pro',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _firestore.collection('users').doc(userId).set(_currentUser!.toMap());
    }

    if (_currentUser != null) await _sharedPrefs.saveUserProfile(_currentUser!.toMap());
    notifyListeners();
  }

  // =========================
  // 🔹 ERROR MESSAGE HANDLER
  // =========================
  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      default:
        return 'Error: ${e.message}';
    }
  }
}
