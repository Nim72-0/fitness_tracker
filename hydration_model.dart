import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// =========================
/// Time Helper
/// =========================
class TimeHelper {
  /// Returns current time formatted like "08:30 AM"
  static String getCurrentTime() => DateFormat('hh:mm a').format(DateTime.now());
}

/// =========================
/// Hydration Model
/// =========================
class HydrationModel {
  final double waterIntake; // total water consumed today in ml
  final double dailyGoal; // daily goal in ml
  final String? userId;
  final List<WaterLog> waterLogs;
  final DateTime lastUpdated;

  HydrationModel({
    required this.waterIntake,
    required this.dailyGoal,
    this.userId,
    required this.waterLogs,
    required this.lastUpdated,
  });

  // =========================
  // UI-friendly Getters
  // =========================
  int get waterGlasses => (waterIntake / 250).floor();
  int get goalInGlasses => (dailyGoal / 250).ceil();
  double get progressPercentage => dailyGoal > 0 ? (waterIntake / dailyGoal).clamp(0.0, 1.0) : 0.0;
  bool get isGoalAchieved => waterIntake >= dailyGoal && dailyGoal > 0;
  double get remainingWater => (dailyGoal - waterIntake).clamp(0.0, double.infinity);
  double get todayWater => waterIntake;

  List<WaterLog> get todaysLogs {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return waterLogs.where((log) {
      final logDate = DateTime(log.timestamp.year, log.timestamp.month, log.timestamp.day);
      return logDate.year == todayStart.year &&
          logDate.month == todayStart.month &&
          logDate.day == todayStart.day;
    }).toList();
  }

  // =========================
  // Factory Constructors
  // =========================
  factory HydrationModel.fromMap(Map<String, dynamic> data) {
    final water = (data['todayWater'] as num?)?.toDouble() ?? 0.0;
    final goal = (data['dailyGoal'] as num?)?.toDouble() ?? 3000.0;

    List<WaterLog> logs = [];
    if (data['waterLogs'] is List<dynamic>) {
      logs = (data['waterLogs'] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map((e) => WaterLog.fromMap(e))
          .toList();
    }

    DateTime lastUpdatedDate = DateTime.now();
    final updated = data['lastUpdated'];
    if (updated is Timestamp) {
      lastUpdatedDate = updated.toDate();
    } else if (updated != null) {
      lastUpdatedDate = DateTime.tryParse(updated.toString()) ?? DateTime.now();
    }

    return HydrationModel(
      waterIntake: water,
      dailyGoal: goal,
      userId: data['userId'] as String?,
      waterLogs: logs,
      lastUpdated: lastUpdatedDate,
    );
  }

  factory HydrationModel.fromTodayStats(Map<String, dynamic> map) => HydrationModel.fromMap(map);

  static HydrationModel initial() => HydrationModel(
        waterIntake: 0.0,
        dailyGoal: 3000.0,
        userId: null,
        waterLogs: [],
        lastUpdated: DateTime.now(),
      );

  // =========================
  // Serialization for Firestore
  // =========================
  Map<String, dynamic> toMap() => {
        'todayWater': waterIntake,
        'dailyGoal': dailyGoal,
        'userId': userId,
        'waterLogs': waterLogs.map((e) => e.toMap()).toList(),
        'lastUpdated': Timestamp.fromDate(lastUpdated),
      };

  // =========================
  // Business Logic Methods
  // =========================
  HydrationModel addWater(double amount, [String? glassName]) {
    if (amount <= 0) return this;

    final newLog = WaterLog(
      amount: amount,
      time: TimeHelper.getCurrentTime(),
      timestamp: DateTime.now(),
      glassName: glassName,
    );

    return HydrationModel(
      waterIntake: waterIntake + amount,
      dailyGoal: dailyGoal,
      userId: userId,
      waterLogs: [...waterLogs, newLog],
      lastUpdated: DateTime.now(),
    );
  }

  HydrationModel removeWater(double amount, [String? glassName]) {
    if (amount <= 0 || waterLogs.isEmpty) return this;

    double remaining = amount;
    final newLogs = List<WaterLog>.from(waterLogs);

    while (remaining > 0 && newLogs.isNotEmpty) {
      final last = newLogs.removeLast();
      remaining -= last.amount;
    }

    final rollbackLog = WaterLog(
      amount: -amount,
      time: TimeHelper.getCurrentTime(),
      timestamp: DateTime.now(),
      glassName: glassName ?? 'Undo',
    );

    return HydrationModel(
      waterIntake: (waterIntake - amount).clamp(0.0, double.infinity),
      dailyGoal: dailyGoal,
      userId: userId,
      waterLogs: [...newLogs, rollbackLog],
      lastUpdated: DateTime.now(),
    );
  }

  HydrationModel removeWaterLog(int index) {
    if (index < 0 || index >= waterLogs.length) return this;

    final removed = waterLogs[index];
    final newLogs = List<WaterLog>.from(waterLogs)..removeAt(index);

    return HydrationModel(
      waterIntake: (waterIntake - removed.amount).clamp(0.0, double.infinity),
      dailyGoal: dailyGoal,
      userId: userId,
      waterLogs: newLogs,
      lastUpdated: DateTime.now(),
    );
  }

  HydrationModel updateGoal(double newGoal) {
    if (newGoal <= 0) return this;

    return HydrationModel(
      waterIntake: waterIntake,
      dailyGoal: newGoal,
      userId: userId,
      waterLogs: waterLogs,
      lastUpdated: DateTime.now(),
    );
  }

  // =========================
  // Cache Support
  // =========================
  static HydrationModel fromCache({
    required double cachedWater,
    required double cachedGoal,
    required List<WaterLog> logs,
    String? uid,
  }) {
    return HydrationModel(
      waterIntake: cachedWater,
      dailyGoal: cachedGoal,
      userId: uid,
      waterLogs: logs,
      lastUpdated: DateTime.now(),
    );
  }
}

/// =========================
/// Water Log Entry
/// =========================
class WaterLog {
  final double amount;
  final String time; // formatted string e.g. "08:30 AM"
  final DateTime timestamp;
  final String? glassName;

  WaterLog({
    required this.amount,
    required this.time,
    required this.timestamp,
    this.glassName,
  });

  Map<String, dynamic> toMap() => {
        'amount': amount,
        'time': time,
        'timestamp': Timestamp.fromDate(timestamp),
        'glassName': glassName,
      };

  factory WaterLog.fromMap(Map<String, dynamic> map) {
    DateTime tsDate = DateTime.now();
    final ts = map['timestamp'];
    if (ts is Timestamp) {
      tsDate = ts.toDate();
    } else if (ts != null) {
      tsDate = DateTime.tryParse(ts.toString()) ?? DateTime.now();
    }

    return WaterLog(
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      time: map['time'] as String? ?? TimeHelper.getCurrentTime(),
      timestamp: tsDate,
      glassName: map['glassName'] as String?,
    );
  }

  /// Serialization for cache
  String serialize() => '$amount|$time|${timestamp.toIso8601String()}|${glassName ?? ''}';

  factory WaterLog.deserialize(String data) {
    final parts = data.split('|');
    if (parts.length < 3) return WaterLog(amount: 0.0, time: TimeHelper.getCurrentTime(), timestamp: DateTime.now());

    return WaterLog(
      amount: double.tryParse(parts[0]) ?? 0.0,
      time: parts[1],
      timestamp: DateTime.tryParse(parts[2]) ?? DateTime.now(),
      glassName: parts.length > 3 && parts[3].isNotEmpty ? parts[3] : null,
    );
  }
}
