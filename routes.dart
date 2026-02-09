import 'package:flutter/material.dart';

// Models IMPORT
import 'models/workout_model.dart';

// Screens
import 'screens/signup_screen.dart';
import 'screens/login_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/steps_screen.dart';
import 'screens/gps_screen.dart';
import 'screens/calories_screen.dart';
import 'screens/workouts_screen.dart';
import 'screens/workout_detail_screen.dart';
import 'screens/workout_history_screen.dart';
import 'screens/workout_stats_screen.dart';
import 'screens/nutrition_screen.dart';
import 'screens/hydration_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/notifications_screen.dart';

class AppRoutes {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final routeName = settings.name ?? '/';
    
    switch (routeName) {
      case '/':
        // This is handled by AuthWrapper in main.dart, but kept for completeness
        return _buildRoute(Container()); // Placeholder, as initialRoute uses AuthWrapper
      case '/signup':
        return _buildRoute(SignupScreen());
      case '/login':
        return _buildRoute(LoginScreen());
      case '/welcome':
        return _buildRoute(WelcomeScreen());
      case '/home':
        return _buildRoute(HomeScreen());
      case '/steps':
        return _buildRoute(StepsScreen());
      case '/gps':
        return _buildRoute(GpsScreen());
      case '/calories':
        return _buildRoute(CaloriesScreen());
      case '/workouts':
        return _buildRoute(WorkoutsScreen());
      case '/workout-detail':
        final args = settings.arguments;
        if (args == null) {
          return _buildRoute(
            Scaffold(
              body: Center(child: Text('No workout selected')),
            ),
          );
        }
        // ✅ TYPE CAST FIX (unchanged)
        return _buildRoute(WorkoutDetailScreen(workout: args as Workout));
      case '/workout-history':
        return _buildRoute(WorkoutHistoryScreen());
      case '/workout-stats':
        return _buildRoute(WorkoutStatsScreen());
      case '/nutrition':
        return _buildRoute(NutritionScreen());
      case '/hydration':
        return _buildRoute(HydrationScreen());
      case '/profile':
        return _buildRoute(ProfileScreen());
      case '/notifications':
        return _buildRoute(NotificationsScreen());
      default:
        return _buildRoute(
          Scaffold(
            body: Center(child: Text('Page not found: $routeName')),
          ),
        );
    }
  }

  static MaterialPageRoute _buildRoute(Widget screen) {
    return MaterialPageRoute(builder: (_) => screen);
  }
}