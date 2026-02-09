// lib/providers/nutrition_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; 

import '../models/nutrition_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class NutritionProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _uid;
  UserModel? _user;
  UserModel? get user => _user;

  List<NutritionModel> _meals = [];
  List<NutritionModel> get meals => List.unmodifiable(_meals);

  String _selectedGoal = 'maintenance';
  String get selectedGoal => _selectedGoal;

  double? _customCalorieGoal;

  final DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  double _totalCalories = 0;
  double _totalProtein = 0;
  double _totalCarbs = 0;
  double _totalFat = 0;
  double _totalFiber = 0;

  int _nutriScore = 0;

  List<Map<String, dynamic>> _weeklyHistory = [];
  List<Map<String, dynamic>> get weeklyHistory => _weeklyHistory;

  List<Map<String, dynamic>> _monthlyHistory = [];
  List<Map<String, dynamic>> get monthlyHistory => _monthlyHistory;

  double get totalCalories => _totalCalories;
  double get totalProtein => _totalProtein;
  double get totalCarbs => _totalCarbs;
  double get totalFat => _totalFat;
  double get totalFiber => _totalFiber;
  int get nutriScore => _nutriScore;

  double get calorieProgress {
    final goal = dailyGoals['Calories'] ?? 2200.0;
    if (goal == 0) return 0;
    return (_totalCalories / goal).clamp(0.0, 1.5);
  }

  Map<String, double> get dailyGoals {
    Map<String, double> goals;
    if (_user == null) {
      goals = _getDefaultGoals();
    } else {
      goals = _calculatePersonalizedGoals();
    }

    if (_customCalorieGoal != null) {
      // Adjustment ratio based on custom calories vs calculated/default calories
      final double calculatedCalories = goals['Calories'] ?? 2200.0;
      final double ratio = _customCalorieGoal! / calculatedCalories;
      
      return {
        'Calories': _customCalorieGoal!,
        'Protein': (goals['Protein'] ?? 65.0) * ratio,
        'Carbs': (goals['Carbs'] ?? 300.0) * ratio,
        'Fat': (goals['Fat'] ?? 70.0) * ratio,
        'Fiber': (goals['Fiber'] ?? 25.0), // Fiber usually stays constant
      };
    }
    return goals;
  }

  void setUserId(String uid) {
    if (_uid != uid) {
      _uid = uid;
      loadTodayData(uid);
    }
  }

  Future<void> loadTodayData(String uid) async {
    if (uid.isEmpty) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _uid = uid;

    final prefs = await SharedPreferences.getInstance();
    _user = await _firestore.getUserProfile(uid);
    _selectedGoal = prefs.getString('nutrition_goal') ?? _user?.goal ?? 'maintenance';
    _customCalorieGoal = prefs.getDouble('custom_calorie_goal');

    _meals = await _firestore.getMeals(uid, _selectedDate);

    await loadWeeklyHistory();
    await loadMonthlyHistory();
    _calculateAllMetrics();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setGoal(String newGoal, {double? customCalories}) async {
    _selectedGoal = newGoal;
    _customCalorieGoal = customCalories;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nutrition_goal', newGoal);
    if (customCalories != null) {
      await prefs.setDouble('custom_calorie_goal', customCalories);
    } else {
      await prefs.remove('custom_calorie_goal');
    }

    _calculateAllMetrics();

    if (_uid != null) {
      _firestore.updateUserField(_uid!, 'goal', newGoal);
      if (customCalories != null) {
        _firestore.updateUserField(_uid!, 'customCalorieGoal', customCalories);
      }
    }

    notifyListeners();
  }

  Future<void> addMeal(NutritionModel meal, {XFile? imageFile}) async {
    if (_uid == null) return;

    String? imageUrl;
    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      imageUrl = await _firestore.uploadMealImage(_uid!, bytes);
    }

    var newMeal = meal.copyWith(imageUrl: imageUrl, timestamp: DateTime.now());

    final newMealId = await _firestore.addMeal(_uid!, newMeal);
    if (newMealId != null) {
      newMeal = newMeal.copyWith(id: newMealId);
      _meals.add(newMeal);
      _calculateAllMetrics();
      await _checkGoalAchievement();
      notifyListeners();
    }
  }

  Future<void> updateMeal(String mealId, NutritionModel updatedMeal, {XFile? newImageFile}) async {
    if (_uid == null) return;

    String? imageUrl = updatedMeal.imageUrl;
    if (newImageFile != null) {
      final bytes = await newImageFile.readAsBytes();
      imageUrl = await _firestore.uploadMealImage(_uid!, bytes);
    }

    final mealToUpdate = updatedMeal.copyWith(imageUrl: imageUrl);
    await _firestore.updateMeal(_uid!, mealId, mealToUpdate);

    final index = _meals.indexWhere((m) => m.id == mealId);
    if (index != -1) {
      _meals[index] = mealToUpdate;
    }

    _calculateAllMetrics();
    notifyListeners();
  }

  Future<void> deleteMeal(String mealId) async {
    if (_uid == null) return;

    await _firestore.deleteMeal(_uid!, mealId);
    _meals.removeWhere((m) => m.id == mealId);

    _calculateAllMetrics();
    notifyListeners();
  }

  void _calculateAllMetrics() {
    _calculateTotals();
    _calculateNutriScore();
  }

  void _calculateTotals() {
    _totalCalories = 0;
    _totalProtein = 0;
    _totalCarbs = 0;
    _totalFat = 0;
    _totalFiber = 0;

    for (var meal in _meals) {
      _totalCalories += meal.calories;
      _totalProtein += meal.protein;
      _totalCarbs += meal.carbs;
      _totalFat += meal.fat;
      _totalFiber += meal.fiber;
    }
  }

  void _calculateNutriScore() {
    final goals = dailyGoals;
    final calGoal = goals['Calories'] ?? 2200.0;
    if (calGoal == 0) {
      _nutriScore = 0;
      return;
    }
    final calDiff = (_totalCalories - calGoal).abs();
    final calScore = 40 * (1 - (calDiff / calGoal).clamp(0.0, 1.0));

    final protGoal = goals['Protein'] ?? 80.0;
    final protRatio = protGoal > 0 ? (_totalProtein / protGoal).clamp(0.0, 1.5) : 0.0;
    final protScore = 30 * protRatio;

    double varietyScore = 0;
    if (_meals.isNotEmpty) {
      final cats = _meals.map((m) => m.category.toLowerCase()).toSet();
      varietyScore = 20 * (cats.length / 4).clamp(0.0, 1.0);
    }

    double timingScore = 0;
    if (_meals.isNotEmpty) {
      final last = _meals.last.timestamp;
      if (DateTime.now().difference(last).inHours <= 4) {
        timingScore = 10;
      }
    }

    _nutriScore = (calScore + protScore + varietyScore + timingScore).clamp(0.0, 100.0).toInt();
  }

  Future<void> loadWeeklyHistory() async {
    if (_uid == null) return;
    final now = DateTime.now();
    final weekStart = now.subtract(const Duration(days: 6));
    _weeklyHistory = await _firestore.getNutritionHistory(_uid!, weekStart, now);
  }

  Future<void> loadMonthlyHistory() async {
    if (_uid == null) return;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    _monthlyHistory = await _firestore.getNutritionHistory(_uid!, monthStart, now);
  }

  List<NutritionModel> getMealsByCategory(String category) {
    return _meals.where((meal) => meal.category.toLowerCase() == category.toLowerCase()).toList();
  }

  Map<String, double> _calculatePersonalizedGoals() {
    if (_user == null) return _getDefaultGoals();

    final bmr = _calculateBMR();
    final tdee = _calculateTDEE(bmr);
    final calorieTarget = _calculateCalorieTarget(tdee);

    return {
      'Calories': calorieTarget,
      'Protein': _calculateProteinTarget(),
      'Carbs': _calculateCarbTarget(calorieTarget),
      'Fat': _calculateFatTarget(calorieTarget),
      'Fiber': _calculateFiberTarget(),
    };
  }

  double _calculateBMR() {
    if (_user == null) {
      return 1500.0;
    }
    final w = _user!.weight;
    final h = _user!.height;
    final a = _user!.age;
    return _user!.gender.toLowerCase() == 'male'
        ? 10 * w + 6.25 * h - 5 * a + 5
        : 10 * w + 6.25 * h - 5 * a - 161;
  }

  double _calculateTDEE(double bmr) {
    final level = _user?.activityLevel.toLowerCase() ?? 'moderate';
    final multipliers = {
      'sedentary': 1.2,
      'light': 1.375,
      'moderate': 1.55,
      'active': 1.725,
      'very active': 1.9,
    };
    return bmr * (multipliers[level] ?? 1.375);
  }

  double _calculateCalorieTarget(double tdee) {
    final goalLower = _selectedGoal.toLowerCase();
    if (goalLower.contains('loss')) return tdee - 500;
    if (goalLower.contains('gain') || goalLower.contains('muscle')) return tdee + 500;
    return tdee;
  }

  double _calculateProteinTarget() {
    final w = _user?.weight ?? 65.0;
    final goalLower = _selectedGoal.toLowerCase();
    if (goalLower.contains('loss')) return w * 2.2;
    if (goalLower.contains('muscle') || goalLower.contains('gain')) return w * 2.5;
    return w * 1.8;
  }

  double _calculateCarbTarget(double calories) {
    double pct = 0.45;
    final goalLower = _selectedGoal.toLowerCase();
    if (goalLower.contains('loss')) pct = 0.40;
    if (goalLower.contains('muscle')) pct = 0.50;
    return (calories * pct) / 4;
  }

  double _calculateFatTarget(double calories) {
    double pct = 0.25;
    final goalLower = _selectedGoal.toLowerCase();
    if (goalLower.contains('loss')) pct = 0.30;
    if (goalLower.contains('muscle')) pct = 0.20;
    return (calories * pct) / 9;
  }

  double _calculateFiberTarget() {
    return (_user?.weight ?? 65.0) * 0.014;
  }

  Map<String, double> _getDefaultGoals() {
    final goal = _selectedGoal.toLowerCase();
    if (goal.contains('loss')) {
      return {'Calories': 1800, 'Protein': 75, 'Carbs': 180, 'Fat': 60, 'Fiber': 30};
    } else if (goal.contains('gain') || goal.contains('muscle')) {
      return {'Calories': 2800, 'Protein': 85, 'Carbs': 380, 'Fat': 85, 'Fiber': 25};
    }
    return {'Calories': 2200, 'Protein': 65, 'Carbs': 300, 'Fat': 70, 'Fiber': 25};
  }

  // ───────────────────── BARCODE & API ─────────────────────
  Future<NutritionModel?> fetchNutritionFromBarcode(String barcode) async {
    try {
      final url = Uri.parse('https://world.openfoodfacts.org/api/v0/product/$barcode.json');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1) {
          final product = data['product'];
          final nutriments = product['nutriments'];
          
          return NutritionModel(
            name: product['product_name'] ?? 'Unknown Product',
            category: 'Snacks', // Default, user can change
            calories: (nutriments['energy-kcal_100g'] as num?)?.toDouble() ?? 0.0,
            protein: (nutriments['proteins_100g'] as num?)?.toDouble() ?? 0.0,
            carbs: (nutriments['carbohydrates_100g'] as num?)?.toDouble() ?? 0.0,
            fat: (nutriments['fat_100g'] as num?)?.toDouble() ?? 0.0,
            fiber: (nutriments['fiber_100g'] as num?)?.toDouble() ?? 0.0,
            timestamp: DateTime.now(),
            imageUrl: product['image_front_url'],
          );
        }
      }
    } catch (e) {
      debugPrint('Error scanning barcode: $e');
    }
    return null;
  }

  // ───────────────────── GOAL ACHIEVEMENT ─────────────────────
  Future<void> _checkGoalAchievement() async {
    final goals = dailyGoals;
    final calGoal = goals['Calories'] ?? 2000;
    
    // Check if within 5% range of goal
    final range = calGoal * 0.05;
    if ((_totalCalories >= calGoal - range) && (_totalCalories <= calGoal + range)) {
       // Check if we already notified today
       final prefs = await SharedPreferences.getInstance();
       final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
       final lastNotified = prefs.getString('last_goal_notification');
       
       if (lastNotified != todayStr) {
         await NotificationService().showNotification(
           'Goal Achieved! 🎉', 
           'Congratulations! You hit your calorie goal of ${calGoal.toInt()} kcal today!',
           type: 'goal_reached'
         );
         await prefs.setString('last_goal_notification', todayStr);
       }
    }
  }

  // ───────────────────── SMART DIET PLAN ─────────────────────
  List<Map<String, dynamic>> getRecommendedMeals(String category) {
    final goalLower = _selectedGoal.toLowerCase();
    final categoryLower = category.toLowerCase();
    
    // Logic: 
    // Weight Loss -> Low Carb, High Protein, Low Calorie
    // Muscle Gain -> High Carb, High Protein, Moderate Calorie
    // Maintenance -> Balanced
    
    final allMeals = _getMealRecommendations();
    
    if (goalLower.contains('loss')) {
       return allMeals['weight_loss']?[categoryLower] ?? [];
    } else if (goalLower.contains('gain') || goalLower.contains('muscle')) {
       return allMeals['muscle_gain']?[categoryLower] ?? [];
    } else {
       return allMeals['maintenance']?[categoryLower] ?? [];
    }
  }

  Map<String, Map<String, List<Map<String, dynamic>>>> _getMealRecommendations() {
    return {
      'weight_loss': {
        'breakfast': [
          {'name': 'Eggs & Avocado', 'calories': 150, 'protein': 20, 'carbs': 2, 'fat': 15, 'fiber': 7, 'imageUrl': 'assets/food/breakfast/eggs_avocado.png'},
          {'name': 'Greek Yogurt & Berries', 'calories': 180, 'protein': 15, 'carbs': 15, 'fat': 0, 'fiber': 4, 'imageUrl': 'assets/food/breakfast/yogurt_berries.png'},
        ],
        'lunch': [
          {'name': 'Grilled Chicken Salad', 'calories': 300, 'protein': 35, 'carbs': 10, 'fat': 12, 'fiber': 6, 'imageUrl': 'assets/food/lunch/chicken_salad.png'},
          {'name': 'Quinoa Salad', 'calories': 250, 'protein': 12, 'carbs': 45, 'fat': 10, 'fiber': 8, 'imageUrl': 'assets/food/lunch/quinoa_salad.png'},
        ],
        'dinner': [
          {'name': 'Fish & Veggies', 'calories': 280, 'protein': 30, 'carbs': 8, 'fat': 10, 'fiber': 5, 'imageUrl': 'assets/food/dinner/fish_veggies.png'},
          {'name': 'Chicken & Sweet Potato', 'calories': 350, 'protein': 30, 'carbs': 40, 'fat': 8, 'fiber': 6, 'imageUrl': 'assets/food/dinner/chicken_sweetpotato.png'},
        ],
        'snacks': [
          {'name': 'Apple & Almonds', 'calories': 150, 'protein': 4, 'carbs': 25, 'fat': 12, 'fiber': 5, 'imageUrl': 'assets/food/snacks/apple_almonds.png'},
        ],
      },
      'muscle_gain': {
        'breakfast': [
          {'name': 'Oatmeal with Fruits', 'calories': 450, 'protein': 15, 'carbs': 60, 'fat': 20, 'fiber': 8, 'imageUrl': 'assets/food/breakfast/oatmeal_fruits.png'},
          {'name': 'Protein Pancakes', 'calories': 400, 'protein': 30, 'carbs': 45, 'fat': 10, 'fiber': 3, 'imageUrl': 'assets/food/breakfast/protein_pancakes.png'},
        ],
        'lunch': [
          {'name': 'Beef & Rice Bowl', 'calories': 700, 'protein': 50, 'carbs': 90, 'fat': 15, 'fiber': 6, 'imageUrl': 'assets/food/lunch/beef_rice.png'},
          {'name': 'Chicken Sandwich', 'calories': 550, 'protein': 40, 'carbs': 60, 'fat': 20, 'fiber': 8, 'imageUrl': 'assets/food/lunch/chicken_sandwich.png'},
        ],
        'dinner': [
          {'name': 'Salmon & Asparagus', 'calories': 650, 'protein': 40, 'carbs': 50, 'fat': 30, 'fiber': 10, 'imageUrl': 'assets/food/dinner/salmon_asparagus.png'},
          {'name': 'Pasta & Meatballs', 'calories': 750, 'protein': 45, 'carbs': 80, 'fat': 25, 'fiber': 8, 'imageUrl': 'assets/food/dinner/pasta_meatballs.png'},
        ],
        'snacks': [
          {'name': 'Protein Shake', 'calories': 250, 'protein': 30, 'carbs': 10, 'fat': 5, 'fiber': 2, 'imageUrl': 'assets/food/snacks/protein_shake.png'},
          {'name': 'Nuts & Fruits', 'calories': 400, 'protein': 10, 'carbs': 30, 'fat': 30, 'fiber': 8, 'imageUrl': 'assets/food/snacks/nuts_fruits.png'},
        ],
      },
      'maintenance': {
        'breakfast': [
          {'name': 'Eggs & Avocado', 'calories': 350, 'protein': 25, 'carbs': 20, 'fat': 25, 'fiber': 8, 'imageUrl': 'assets/food/breakfast/eggs_avocado.png'},
        ],
        'lunch': [
          {'name': 'Chicken Sandwich', 'calories': 450, 'protein': 25, 'carbs': 50, 'fat': 15, 'fiber': 6, 'imageUrl': 'assets/food/lunch/chicken_sandwich.png'},
        ],
        'dinner': [
          {'name': 'Pasta & Meatballs', 'calories': 600, 'protein': 30, 'carbs': 70, 'fat': 20, 'fiber': 8, 'imageUrl': 'assets/food/dinner/pasta_meatballs.png'},
        ],
        'snacks': [
          {'name': 'Banana Smoothie', 'calories': 250, 'protein': 10, 'carbs': 40, 'fat': 5, 'fiber': 4, 'imageUrl': 'assets/food/snacks/banana_smoothie.png'},
        ],
      },
    };
  }
}
