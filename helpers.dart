// lib/utils/helpers.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// =========================
/// TIME & GREETING HELPERS
/// =========================

/// Get time-based greeting (Good Morning/Afternoon/Evening/Night)
String getGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good Morning';
  if (hour < 17) return 'Good Afternoon';
  if (hour < 21) return 'Good Evening';
  return 'Good Night';
}

/// Get daily motivational quote (changes based on day of month)
String getDailyQuote() {
  final quotes = [
    'The only bad workout is the one that didn\'t happen.',
    'Don\'t stop when you\'re tired. Stop when you\'re done.',
    'Your body can stand almost anything. It\'s your mind you have to convince.',
    'Strive for progress, not perfection.',
    'The hardest lift of all is lifting your butt off the couch.',
    'Success starts with self‑discipline.',
    'You don\'t have to be great to start, but you have to start to be great.',
    'The pain you feel today will be the strength you feel tomorrow.',
    'Your health is an investment, not an expense.',
    'Fitness is not about being better than someone else. It\'s about being better than you used to be.',
    'The only way to do great work is to love what you do.',
    'Your future is created by what you do today, not tomorrow.',
    'Small steps every day lead to big results.',
    'Energy and persistence conquer all things.',
    'Believe you can and you\'re halfway there.',
    'The body achieves what the mind believes.',
    'Push yourself because no one else is going to do it for you.',
    'Dream it. Wish it. Do it.',
    'Great things never come from comfort zones.',
    'Sweat is just fat crying.',
  ];
  final index = DateTime.now().day % quotes.length;
  return quotes[index];
}

/// Get current time in 24-hour format (HH:mm)
String getCurrentTime24Hour() {
  final now = DateTime.now();
  return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
}

/// Get current time in 12-hour format with AM/PM
String getCurrentTime12Hour() {
  final now = DateTime.now();
  final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
  final ampm = now.hour >= 12 ? 'PM' : 'AM';
  return '${hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} $ampm';
}

/// Format a DateTime to HH:mm (24-hour)
String formatTime24Hour(DateTime time) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

/// Format a DateTime to 12-hour format with AM/PM
String formatTime12Hour(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final ampm = time.hour >= 12 ? 'PM' : 'AM';
  return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $ampm';
}

/// Get day name (Monday, Tuesday, etc.)
String getDayName(DateTime date) {
  return ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'][date.weekday - 1];
}

/// Get short day name (Mon, Tue, etc.)
String getShortDayName(DateTime date) {
  return ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][date.weekday - 1];
}

/// =========================
/// HYDRATION HELPERS
/// =========================

/// Save hydration intake locally (SharedPreferences)
Future<void> saveHydration(int ml) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_hydration_ml', ml);
    await prefs.setString('last_hydration_time', DateTime.now().toIso8601String());
  } catch (e) {
    debugPrint('Error saving hydration: $e');
  }
}

/// Get hydration intake from local storage
Future<int> getHydration() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('last_hydration_ml') ?? 0;
  } catch (e) {
    debugPrint('Error getting hydration: $e');
    return 0;
  }
}

/// Save hydration goal locally
Future<void> saveHydrationGoal(int ml) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('hydration_goal_ml', ml);
  } catch (e) {
    debugPrint('Error saving hydration goal: $e');
  }
}

/// Get hydration goal from local storage
Future<int> getHydrationGoal() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('hydration_goal_ml') ?? 3000;
  } catch (e) {
    debugPrint('Error getting hydration goal: $e');
    return 3000;
  }
}

/// Calculate hydration percentage
double calculateHydrationPercentage(int current, int goal) {
  if (goal <= 0) return 0.0;
  return (current / goal).clamp(0.0, 1.0);
}

/// Get hydration status message
String getHydrationStatus(int current, int goal) {
  final percentage = calculateHydrationPercentage(current, goal) * 100;
  if (percentage >= 100) return 'Great job! You reached your goal! 🎉';
  if (percentage >= 75) return 'Almost there! Keep going! 💪';
  if (percentage >= 50) return 'Halfway done! You can do it! ✨';
  if (percentage >= 25) return 'Good start! Keep hydrating! 💧';
  return 'Time to drink some water! 💦';
}

/// =========================
/// USER PREFERENCES HELPERS
/// =========================

/// Save user goal (Weight Loss/Muscle Gain/Maintenance)
Future<void> saveUserGoal(String goal) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_goal', goal);
  } catch (e) {
    debugPrint('Error saving user goal: $e');
  }
}

/// Get user goal
Future<String> getUserGoal() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_goal') ?? 'Weight Loss';
  } catch (e) {
    debugPrint('Error getting user goal: $e');
    return 'Weight Loss';
  }
}

/// Save user profile data
Future<void> saveUserProfile({
  required String name,
  required String email,
  required int age,
  required String gender,
  required double height,
  required double weight,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_email', email);
    await prefs.setInt('user_age', age);
    await prefs.setString('user_gender', gender);
    await prefs.setDouble('user_height', height);
    await prefs.setDouble('user_weight', weight);
  } catch (e) {
    debugPrint('Error saving user profile: $e');
  }
}

/// Get user name
Future<String> getUserName() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name') ?? 'Fitness Enthusiast';
  } catch (e) {
    debugPrint('Error getting user name: $e');
    return 'Fitness Enthusiast';
  }
}

/// Check if user is logged in
Future<bool> isUserLoggedIn() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  } catch (e) {
    debugPrint('Error checking login status: $e');
    return false;
  }
}

/// Set login status
Future<void> setLoginStatus(bool isLoggedIn) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', isLoggedIn);
  } catch (e) {
    debugPrint('Error setting login status: $e');
  }
}

/// =========================
/// UI & DISPLAY HELPERS
/// =========================

/// Show a snackbar anywhere in the app
void showSnackBar(
  BuildContext context,
  String message, {
  Color backgroundColor = Colors.blueAccent,
  Duration duration = const Duration(seconds: 3),
  bool isError = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      duration: duration,
      behavior: SnackBarBehavior.floating,
      backgroundColor: isError ? Colors.redAccent : backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
    ),
  );
}

/// Show success snackbar
void showSuccessSnackBar(BuildContext context, String message) {
  showSnackBar(
    context,
    message,
    backgroundColor: Colors.green,
    isError: false,
  );
}

/// Show error snackbar
void showErrorSnackBar(BuildContext context, String message) {
  showSnackBar(
    context,
    message,
    backgroundColor: Colors.redAccent,
    isError: true,
  );
}

/// Clamp a value between min and max
T clampValue<T extends num>(T value, T min, T max) {
  if (value < min) return min;
  if (value > max) return max;
  return value;
}

/// Format number with commas (e.g., 10000 → 10,000)
String formatNumberWithCommas(int number) {
  return number.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  );
}

/// Format double to 1 decimal place
String formatDouble(double value) {
  return value.toStringAsFixed(1);
}

/// Calculate BMI
double calculateBMI(double weightKg, double heightCm) {
  if (heightCm <= 0) return 0;
  final heightM = heightCm / 100;
  return weightKg / (heightM * heightM);
}

/// Get BMI category
String getBMICategory(double bmi) {
  if (bmi < 18.5) return 'Underweight';
  if (bmi < 25) return 'Normal';
  if (bmi < 30) return 'Overweight';
  return 'Obese';
}

/// Calculate daily calorie needs (Harris-Benedict equation)
int calculateDailyCalories({
  required double weight,
  required double height,
  required int age,
  required String gender,
  required String activityLevel,
  required String goal,
}) {
  // Basal Metabolic Rate (BMR)
  double bmr;
  if (gender.toLowerCase() == 'male') {
    bmr = 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
  } else {
    bmr = 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
  }

  // Activity multiplier
  Map<String, double> activityMultipliers = {
    'sedentary': 1.2,
    'light': 1.375,
    'moderate': 1.55,
    'active': 1.725,
    'very_active': 1.9,
  };

  double multiplier = activityMultipliers[activityLevel.toLowerCase()] ?? 1.2;
  double maintenanceCalories = bmr * multiplier;

  // Adjust based on goal
  Map<String, double> goalAdjustments = {
    'weight loss': -500,
    'muscle gain': 500,
    'maintenance': 0,
  };

  double adjustment = goalAdjustments[goal.toLowerCase()] ?? 0;
  return (maintenanceCalories + adjustment).round();
}

/// Get goal-based water recommendation (in ml)
int getGoalWaterRecommendation(String goal) {
  Map<String, int> recommendations = {
    'weight loss': 3000,
    'muscle gain': 3500,
    'maintenance': 2500,
  };
  return recommendations[goal.toLowerCase()] ?? 3000;
}

/// Get goal-based workout recommendations
List<String> getGoalWorkouts(String goal) {
  Map<String, List<String>> workouts = {
    'weight loss': ['Cardio', 'HIIT', 'Running', 'Cycling', 'Swimming'],
    'muscle gain': ['Weight Training', 'Strength', 'Compound Lifts', 'Bodybuilding'],
    'maintenance': ['Yoga', 'Pilates', 'Walking', 'Light Cardio', 'Stretching'],
  };
  return workouts[goal.toLowerCase()] ?? ['Cardio', 'Strength'];
}

/// =========================
/// VALIDATION HELPERS
/// =========================

/// Validate email format
bool isValidEmail(String email) {
  return RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(email);
}

/// Validate password strength
bool isValidPassword(String password) {
  return password.length >= 6;
}

/// Validate name (at least 2 characters)
bool isValidName(String name) {
  return name.trim().length >= 2;
}

/// Validate age (1-120)
bool isValidAge(int age) {
  return age >= 1 && age <= 120;
}

/// Validate height (50-250 cm)
bool isValidHeight(double height) {
  return height >= 50 && height <= 250;
}

/// Validate weight (20-300 kg)
bool isValidWeight(double weight) {
  return weight >= 20 && weight <= 300;
}