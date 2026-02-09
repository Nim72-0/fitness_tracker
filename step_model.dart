import 'dart:convert';
// for numeric helpers
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // Color for status colors

class StepModel {
  final int steps;
  final int goal;
  final int caloriesBurned;
  final int caloriesGoal;
  final DateTime date;
  final double distanceKm;
  final int activeMinutes;
  final bool isGoalAchieved;
  final String? notes;
  final List<Map<String, dynamic>>? hourlyData;

  // New calorie tracking fields
  final int foodCalories;
  final int exerciseCalories;
  final int netCalories;
  final String calorieGoalType; // weight_loss, weight_gain, muscle_gain, maintenance
  final Map<String, dynamic>? calorieHistory;

  StepModel({
    required this.steps,
    required this.goal,
    required this.date,
    int? calories, // alias for caloriesBurned (compatibility)
    int? caloriesBurned,
    this.caloriesGoal = 2000,
    this.distanceKm = 0.0,
    this.activeMinutes = 0,
    this.isGoalAchieved = false,
    this.notes,
    this.hourlyData,
    this.foodCalories = 0,
    this.exerciseCalories = 0,
    int? netCalories,
    this.calorieGoalType = 'maintenance',
    this.calorieHistory,
  })  : caloriesBurned = (calories ?? caloriesBurned ?? 0),
        netCalories = netCalories ?? (foodCalories - exerciseCalories);

  // ========================
  // FACTORY CONSTRUCTORS
  // ========================
  // ✅ FIXED: date parameter remove kiya (error mein "Too few positional arguments" tha)
  factory StepModel.today({
    int steps = 0,
    int goal = 10000,
    int caloriesGoal = 2000,
    String calorieGoalType = 'maintenance',
  }) {
    final caloriesBurned = _calculateCalories(steps);
    return StepModel(
      steps: steps,
      goal: goal,
      date: DateTime.now(), // ✅ FIXED: Hardcoded DateTime.now()
      caloriesBurned: caloriesBurned,
      caloriesGoal: caloriesGoal,
      distanceKm: _calculateDistance(steps),
      activeMinutes: _calculateActiveMinutes(steps),
      isGoalAchieved: steps >= goal,
      calorieGoalType: calorieGoalType,
      exerciseCalories: caloriesBurned,
      netCalories: -caloriesBurned,
    );
  }

  factory StepModel.empty() => StepModel.today();

  factory StepModel.fromDailyStats(Map<String, dynamic>? stats) {
    stats ??= {};

    final steps = (stats['steps'] as num?)?.toInt() ?? 0;
    final goal = (stats['stepsGoal'] as num?)?.toInt() ??
        (stats['goal'] as num?)?.toInt() ??
        10000;
    final caloriesGoal = (stats['caloriesGoal'] as num?)?.toInt() ?? 2000;

    final rawDate = stats['date'];
    final date = rawDate is Timestamp
        ? rawDate.toDate()
        : rawDate != null
            ? DateTime.tryParse(rawDate.toString()) ?? DateTime.now()
            : DateTime.now();

    final hourly = (stats['hourlyData'] is List)
        ? (stats['hourlyData'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
            .toList()
        : null;

    final foodCalories = (stats['foodCalories'] as num?)?.toInt() ?? 0;
    final exerciseCalories = (stats['exerciseCalories'] as num?)?.toInt() ?? 0;

    // Accept either 'caloriesBurned' or 'calories' (compatibility)
    final caloriesBurnedVal =
        (stats['caloriesBurned'] as num?)?.toInt() ?? (stats['calories'] as num?)?.toInt();

    final netCalories = (stats['netCalories'] as num?)?.toInt() ?? (foodCalories - exerciseCalories);
    final calorieGoalType = stats['calorieGoalType']?.toString() ?? 'maintenance';

    Map<String, dynamic>? calorieHistory;
    final historyData = stats['calorieHistory'];
    if (historyData != null) {
      if (historyData is Map) {
        calorieHistory = Map<String, dynamic>.from(historyData);
      } else if (historyData is String) {
        try {
          calorieHistory = jsonDecode(historyData);
        } catch (_) {}
      }
    }

    return StepModel(
      steps: steps,
      goal: goal,
      date: date,
      caloriesBurned: caloriesBurnedVal,
      caloriesGoal: caloriesGoal,
      distanceKm: (stats['distanceKm'] as num?)?.toDouble() ?? _calculateDistance(steps),
      activeMinutes: (stats['activeMinutes'] as num?)?.toInt() ?? _calculateActiveMinutes(steps),
      isGoalAchieved: (stats['isGoalAchieved'] as bool?) ?? (steps >= goal),
      notes: stats['notes']?.toString(),
      hourlyData: hourly,
      foodCalories: foodCalories,
      exerciseCalories: exerciseCalories,
      netCalories: netCalories,
      calorieGoalType: calorieGoalType,
      calorieHistory: calorieHistory,
    );
  }

  factory StepModel.fromMap(Map<String, dynamic>? map) => StepModel.fromDailyStats(map);

  // ========================
  // TO MAP / CACHE
  // ========================
  Map<String, dynamic> toMap() => {
        'steps': steps,
        'stepsGoal': goal, // consistent naming
        'caloriesBurned': caloriesBurned,
        'caloriesGoal': caloriesGoal,
        'date': Timestamp.fromDate(date),
        'distanceKm': distanceKm,
        'activeMinutes': activeMinutes,
        'isGoalAchieved': isGoalAchieved,
        'notes': notes,
        'hourlyData': hourlyData,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'foodCalories': foodCalories,
        'exerciseCalories': exerciseCalories,
        'netCalories': netCalories,
        'calorieGoalType': calorieGoalType,
        'calorieHistory': calorieHistory,
      };

  String toCacheString() => jsonEncode(toMap());

  factory StepModel.fromCacheString(String cached) {
    try {
      return StepModel.fromMap(jsonDecode(cached));
    } catch (_) {
      return StepModel.today();
    }
  }

  // ========================
  // COPY / UPDATE METHODS
  // ========================
  StepModel copyWith({
    int? steps,
    int? goal,
    int? calories,
    int? caloriesBurned,
    int? caloriesGoal,
    DateTime? date,
    double? distanceKm,
    int? activeMinutes,
    bool? isGoalAchieved,
    String? notes,
    List<Map<String, dynamic>>? hourlyData,
    int? foodCalories,
    int? exerciseCalories,
    int? netCalories,
    String? calorieGoalType,
    Map<String, dynamic>? calorieHistory,
  }) {
    final newSteps = steps ?? this.steps;
    final newFood = foodCalories ?? this.foodCalories;
    final newExercise = exerciseCalories ?? this.exerciseCalories;
    final newNet = netCalories ?? (newFood - newExercise);
    final newGoal = goal ?? this.goal;

    return StepModel(
      steps: newSteps,
      goal: newGoal,
      caloriesBurned: (calories ?? caloriesBurned) ?? _calculateCalories(newSteps),
      caloriesGoal: caloriesGoal ?? this.caloriesGoal,
      date: date ?? this.date,
      distanceKm: distanceKm ?? _calculateDistance(newSteps),
      activeMinutes: activeMinutes ?? _calculateActiveMinutes(newSteps),
      isGoalAchieved: isGoalAchieved ?? (newSteps >= newGoal),
      notes: notes ?? this.notes,
      hourlyData: hourlyData ?? this.hourlyData,
      foodCalories: newFood,
      exerciseCalories: newExercise,
      netCalories: newNet,
      calorieGoalType: calorieGoalType ?? this.calorieGoalType,
      calorieHistory: calorieHistory ?? this.calorieHistory,
    );
  }

  StepModel addSteps(int delta) => copyWith(steps: steps + delta);
  StepModel reset() => copyWith(steps: 0);
  StepModel setGoal(int newGoal) => copyWith(goal: newGoal);
  StepModel addFoodCalories(int calories) => copyWith(foodCalories: foodCalories + calories);
  StepModel addExerciseCalories(int calories) => copyWith(exerciseCalories: exerciseCalories + calories);
  StepModel setCalorieGoalType(String type) => copyWith(calorieGoalType: type);
  StepModel setCalorieGoal(int goal) => copyWith(caloriesGoal: goal);
  StepModel resetCalories() => copyWith(foodCalories: 0, exerciseCalories: 0);

  // ========================
  // STATIC CALCULATIONS
  // ========================
  static int _calculateCalories(int steps) => (steps * 0.04).round();
  static double _calculateDistance(int steps) => steps * 0.000762;
  static int _calculateActiveMinutes(int steps) => (steps / 100).round();

  // ========================
  // GETTERS
  // ========================
  double get progress => goal > 0 ? (steps / goal).clamp(0.0, 1.0) : 0.0;
  int get progressPercentage => (progress * 100).round();
  int get remainingSteps {
    final rem = goal - steps;
    return rem < 0 ? 0 : rem;
  }

  String get formattedDate => '${date.day}/${date.month}';
  String get formattedDistance => '${distanceKm.toStringAsFixed(1)} km';
  String get formattedCalories => '$caloriesBurned cal';
  bool get isGoalReached => steps >= goal;
  String get dayName => ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];

  // Calorie getters
  String get formattedFoodCalories => '$foodCalories cal';
  String get formattedExerciseCalories => '$exerciseCalories cal';
  String get formattedNetCalories => '$netCalories cal';
  String get formattedCaloriesGoal => '$caloriesGoal cal';
  double get calorieProgress => caloriesGoal > 0 ? (netCalories / caloriesGoal).clamp(0.0, 1.0) : 0.0;
  int get calorieProgressPercentage => (calorieProgress * 100).round();

  // Calorie progress with status
  Map<String, dynamic> getCalorieProgress() {
    final percentage = calorieProgress;
    final remaining = caloriesGoal - netCalories;

    String status;
    Color statusColor;

    if (calorieGoalType == 'weight_loss') {
      if (netCalories < caloriesGoal - 200) {
        status = 'Good deficit for weight loss';
        statusColor = Colors.green;
      } else if (netCalories > caloriesGoal) {
        status = 'Over limit - adjust intake';
        statusColor = Colors.orange;
      } else {
        status = 'On track for weight loss';
        statusColor = Colors.blue;
      }
    } else if (calorieGoalType == 'weight_gain' || calorieGoalType == 'muscle_gain') {
      if (netCalories > caloriesGoal + 200) {
        status = 'Good surplus for gain';
        statusColor = Colors.green;
      } else if (netCalories < caloriesGoal) {
        status = 'Need more calories for gain';
        statusColor = Colors.orange;
      } else {
        status = 'On track for gain';
        statusColor = Colors.blue;
      }
    } else {
      if (netCalories.abs() <= 100) {
        status = 'Perfect maintenance';
        statusColor = Colors.green;
      } else {
        status = 'Adjust for maintenance';
        statusColor = Colors.blue;
      }
    }

    return {
      'percentage': percentage,
      'percentageText': '${(percentage * 100).toInt()}%',
      'remaining': remaining,
      'status': status,
      'statusColor': statusColor,
      'isDeficit': netCalories < caloriesGoal,
      'isSurplus': netCalories > caloriesGoal,
      'difference': netCalories - caloriesGoal,
    };
  }

  bool get isCalorieGoalAchieved {
    if (calorieGoalType == 'weight_loss') {
      return netCalories <= caloriesGoal - 200;
    } else if (calorieGoalType == 'weight_gain' || calorieGoalType == 'muscle_gain') {
      return netCalories >= caloriesGoal + 200;
    } else {
      return netCalories.abs() <= 100;
    }
  }

  String get goalTypeDisplayName {
    switch (calorieGoalType) {
      case 'weight_loss':
        return 'Weight Loss';
      case 'weight_gain':
        return 'Weight Gain';
      case 'muscle_gain':
        return 'Muscle Gain';
      case 'maintenance':
        return 'Maintenance';
      default:
        // Fallback formatting
        return calorieGoalType.replaceAll('_', ' ').split(' ').map((w) {
          if (w.isEmpty) return '';
          return w[0].toUpperCase() + w.substring(1).toLowerCase();
        }).join(' ');
    }
  }

  // Weekly history helper
  List<Map<String, dynamic>> getWeeklyHistory() {
    if (calorieHistory == null || calorieHistory!.isEmpty) return [];

    final List<Map<String, dynamic>> history = [];
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.day}/${date.month}';

      if (calorieHistory!.containsKey(dateKey)) {
        history.add({
          'date': dateKey,
          ...Map<String, dynamic>.from(calorieHistory![dateKey]),
        });
      } else {
        history.add({
          'date': dateKey,
          'calories': 0,
          'goal': caloriesGoal,
          'food': 0,
          'exercise': 0,
        });
      }
    }

    return history;
  }

  StepModel addToHistory() {
    final updatedHistory = Map<String, dynamic>.from(calorieHistory ?? {});
    final todayKey = '${date.day}/${date.month}';

    updatedHistory[todayKey] = {
      'calories': netCalories,
      'goal': caloriesGoal,
      'food': foodCalories,
      'exercise': exerciseCalories,
      'steps': steps,
      'timestamp': DateTime.now().toIso8601String(),
    };

    return copyWith(calorieHistory: updatedHistory);
  }
}