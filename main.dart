import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

// Services
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/firestore_service.dart';
import 'services/shared_prefs_service.dart';

// Providers
import 'providers/steps_provider.dart';
import 'providers/workouts_provider.dart';
import 'providers/nutrition_provider.dart';
import 'providers/gps_provider.dart';
import 'providers/hydration_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/notification_provider.dart';

// Screens
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/nutrition_screen.dart';
import 'screens/workouts_screen.dart';
import 'screens/workout_stats_screen.dart';
import 'screens/steps_screen.dart';
import 'screens/calories_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/workout_detail_screen.dart';
import 'screens/workout_history_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/gps_screen.dart';
import 'screens/hydration_screen.dart';

// Models
import 'models/workout_model.dart';

// Utils
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('🚀 App starting...');
  try {
    debugPrint('⏳ Initializing Firebase...');
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    debugPrint('✅ Firebase Initialized');

    debugPrint('⏳ Initializing NotificationService...');
    await NotificationService().init();
    debugPrint('✅ NotificationService Initialized');
    
    // ✅ Initialize SharedPrefs early for reset logic
    debugPrint('⏳ Initializing SharedPrefs...');
    final prefsRepo = SharedPrefsService();
    await prefsRepo.init();
    debugPrint('✅ SharedPrefs Initialized');

    // 🔄 Master Reset (Remove this in production builds if needed)
    // This ensures that fresh APK builds start from the Signup Screen.
    if (!prefsRepo.containsKey('master_reset_done_v1')) {
      debugPrint('🧹 Performing Master Reset...');
      await prefsRepo.clearAll();
      await prefsRepo.init(); // Re-init after clear
      await prefsRepo.setStringList('master_reset_done_v1', ['true']);
      debugPrint('🚀 Master Reset Performed: Starting fresh from Signup.');
    }

    // ✅ Initialize AuthService to load user session
    debugPrint('⏳ Initializing AuthService...');
    final authService = AuthService();
    await authService.initialize();
    debugPrint('✅ AuthService Initialized');
    
    runApp(MyApp(authService: authService));
    debugPrint('🚀 runApp called');
  } catch (e, stack) {
    debugPrint('❌ Firebase/App init failed: $e\n$stack');
    runApp(const ErrorApp());
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme, // ✅ Use AppTheme here
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, 
                  size: 80, 
                  color: AppColors.error // ✅ Use theme color
                ),
                const SizedBox(height: 24),
                Text(
                  'App Initialization Failed',
                  style: AppText.headlineSmall.copyWith( // ✅ Use theme text style
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Please check your internet connection\nand restart the app.',
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith( // ✅ Use theme text style
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  const MyApp({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => SharedPrefsService()),
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider(create: (_) => StepsProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutsProvider()),
        ChangeNotifierProvider(create: (_) => NutritionProvider()),
        ChangeNotifierProvider(create: (_) => GPSProvider()),
        ChangeNotifierProvider(create: (_) => HydrationProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(
          create: (_) => ProfileProvider(
            firestoreService: FirestoreService(),
            sharedPrefs: SharedPrefsService(),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'FitTrack Pro',
        theme: AppTheme.theme, // ✅ Use only light theme (as per instructions)
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/welcome': (context) => const WelcomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/home': (context) => const HomeScreen(),
          '/nutrition': (context) => const NutritionScreen(),
          '/workouts': (context) => const WorkoutsScreen(),
          '/workout-stats': (context) => const WorkoutStatsScreen(),
          '/steps': (context) => const StepsScreen(),
          '/calories': (context) => const CaloriesScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/hydration': (context) => const HydrationScreen(),
          '/notifications': (context) => const NotificationsScreen(),
          '/gps': (context) => const GpsScreen(),
          '/workout-detail': (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Workout?;
            return WorkoutDetailScreen(workout: args ?? Workout.empty());
          },
          '/workout-history': (context) => const WorkoutHistoryScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final prefs = Provider.of<SharedPrefsService>(context, listen: false);

    return StreamBuilder<User?>(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
           return _buildErrorScreen('Auth Stream Error: ${snapshot.error}');
        }

        // 🕐 Show loading while initializing
        if (snapshot.connectionState == ConnectionState.waiting || auth.isLoading) {
          return _buildSplashLoading();
        }

        final user = snapshot.data;

        if (user != null) {
          // --- LOGGED IN FLOW ---
          final profileData = prefs.getUserProfile();
          final hasCompletedProfile = profileData != null &&
              profileData['name'] != null &&
              (profileData['name'] as String).isNotEmpty;

          // 1️⃣ Show Welcome Screen if profile is missing OR explicitly requested
          if (prefs.shouldShowWelcome || !hasCompletedProfile) {
             _initializeProviders(context, user.uid);
             return const WelcomeScreen();
          }

          // 2️⃣ Go to Home Screen
          _initializeProviders(context, user.uid);
          return const HomeScreen();
          
        } else {
          // --- LOGGED OUT FLOW ---
          // 🆕 Start at Signup if it's the first time
          if (prefs.isFirstTime) {
            return const SignupScreen();
          } else {
            return const LoginScreen();
          }
        }
      },
    );
  }

  void _initializeProviders(BuildContext context, String uid) {
    // Standard initialization for all reactive providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        // Core Profile & Auth context
        context.read<ProfileProvider>().setUserId(uid);
        
        // Activity & Location
        context.read<StepsProvider>().setUserId(uid);
        context.read<GPSProvider>().setUserId(uid);
        context.read<GPSProvider>().loadLastLocation();
        
        // Nutrition & Hydration (Fix for "Failed to add water")
        context.read<HydrationProvider>().setUserId(uid);
        context.read<NutritionProvider>().setUserId(uid);
        
        // Workouts & Notifications
        context.read<WorkoutsProvider>().setUserId(uid);
        context.read<NotificationProvider>().setUserId(uid);
        context.read<NotificationProvider>().loadNotifications();
      }
    });
  }

  Widget _buildSplashLoading() {
    return Scaffold(
      backgroundColor: AppColors.background, // ✅ Use theme color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: AppColors.primary, // ✅ Use theme color
            ),
            const SizedBox(height: 20),
            Text(
              'Loading...',
              style: AppText.bodyLarge.copyWith( // ✅ Use theme text style
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Scaffold(
      backgroundColor: AppColors.background, // ✅ Use theme color
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, 
                color: AppColors.error, // ✅ Use theme color
                size: 64
              ),
              const SizedBox(height: 16),
              Text(
                'Authentication Error', 
                style: AppText.headlineSmall.copyWith( // ✅ Use theme text style
                  color: AppColors.textPrimary,
                )
              ),
              const SizedBox(height: 8),
              Text(
                error, 
                textAlign: TextAlign.center, 
                style: AppText.body.copyWith( // ✅ Use theme text style
                  color: AppColors.textSecondary,
                )
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, // ✅ Use theme color
                  foregroundColor: AppColors.white,
                ),
                onPressed: () => FirebaseAuth.instance.signOut(),
                child: Text(
                  'Reset and try again',
                  style: AppText.button.copyWith( // ✅ Use theme text style
                    color: AppColors.white,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}


// ---------------------
// Navigation Helpers
// ---------------------
class AppNavigator {
  static void goToHome(BuildContext context) =>
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);

  static void goToLogin(BuildContext context) =>
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);

  static void goToSignup(BuildContext context) =>
      Navigator.pushNamed(context, '/signup');

  static void goToProfile(BuildContext context) =>
      Navigator.pushNamed(context, '/profile');

  static Future<void> logout(BuildContext context) async {
    await context.read<AuthService>().signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/welcome', (_) => false);
    }
  }
}