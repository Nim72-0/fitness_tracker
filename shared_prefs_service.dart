// lib/services/shared_prefs_service.dart - PRODUCTION-READY UPDATED
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  static SharedPrefsService? _instance;
  SharedPreferences? _prefs;

  SharedPrefsService._internal();

  factory SharedPrefsService() {
    _instance ??= SharedPrefsService._internal();
    return _instance!;
  }

  /// Initialize SharedPreferences
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // =========================
  // 🔹 USER AUTHENTICATION
  // =========================
  Future<void> setLoggedIn(bool value) async => await _prefs?.setBool('is_logged_in', value);
  bool get isLoggedIn => _prefs?.getBool('is_logged_in') ?? false;

  Future<void> setUserId(String id) async => await _prefs?.setString('user_id', id);
  String? get userId => _prefs?.getString('user_id');

  Future<void> setUserEmail(String email) async => await _prefs?.setString('user_email', email);
  String? get userEmail => _prefs?.getString('user_email');

  Future<void> setFirstTime(bool value) async => await _prefs?.setBool('is_first_time', value);
  bool get isFirstTime => _prefs?.getBool('is_first_time') ?? true;

  Future<void> setShouldShowWelcome(bool value) async => await _prefs?.setBool('should_show_welcome', value);
  bool get shouldShowWelcome => _prefs?.getBool('should_show_welcome') ?? false;

  // =========================
  // 🔹 USER PROFILE DATA
  // =========================
  Future<void> saveProfileImagePath(String path) async =>
      await _prefs?.setString('profile_image_path', path);
  String? get profileImagePath => _prefs?.getString('profile_image_path');

  Future<void> saveUserProfile(Map<String, dynamic> data) async {
    await init();

    await _prefs?.setString('user_id', data['uid']?.toString() ?? '');
    await _prefs?.setString('user_name', data['name']?.toString() ?? '');
    await _prefs?.setString('user_email', data['email']?.toString() ?? '');
    await _prefs?.setString('user_gender', data['gender']?.toString() ?? '');
    await _prefs?.setString('user_goal', data['goal']?.toString() ?? '');
    await saveProfileImagePath(data['profileImagePath']?.toString() ?? '');

    final age = int.tryParse(data['age']?.toString() ?? '');
    if (age != null) await _prefs?.setInt('user_age', age);

    final height = double.tryParse(data['height']?.toString() ?? '');
    if (height != null) await _prefs?.setDouble('user_height', height);

    final weight = double.tryParse(data['weight']?.toString() ?? '');
    if (weight != null) await _prefs?.setDouble('user_weight', weight);

    await setLoggedIn(true);
    await setFirstTime(false);
  }

  Map<String, dynamic>? getUserProfile() {
    if (_prefs == null || !isLoggedIn) return null;
    final uid = _prefs?.getString('user_id');
    if (uid == null || uid.isEmpty) return null;

    return {
      'uid': uid,
      'name': _prefs?.getString('user_name') ?? '',
      'email': _prefs?.getString('user_email') ?? '',
      'age': _prefs?.getInt('user_age') ?? 0,
      'height': _prefs?.getDouble('user_height') ?? 0.0,
      'weight': _prefs?.getDouble('user_weight') ?? 0.0,
      'gender': _prefs?.getString('user_gender') ?? '',
      'goal': _prefs?.getString('user_goal') ?? '',
      'profileImagePath': profileImagePath,
    };
  }

  Future<void> clearUserProfile() async {
    await _prefs?.remove('user_id');
    await _prefs?.remove('user_name');
    await _prefs?.remove('user_email');
    await _prefs?.remove('user_age');
    await _prefs?.remove('user_height');
    await _prefs?.remove('user_weight');
    await _prefs?.remove('user_gender');
    await _prefs?.remove('user_goal');
    await _prefs?.remove('profile_image_path');
    await setLoggedIn(false);
  }

  // =========================
  // 🔹 FITNESS GOALS
  // =========================
  Future<void> saveDailyStepGoal(int steps) async =>
      await _prefs?.setInt('daily_step_goal', steps);
  int get dailyStepGoal => _prefs?.getInt('daily_step_goal') ?? 10000;

  Future<void> saveDailyCalorieGoal(int calories) async =>
      await _prefs?.setInt('daily_calorie_goal', calories);
  int get dailyCalorieGoal => _prefs?.getInt('daily_calorie_goal') ?? 2000;

  Future<void> saveDailyWaterGoal(int ml) async =>
      await _prefs?.setInt('daily_water_goal_ml', ml);
  int get dailyWaterGoal => _prefs?.getInt('daily_water_goal_ml') ?? 3000;

  // =========================
  // 🔹 DAILY PROGRESS
  // =========================
  Future<void> saveTodaySteps(int steps) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    await _prefs?.setInt('steps_$today', steps);
  }

  int getTodaySteps() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return _prefs?.getInt('steps_$today') ?? 0;
  }

  Future<void> saveTodayWater(int ml) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    await _prefs?.setInt('water_$today', ml);
  }

  int getTodayWater() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return _prefs?.getInt('water_$today') ?? 0;
  }

  Future<void> saveTodayCalories(int calories) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    await _prefs?.setInt('calories_$today', calories);
  }

  int getTodayCalories() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return _prefs?.getInt('calories_$today') ?? 0;
  }

  Future<void> saveTodayWorkoutMinutes(int minutes) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    await _prefs?.setInt('workout_$today', minutes);
  }

  int getTodayWorkoutMinutes() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return _prefs?.getInt('workout_$today') ?? 0;
  }

  // =========================
  // 🔹 GENERIC STORAGE METHODS
  // =========================
  Future<void> setStringList(String key, List<String> value) async =>
      await _prefs?.setStringList(key, value);

  List<String>? getStringList(String key) => _prefs?.getStringList(key);

  bool containsKey(String key) => _prefs?.containsKey(key) ?? false;
  Future<void> remove(String key) async => await _prefs?.remove(key);
  Set<String> get keys => _prefs?.getKeys() ?? {};
  Future<void> clearAll() async => await _prefs?.clear();

  void printAllData() {
    if (_prefs == null || !kDebugMode) return;
    debugPrint('=== SHARED PREFERENCES DATA ===');
    for (final key in _prefs!.getKeys()) {
      debugPrint('$key: ${_prefs!.get(key)}');
    }
    debugPrint('================================');
  }
}
