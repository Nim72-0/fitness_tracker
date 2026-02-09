// lib/providers/profile_provider.dart
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart'; // Use XFile
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/shared_prefs_service.dart';

class ProfileProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final SharedPrefsService _sharedPrefs;

  UserModel? _user;
  XFile? _profileImage;

  bool _isLoading = false;
  bool _isSaving = false;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;

  UserModel? get user => _user;
  String? get uid => _user?.uid;
  XFile? get profileImage => _profileImage;

  String get name => _user?.name ?? 'New User';
  int get age => _user?.age ?? 0;
  double get height => _user?.height ?? 0;
  double get weight => _user?.weight ?? 0;
  String get gender => _user?.gender ?? 'Male'; 
  String get goal => _user?.goal ?? 'weight_loss';
  String? get profileImageUrl => _user?.profileImageUrl;

  ProfileProvider({
    required FirestoreService firestoreService,
    required SharedPrefsService sharedPrefs,
  })  : _firestoreService = firestoreService,
        _sharedPrefs = sharedPrefs;

  void setUserId(String uid) {
    if (uid.isEmpty) return;
    if (_user == null || _user!.uid != uid) {
      _user = UserModel(uid: uid, email: '', name: '');
      loadProfileData();
    }
  }

  Future<void> loadProfileData() async {
    if (_user == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final cachedUser = _sharedPrefs.getUserProfile();
      if (cachedUser != null) {
        _user = UserModel.fromMap(cachedUser);
        notifyListeners();
      }

      final firestoreUser = await _firestoreService.getUserProfile(_user!.uid);
      if (firestoreUser != null) {
        _user = firestoreUser;
        await _sharedPrefs.saveUserProfile(firestoreUser.toMap());
      }
    } catch (e) {
      debugPrint('Error loading profile data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> updateProfile({
    required String name,
    required int age,
    required double height,
    required double weight,
    required String gender,
    required String goal,
  }) async {
    // Auto-recover user from Firebase Auth if _user is null
    if (_user == null) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        setUserId(currentUser.uid);
      } else {
        return 'User not logged in';
      }
    }

    _isSaving = true;
    notifyListeners();

    try {
      final updatedUser = _user!.copyWith(
        name: name,
        age: age,
        height: height,
        weight: weight,
        gender: gender,
        goal: goal,
        updatedAt: DateTime.now(),
      );

      // Save to Firestore first
      await _firestoreService.updateUser(updatedUser);
      
      // Save locally using JSON-safe map
      await _sharedPrefs.saveUserProfile(updatedUser.toSharedPrefsMap());

      _user = updatedUser;
      return null; // Success
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return e.toString(); // Return specific error
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> updateProfileImage(XFile image) async {
    // Auto-recover user from Firebase Auth if _user is null
    if (_user == null) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        setUserId(currentUser.uid);
      } else {
        return;
      }
    }

    if (_user == null) return;

    _profileImage = image;
    notifyListeners();

    try {
      final bytes = await image.readAsBytes();
      final imageUrl = await _firestoreService.uploadProfileImage(_user!.uid, bytes);
      
      if (imageUrl != null) {
        // Update user model with new URL
        final updatedUser = _user!.copyWith(
          profileImageUrl: imageUrl,
          updatedAt: DateTime.now(),
        );
        await _firestoreService.updateUser(updatedUser);
        await _sharedPrefs.saveUserProfile(updatedUser.toSharedPrefsMap());
        _user = updatedUser;
      }
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> updateUserField(String field, dynamic value) async {
    if (_user == null) return;

    try {
      await _firestoreService.updateUserField(_user!.uid, field, value);
      await loadProfileData(); // Reload to get the latest version
    } catch (e) {
      debugPrint('Error updating user field: $e');
    }
  }

  Future<void> clearProfile() async {
    _user = null;
    _profileImage = null;
    await _sharedPrefs.clearUserProfile();
    notifyListeners();
  }
}