// lib/providers/hydration_provider.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/hydration_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class HydrationProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  // Core data
  HydrationModel _hydration = HydrationModel.initial();
  bool _isLoading = false;
  String? _userId;

  // User/profile info
  UserModel? _user;
  UserModel? get user => _user;

  String? get fitnessGoal => _user?.goal;
  double? get userWeight => _user?.weight;
  int preferredGlassSize = 250;

  // Getters
  HydrationModel get hydration => _hydration;
  bool get isLoading => _isLoading;
  bool get isGoalAchieved => _hydration.isGoalAchieved;
  double get progressPercentage => _hydration.progressPercentage;
  double get remainingWater => _hydration.remainingWater;
  int get waterGlasses => _hydration.waterGlasses;
  double get dailyGoal => _hydration.dailyGoal;
  double get todayWater => _hydration.todayWater;

  List<WaterLog> get history => List.unmodifiable(_hydration.waterLogs);

  int get recommendedDailyGoal {
    final weight = _user?.weight ?? 60.0;
    final goalType = (_user?.goal ?? 'maintenance').toLowerCase();

    const multipliers = {
      'weight_loss': 35.0,    // Higher water intake for weight loss
      'muscle_gain': 40.0,    // Higher for muscle building
      'weight_gain': 35.0,    // Moderate for weight gain
      'maintenance': 30.0,    // Standard maintenance
    };

    final multiplier = multipliers[goalType] ?? 30.0;
    return (weight * multiplier).round();
  }

  // Calculate glasses needed (assuming 250ml per glass)
  int get goalInGlasses => (dailyGoal / 250).ceil();
  int get currentGlasses => (todayWater / 250).floor();
  int get remainingGlasses => (remainingWater / 250).ceil();

  // ──────────────────────────────────────────────
  // Initialize / set user
  // ──────────────────────────────────────────────
  Future<void> setUserId(String uid) async {
    if (uid.isEmpty) return;

    _userId = uid;
    _isLoading = true;
    notifyListeners();

    try {
      // Load today's hydration from Firestore
      final data = await _firestore.getTodayHydration(uid);
      _hydration = data ?? HydrationModel.initial();

      // Load user profile
      final profile = await _firestore.getUserProfile(uid);
      if (profile != null) {
        _user = profile;

        // Apply recommended goal if default
        if (_hydration.dailyGoal == 3000.0) {
          await updateGoal(recommendedDailyGoal);
        }
      }

      // Load cached hydration
      await _loadFromCache();
    } catch (e) {
      debugPrint('Hydration init error: $e');
      await _loadFromCache();
    }

    _isLoading = false;
    notifyListeners();
  }

  // ──────────────────────────────────────────────
  // Add water intake
  // ──────────────────────────────────────────────
  Future<bool> addWater(double amount, {String? glassName}) async {
    if (_userId == null || amount <= 0) return false;

    final prevHydration = _hydration;
    final wasAchieved = _hydration.isGoalAchieved;

    try {
      // HydrationModel.addWater handles timestamp/time internally
      _hydration = _hydration.addWater(amount, glassName);
      notifyListeners();

      await _firestore.addWater(_userId!, amount, glassName: glassName);
      await _cacheHydration();

      // Check for goal completion
      if (!wasAchieved && _hydration.isGoalAchieved) {
        await NotificationService().showNotification(
          'Goal Achieved! 🎉',
          'You reached your hydration goal of ${_hydration.dailyGoal.toInt()}ml. Great job!',
          type: 'hydration_goal',
        );
      }

      return true;
    } catch (e) {
      debugPrint('Add water error: $e');
      _hydration = prevHydration;
      notifyListeners();
      return false;
    }
  }

  // ──────────────────────────────────────────────
  // Update daily goal
  // ──────────────────────────────────────────────
  Future<bool> updateGoal(int newGoalMl) async {
    if (_userId == null || newGoalMl <= 0) return false;

    final prevGoal = _hydration.dailyGoal;

    try {
      _hydration = _hydration.updateGoal(newGoalMl.toDouble());
      notifyListeners();

      await _firestore.updateWaterGoal(_userId!, newGoalMl.toDouble());
      await _cacheHydration();

      return true;
    } catch (e) {
      debugPrint('Update goal error: $e');
      _hydration = _hydration.updateGoal(prevGoal);
      notifyListeners();
      return false;
    }
  }

  // ──────────────────────────────────────────────
  // Fetch today's hydration (manual refresh)
  // ──────────────────────────────────────────────
  Future<void> fetchTodayHydration() async {
    if (_userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final data = await _firestore.getTodayHydration(_userId!);
      _hydration = data;

      await _cacheHydration();
    } catch (e) {
      debugPrint('Fetch hydration error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ──────────────────────────────────────────────
  // Cache hydration locally
  // ──────────────────────────────────────────────
  Future<void> _cacheHydration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('hydration_today_ml', _hydration.waterIntake);
      await prefs.setDouble('hydration_goal_ml', _hydration.dailyGoal);

      final logs = _hydration.waterLogs.map((log) => log.serialize()).toList();
      await prefs.setStringList('hydration_logs', logs);
    } catch (e) {
      debugPrint('Cache hydration error: $e');
    }
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = prefs.getDouble('hydration_today_ml') ?? 0.0;
      final goal = prefs.getDouble('hydration_goal_ml') ?? 3000.0;
      final logsStr = prefs.getStringList('hydration_logs') ?? [];

      final logs = logsStr.map((str) => WaterLog.deserialize(str)).toList();

      _hydration = HydrationModel.fromCache(
        cachedWater: today,
        cachedGoal: goal,
        logs: logs,
        uid: _userId,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Load cache error: $e');
      _hydration = HydrationModel.initial();
    }
  }

  // ──────────────────────────────────────────────
  // Clear provider on logout
  // ──────────────────────────────────────────────
  // ──────────────────────────────────────────────
  // Notifications
  // ──────────────────────────────────────────────
  Future<void> enableHourlyReminders() async {
    await NotificationService().scheduleHourlyHydrationNotifications();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hydration_reminders_enabled', true);
    notifyListeners();
  }

  Future<void> disableHourlyReminders() async {
    await NotificationService().cancelHydrationNotifications();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hydration_reminders_enabled', false);
    notifyListeners();
  }

  Future<bool> areRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('hydration_reminders_enabled') ?? false;
  }
}
