// lib/services/firestore_service.dart
import 'dart:typed_data'; // For Uint8List
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/user_model.dart';
import '../models/hydration_model.dart';
import '../models/nutrition_model.dart';
import '../models/workout_model.dart';
import '../models/gps_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Timestamp _now() => Timestamp.fromDate(DateTime.now());

  String _dateDocId([DateTime? date]) {
    final d = date ?? DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  // ────────────────────────────────
  // USER PROFILE
  // ────────────────────────────────
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) return UserModel.fromMap(doc.data()!);

      final defaultUser = UserModel(
        uid: uid,
        email: '',
        name: 'New User',
        createdAt: DateTime.now(),
      );

      await _db.collection('users').doc(uid).set(defaultUser.toMap());
      return defaultUser;
    } catch (e) {
      debugPrint('getUserProfile error: $e');
      return null;
    }
  }

  Future<void> updateUser(UserModel user) async {
    if (user.uid.isEmpty) {
      debugPrint('updateUser error: Cannot update user with empty UID');
      return;
    }
    try {
      await _db.collection('users').doc(user.uid).set(
            user.toMap(),
            SetOptions(merge: true),
          );
    } catch (e) {
      debugPrint('updateUser error: $e');
      rethrow;
    }
  }

  Future<void> updateUserField(String uid, String field, dynamic value) async {
    try {
      await _db.collection('users').doc(uid).set({
        field: value,
        'updatedAt': _now(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('updateUserField error: $e');
    }
  }

  Future<String?> uploadProfileImage(String uid, Uint8List imageBytes) async {
    try {
      final ref = _storage.ref().child('profile_images/$uid.jpg');
      await ref.putData(imageBytes, SettableMetadata(contentType: 'image/jpeg'));
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('uploadProfileImage error: $e');
      if (e.toString().contains('retry-limit-exceeded')) {
        debugPrint('Tip: Check your internet connection or Firebase Storage rules.');
      }
      return null;
    }
  }

  // ────────────────────────────────
  // HYDRATION
  // ────────────────────────────────
  Future<HydrationModel> getTodayHydration(String uid) async {
    try {
      final docId = _dateDocId();
      final docRef = _db.collection('hydration').doc(uid).collection('daily').doc(docId);
      final doc = await docRef.get();

      if (doc.exists && doc.data() != null) return HydrationModel.fromMap(doc.data()!);

      final defaultHydration = HydrationModel.initial();
      await docRef.set(defaultHydration.toMap());
      return defaultHydration;
    } catch (e) {
      debugPrint('getTodayHydration error: $e');
      return HydrationModel.initial();
    }
  }

  Future<void> addWater(String uid, double amount, {String? glassName}) async {
    if (amount <= 0) return;
    try {
      final docId = _dateDocId();
      final docRef = _db.collection('hydration').doc(uid).collection('daily').doc(docId);

      final newLog = {
        'amount': amount,
        'time': DateFormat('hh:mm a').format(DateTime.now()),
        'timestamp': _now(),
        if (glassName != null) 'glassName': glassName,
      };

      await docRef.set({
        'dailyGoal': FieldValue.increment(0),
        'todayWater': FieldValue.increment(amount),
        'waterLogs': FieldValue.arrayUnion([newLog]),
        'lastUpdated': _now(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('addWater error: $e');
    }
  }

  Future<void> updateWaterGoal(String uid, double goal) async {
    if (goal <= 0) return;
    try {
      final docRef = _db.collection('hydration').doc(uid).collection('daily').doc(_dateDocId());
      await docRef.set({'dailyGoal': goal, 'lastUpdated': _now()}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('updateWaterGoal error: $e');
    }
  }

  // ────────────────────────────────
  // NUTRITION
  // ────────────────────────────────
  Future<List<NutritionModel>> getMeals(String uid, DateTime date) async {
    try {
      final start = Timestamp.fromDate(DateTime(date.year, date.month, date.day));
      final end = Timestamp.fromDate(DateTime(date.year, date.month, date.day, 23, 59, 59));

      final snapshot = await _db
          .collection('nutrition')
          .doc(uid)
          .collection('meals')
          .where('timestamp', isGreaterThanOrEqualTo: start)
          .where('timestamp', isLessThanOrEqualTo: end)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) => NutritionModel.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      debugPrint('getMeals error: $e');
      return [];
    }
  }

  Future<String?> addMeal(String uid, NutritionModel meal) async {
    try {
      final docRef = await _db.collection('nutrition').doc(uid).collection('meals').add(meal.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('addMeal error: $e');
      return null;
    }
  }

  Future<void> updateMeal(String uid, String mealId, NutritionModel meal) async {
    try {
      await _db.collection('nutrition').doc(uid).collection('meals').doc(mealId).update(meal.toMap());
    } catch (e) {
      debugPrint('updateMeal error: $e');
      rethrow;
    }
  }

  Future<void> deleteMeal(String uid, String mealId) async {
    try {
      if (mealId.isEmpty) return;
      await _db.collection('nutrition').doc(uid).collection('meals').doc(mealId).delete();
    } catch (e) {
      debugPrint('deleteMeal error: $e');
    }
  }

  Future<String?> uploadMealImage(String uid, Uint8List imageBytes) async {
    try {
      final ref = _storage.ref().child('meal_images/$uid/${DateTime.now().toIso8601String()}.jpg');
      await ref.putData(imageBytes, SettableMetadata(contentType: 'image/jpeg'));
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('uploadMealImage error: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getNutritionHistory(String uid, DateTime startDate, DateTime endDate) async {
    try {
      final snapshot = await _db
          .collection('nutrition')
          .doc(uid)
          .collection('meals')
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where('timestamp', isLessThanOrEqualTo: endDate)
          .orderBy('timestamp', descending: true)
          .get();

      final meals = snapshot.docs.map((doc) => NutritionModel.fromMap(doc.data(), doc.id)).toList();
      return meals.map((meal) => {
        'date': DateFormat('yyyy-MM-dd').format(meal.timestamp),
        'calories': meal.calories,
        'goal': 2200, // Placeholder
      }).toList();
    } catch (e) {
      debugPrint('getNutritionHistory error: $e');
      return [];
    }
  }

  // ────────────────────────────────
  // WORKOUTS
  // ────────────────────────────────
  Future<List<Workout>> getWorkouts() async {
    try {
      final snap = await _db.collection('workouts').orderBy('createdAt').get();
      return snap.docs.map((d) => Workout.fromMap(d.data(), id: d.id)).toList();
    } catch (e) {
      debugPrint('getWorkouts error: $e');
      return [];
    }
  }

  Future<List<WorkoutSession>> getWorkoutHistory(String uid) async {
    try {
      final snap = await _db
          .collection('workout_history')
          .doc(uid)
          .collection('sessions')
          .orderBy('completedAt', descending: true)
          .limit(50)
          .get();

      return snap.docs.map((d) => WorkoutSession.fromMap(d.data())).toList();
    } catch (e) {
      debugPrint('getWorkoutHistory error: $e');
      return [];
    }
  }

  Future<void> saveWorkoutSession(String uid, WorkoutSession session) async {
    try {
      await _db.collection('workout_history').doc(uid).collection('sessions').doc(session.id).set(session.toMap());
    } catch (e) {
      debugPrint('saveWorkoutSession error: $e');
    }
  }

  Future<Set<String>> getFavoriteWorkoutIds(String uid) async {
    try {
      final doc = await _db.collection('user_favorites').doc(uid).get();
      final list = doc.data()?['workoutIds'] as List<dynamic>? ?? [];
      return list.map((e) => e.toString()).toSet();
    } catch (e) {
      debugPrint('getFavoriteWorkoutIds error: $e');
      return {};
    }
  }

  Future<void> addFavoriteWorkout(String uid, String workoutId) async {
    try {
      await _db.collection('user_favorites').doc(uid).set({
        'workoutIds': FieldValue.arrayUnion([workoutId]),
        'updatedAt': _now()
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('addFavoriteWorkout error: $e');
    }
  }

  Future<void> removeFavoriteWorkout(String uid, String workoutId) async {
    try {
      await _db.collection('user_favorites').doc(uid).set({
        'workoutIds': FieldValue.arrayRemove([workoutId]),
        'updatedAt': _now()
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('removeFavoriteWorkout error: $e');
    }
  }

  // ────────────────────────────────
  // GPS ROUTES
  // ────────────────────────────────
  Future<void> saveGPSRoute(String uid, GPSRoute route) async {
    try {
      // Create a new document in 'routes' subcollection
      final docRef = _db.collection('gps_routes').doc(uid).collection('user_routes').doc();
      
      // Save route data
      // Ensuring we use a map, assuming toMap exists or we construct one.
      // Ideally GPSRoute has toMap. If not, we'll see an error next.
      await docRef.set(route.toMap()); 
      
    } catch (e) {
      debugPrint('saveGPSRoute error: $e');
      rethrow;
    }
  }
}
