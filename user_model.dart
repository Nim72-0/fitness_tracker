// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart'; // debugPrint

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? profileImageUrl;
  final int age;
  final double weight;
  final double height;
  final String gender;
  final String goal;
  final double? customCalorieGoal;
  final String fitnessGoal;
  final String level;
  final double? bmi;
  final String activityLevel;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.profileImageUrl,
    this.age = 25,
    this.weight = 65.0,
    this.height = 170.0,
    this.gender = 'Male',
    this.goal = 'Maintenance',
    this.customCalorieGoal,
    String? fitnessGoal,
    String? level,
    this.bmi,
    this.activityLevel = 'moderate',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : fitnessGoal = fitnessGoal ?? goal,
        level = level ?? 'beginner',
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // =========================
  // TO FIRESTORE MAP
  // =========================
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'profileImageUrl': profileImageUrl,
      'age': age,
      'weight': weight,
      'height': height,
      'gender': gender,
      'goal': goal,
      'customCalorieGoal': customCalorieGoal,
      'fitnessGoal': fitnessGoal,
      'level': level,
      'bmi': bmi,
      'activityLevel': activityLevel,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // =========================
  // FROM FIRESTORE MAP
  // =========================
  factory UserModel.fromMap(Map<String, dynamic>? map) {
    map ??= {};

    try {
      return UserModel(
        uid: map['uid']?.toString() ?? 'unknown',
        email: map['email']?.toString() ?? '',
        name: map['name']?.toString() ?? 'Fitness Pro',
        profileImageUrl: map['profileImageUrl']?.toString(),
        age: _safeInt(map['age']) ?? 25,
        weight: _safeDouble(map['weight']) ?? 65.0,
        height: _safeDouble(map['height']) ?? 170.0,
        gender: map['gender']?.toString() ?? 'Male',
        goal: map['goal']?.toString() ?? 'Maintenance',
        customCalorieGoal: _safeDouble(map['customCalorieGoal']),
        fitnessGoal: map['fitnessGoal']?.toString() ?? map['goal']?.toString() ?? 'Maintenance',
        level: map['level']?.toString() ?? 'beginner',
        bmi: _safeDouble(map['bmi']),
        activityLevel: map['activityLevel']?.toString() ?? 'moderate',
        createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
        updatedAt: _parseDateTime(map['updatedAt']) ?? DateTime.now(),
      );
    } catch (e) {
      debugPrint('UserModel parse error: $e');
      return UserModel(
        uid: map['uid']?.toString() ?? 'default_uid',
        email: map['email']?.toString() ?? 'user@example.com',
        name: 'Fitness Pro',
      );
    }
  }

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel.fromMap(data);
  }

  // =========================
  // JSON / SHARED PREFS
  // =========================
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'profileImageUrl': profileImageUrl,
      'age': age,
      'weight': weight,
      'height': height,
      'gender': gender,
      'goal': goal,
      'customCalorieGoal': customCalorieGoal,
      'fitnessGoal': fitnessGoal,
      'level': level,
      'bmi': bmi,
      'activityLevel': activityLevel,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory UserModel.fromJson(String jsonString) {
    final map = json.decode(jsonString) as Map<String, dynamic>;
    return UserModel.fromMap(map);
  }

  String toJsonString() => json.encode(toJson());

  Map<String, dynamic> toSharedPrefsMap() => toJson();

  factory UserModel.fromSharedPrefsMap(Map<String, dynamic> map) => UserModel.fromMap(map);

  // Array operator [] for backwards compatibility
  dynamic operator [](String key) {
    switch (key) {
      case 'uid':
        return uid;
      case 'email':
        return email;
      case 'name':
        return name;
      case 'profileImageUrl':
        return profileImageUrl;
      case 'age':
        return age;
      case 'weight':
        return weight;
      case 'height':
        return height;
      case 'gender':
        return gender;
      case 'goal':
        return goal;
      case 'customCalorieGoal':
        return customCalorieGoal;
      case 'fitnessGoal':
        return fitnessGoal;
      case 'level':
        return level;
      case 'bmi':
        return bmi;
      case 'activityLevel':
        return activityLevel;
      case 'createdAt':
        return createdAt;
      case 'updatedAt':
        return updatedAt;
      default:
        return null;
    }
  }

  // =========================
  // COPY WITH
  // =========================
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? profileImageUrl,
    int? age,
    double? weight,
    double? height,
    String? gender,
    String? goal,
    double? customCalorieGoal,
    String? fitnessGoal,
    String? level,
    double? bmi,
    String? activityLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      gender: gender ?? this.gender,
      goal: goal ?? this.goal,
      customCalorieGoal: customCalorieGoal ?? this.customCalorieGoal,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      level: level ?? this.level,
      bmi: bmi ?? this.bmi,
      activityLevel: activityLevel ?? this.activityLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // =========================
  // CALCULATIONS
  // =========================
  double calculateBMI() {
    if (height <= 0) return 0.0;
    final heightM = height / 100;
    return weight / (heightM * heightM);
  }

  String getBMICategory() {
    final currentBMI = bmi ?? calculateBMI();
    if (currentBMI < 18.5) return 'Underweight';
    if (currentBMI < 25) return 'Normal';
    if (currentBMI < 30) return 'Overweight';
    return 'Obese';
  }

  String get initials {
    final safeName = name.trim().isNotEmpty ? name.trim() : 'Fitness Pro';
    final parts = safeName.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return safeName[0].toUpperCase();
  }

  String get displayName {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Fitness Pro';
    return trimmed.split(' ').first;
  }

  bool get isProfileComplete {
    return age > 0 &&
        weight > 0 &&
        height > 0 &&
        gender.isNotEmpty &&
        goal.isNotEmpty;
  }

  double get profileCompletionPercentage {
    int completed = 0;
    if (age > 0) completed++;
    if (weight > 0) completed++;
    if (height > 0) completed++;
    if (gender.isNotEmpty) completed++;
    if (goal.isNotEmpty) completed++;
    return completed / 5;
  }

  int get recommendedWaterIntake {
    final g = goal.toLowerCase();
    if (g.contains('loss')) return 3000;
    if (g.contains('gain') || g.contains('muscle')) return 3500;
    return 2500;
  }

  int calculateDailyCalories({String activityLevel = 'moderate'}) {
    final w = weight;
    final h = height;
    final a = age;
    final g = gender.toLowerCase();

    double bmr;
    if (g == 'male') {
      bmr = 10 * w + 6.25 * h - 5 * a + 5;
    } else {
      bmr = 10 * w + 6.25 * h - 5 * a - 161;
    }

    final multipliers = {
      'sedentary': 1.2,
      'light': 1.375,
      'moderate': 1.55,
      'active': 1.725,
      'very active': 1.9,
    };

    final multiplier = multipliers[activityLevel.toLowerCase()] ?? 1.375;
    double maintenance = bmr * multiplier;

    final adjustments = {
      'weight loss': -500.0,
      'weight gain': 500.0,
      'muscle gain': 300.0,
      'maintenance': 0.0,
    };

    final adjustment = adjustments[goal.toLowerCase()] ?? 0.0;
    return (maintenance + adjustment).round();
  }

  // =========================
  // HELPERS (SAFE PARSING)
  // =========================
  static int _safeInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    if (v is num) return v.toInt();
    return 0;
  }

  static double _safeDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    if (v is num) return v.toDouble();
    return 0.0;
  }

  static DateTime _parseDateTime(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }

  @override
  String toString() => 'UserModel(uid: $uid, name: $name, age: $age, weight: $weight, goal: $goal)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel && runtimeType == other.runtimeType && uid == other.uid;

  @override
  int get hashCode => uid.hashCode;
}
