import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/steps_provider.dart';
import '../providers/hydration_provider.dart';
import '../providers/workouts_provider.dart';
import '../providers/nutrition_provider.dart';
import '../providers/gps_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/notification_provider.dart';
import '../models/workout_model.dart';
import '../utils/theme.dart';

import 'steps_screen.dart';
import 'nutrition_screen.dart';
import 'calories_screen.dart';
import 'workouts_screen.dart';
import 'workout_detail_screen.dart';
import 'notifications_screen.dart';
import 'gps_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshAllData());
  }

  Future<void> _refreshAllData() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    try {
      final steps = Provider.of<StepsProvider>(context, listen: false);
      final hydration = Provider.of<HydrationProvider>(context, listen: false);
      final workouts = Provider.of<WorkoutsProvider>(context, listen: false);
      final nutrition = Provider.of<NutritionProvider>(context, listen: false);
      final profile = Provider.of<ProfileProvider>(context, listen: false);
      final notifications = Provider.of<NotificationProvider>(context, listen: false);
      final gps = Provider.of<GPSProvider>(context, listen: false);

      profile.setUserId(profile.uid ?? '');

      await Future.wait([
        steps.fetchTodaySteps(),
        hydration.fetchTodayHydration(),
        workouts.fetchWorkouts(),
        nutrition.loadTodayData(profile.uid ?? ''),
        notifications.loadNotifications(),
        gps.fetchRecentRoutes(),
      ]);
    } catch (e) {
      debugPrint('Home refresh error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to refresh data: $e',
              style: AppText.body.copyWith(color: AppColors.white),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarBackground,
        elevation: 0,
        toolbarHeight: 80,
        title: Consumer<ProfileProvider>(
          builder: (context, profile, _) {
            final name = profile.name;
            final hour = DateTime.now().hour;
            String greeting = 'Good Morning';
            if (hour >= 12 && hour < 17) {
              greeting = 'Good Afternoon';
            } else if (hour >= 17 && hour < 21) greeting = 'Good Evening';
            else if (hour >= 21 || hour < 5) greeting = 'Good Night';
            
            return Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/profile'),
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
                      boxShadow: AppTheme.smallShadow,
                    ),
                    child: ClipOval(
                      child: profile.profileImage != null
                          ? (kIsWeb 
                              ? Image.network(profile.profileImage!.path, fit: BoxFit.cover) 
                              : Image.file(File(profile.profileImage!.path), fit: BoxFit.cover))
                          : Container(
                              color: AppColors.primary.withOpacity(0.1),
                              child: Icon(Icons.person, color: AppColors.primary),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$greeting,', 
                      style: AppText.bodySmall.copyWith(color: AppColors.textSecondary)
                    ),
                    Text('$name 👋', 
                      style: AppText.headlineSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary
                      )
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notif, _) {
              final unread = notif.unreadCount;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications_none_rounded, 
                      size: 28,
                      color: AppColors.textSecondary
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsScreen())
                    ),
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAllData,
        color: AppColors.primary,
        child: _isRefreshing
            ? Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDailyStats(),
                    _buildTodayAchievement(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: Text(
                        'Your Focus',
                        style: AppText.headlineSmall.copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                    _buildGoalBasedSection(),
                    _buildTodaysRecommendation(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: Text(
                        'Performance Tracking',
                        style: AppText.headlineSmall.copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                    _buildSecondaryFeatures(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: Text(
                        'Weekly Activity',
                        style: AppText.headlineSmall.copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                    _buildWeeklyProgress(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
      ),
      floatingActionButton: Consumer<GPSProvider>(
        builder: (context, gps, _) => FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GpsScreen())
          ),
          icon: Icon(
            gps.isTracking ? Icons.stop_rounded : Icons.play_arrow_rounded,
            color: AppColors.white,
          ),
          label: Text(
            gps.isTracking ? 'Stop GPS' : 'Start GPS',
            style: AppText.button,
          ),
          backgroundColor: gps.isTracking ? AppColors.error : AppColors.primary,
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildDailyStats() {
    return Consumer6<StepsProvider, HydrationProvider, WorkoutsProvider, NutritionProvider, GPSProvider, NotificationProvider>(
      builder: (context, steps, hydration, workouts, nutrition, gps, notifications, _) {
        final stepProgress = steps.progressPercentage;
        final hydrationProgress = hydration.progressPercentage;
        final calorieProgress = nutrition.calorieProgress;
        final todaySessions = workouts.workoutHistory.where((s) => 
            s.completedAt.day == DateTime.now().day && 
            s.completedAt.month == DateTime.now().month && 
            s.completedAt.year == DateTime.now().year
        ).toList();
        final todayBurned = todaySessions.fold(0, (sum, s) => sum + s.caloriesBurned);
        final workoutProgress = todaySessions.isNotEmpty ? 1.0 : 0.0;

        return SizedBox(
          height: 170,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            children: [
              _statCard(
                'Steps',
                '${steps.steps}',
                'of ${steps.goal}',
                stepProgress,
                Icons.directions_walk_rounded,
                AppColors.stepsColor,
                AppColors.stepsColorLight,
              ),
              _statCard(
                'Hydration',
                '${hydration.currentGlasses}',
                'of ${hydration.goalInGlasses} gl',
                hydrationProgress,
                Icons.water_drop_rounded,
                AppColors.hydrationColor,
                AppColors.hydrationColorLight,
              ),
              _statCard(
                'Calories',
                '${nutrition.totalCalories.toInt()}',
                'kcal consumed',
                calorieProgress,
                Icons.local_fire_department_rounded,
                AppColors.calories,
                AppColors.caloriesLight,
              ),
              _statCard(
                'Workout',
                '${todaySessions.length}',
                '$todayBurned kcal burned',
                workoutProgress,
                Icons.fitness_center_rounded,
                AppColors.workout,
                AppColors.workout.withOpacity(0.1),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(
    String label,
    String value,
    String subValue,
    double progress,
    IconData icon,
    Color color,
    Color bgColor,
  ) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const Spacer(),
          Text(
            value,
            style: AppText.displayMedium.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subValue,
            style: AppText.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xs),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalBasedSection() {
    return Consumer4<ProfileProvider, WorkoutsProvider, HydrationProvider, NutritionProvider>(
      builder: (context, profile, workouts, hydration, nutrition, _) {
        final goal = profile.goal;
        final goalTitle = goal.toLowerCase().contains('loss') ? 'Weight Loss' :
                          goal.toLowerCase().contains('muscle') ? 'Muscle Gain' :
                          goal.toLowerCase().contains('gain') ? 'Weight Gain' :
                          'Maintenance';

        final icon = goal.toLowerCase().contains('loss') ? Icons.local_fire_department_rounded :
                     goal.toLowerCase().contains('muscle') ? Icons.fitness_center_rounded :
                     goal.toLowerCase().contains('gain') ? Icons.trending_up_rounded :
                     Icons.balance_rounded;

        final color = goal.toLowerCase().contains('loss') ? AppColors.calories :
                       goal.toLowerCase().contains('muscle') ? AppColors.workout :
                       goal.toLowerCase().contains('gain') ? AppColors.stepsColor :
                       AppColors.secondary;

        final recommendedWorkouts = workouts.getWorkoutsByGoal(goal);
        final recommendedWorkout = recommendedWorkouts.isNotEmpty ? recommendedWorkouts.first : null;
        
        final waterGoal = (hydration.dailyGoal / 1000).toStringAsFixed(1);
        final calorieGoal = nutrition.dailyGoals['Calories']?.toInt() ?? 2000;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppTheme.cardShadow,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Goal-Based Focus',
                          style: AppText.label.copyWith(color: AppColors.textSecondary)
                        ),
                        Text(
                          goalTitle,
                          style: AppText.title.copyWith(color: color)
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (recommendedWorkout != null) ...[
                Text(
                  'Recommended Action: ${recommendedWorkout.name}',
                  style: AppText.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _goalChip(
                    Icons.stars_rounded,
                    '${calorieGoal}kcal ${goal.toLowerCase().contains('loss') ? 'Deficit' : goal.toLowerCase().contains('gain') ? 'Surplus' : 'Target'}',
                    color
                  ),
                  _goalChip(
                    Icons.water_drop_rounded,
                    '${waterGoal}L Target',
                    AppColors.hydrationColor
                  ),
                  _goalChip(
                    Icons.fitness_center_rounded,
                    goal.toLowerCase().contains('loss') ? 'Cardio Focus' : 'Strength Focus',
                    AppColors.workout
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _goalChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppText.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryFeatures() {
    return GridView.count(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _featureTile(
          'GPS Tracker',
          Icons.location_on_rounded,
          AppColors.secondary,
          const Color(0xFFEEF2FF),
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GpsScreen()))
        ),
        _featureTile(
          'History',
          Icons.history_rounded,
          AppColors.textMuted,
          AppColors.surfaceVariant,
          () => Navigator.pushNamed(context, '/workout-history')
        ),
        _featureTile(
          'Statistics',
          Icons.bar_chart_rounded,
          AppColors.stepsColor,
          AppColors.stepsColorLight,
          () => Navigator.pushNamed(context, '/workout-stats')
        ),
        _featureTile(
          'Hydration',
          Icons.water_drop_rounded,
          AppColors.hydrationColor,
          AppColors.hydrationColorLight,
          () => Navigator.pushNamed(context, '/hydration')
        ),
      ],
    );
  }

  Widget _featureTile(String title, IconData icon, Color color, Color bgColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
          boxShadow: AppTheme.smallShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: AppText.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysRecommendation() {
    return Consumer<WorkoutsProvider>(
      builder: (context, workouts, _) {
        final workout = workouts.todayWorkouts.isNotEmpty ? workouts.todayWorkouts.first : null;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.star_rounded, color: AppColors.white, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'AI Recommendation',
                    style: AppText.labelLarge.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      'Today',
                      style: AppText.labelSmall.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (workout != null) ...[
                Text(
                  workout.name,
                  style: AppText.headlineMedium.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${workout.duration} min • ${workout.level} level',
                  style: AppText.body.copyWith(
                    color: AppColors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => WorkoutDetailScreen(workout: workout)),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: Text(
                      'Start Now',
                      style: AppText.button.copyWith(color: AppColors.primary),
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  'Time to get moving!',
                  style: AppText.headlineSmall.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check out some workouts to stay on track with your goals.',
                  style: AppText.body.copyWith(
                    color: AppColors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeeklyProgress() {
    return Consumer5<StepsProvider, HydrationProvider, NutritionProvider, WorkoutsProvider, GPSProvider>(
      builder: (context, steps, hydration, nutrition, workouts, gps, _) {
        final stepWeekly = steps.history.isNotEmpty 
            ? (steps.history.map((h) => h.progressPercentage).reduce((a, b) => a + b) / steps.history.length * 100).toInt() 
            : 0;

        final hydrationWeekly = hydration.history.isNotEmpty
            ? (hydration.history.map((h) => h.amount).reduce((a, b) => a + b) / (hydration.dailyGoal * hydration.history.length) * 100).toInt()
            : 0;

        final nutritionWeekly = nutrition.nutriScore;
        final weekWorkouts = workouts.stats['weekWorkouts'] ?? 0;
        final workoutWeekly = weekWorkouts > 0 ? (weekWorkouts / 7 * 100).toInt().clamp(0, 100) : 0;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.border),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _progressBar('Steps Activity', stepWeekly, AppColors.stepsColor),
              const SizedBox(height: 20),
              _progressBar('Hydration Goal', hydrationWeekly, AppColors.hydrationColor),
              const SizedBox(height: 20),
              _progressBar('Nutrition Score', nutritionWeekly, AppColors.nutritionColor),
              const SizedBox(height: 20),
              _progressBar('Training Consistency', workoutWeekly, AppColors.workout),
            ],
          ),
        );
      },
    );
  }

  Widget _progressBar(String label, int percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppText.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '$percent%',
              style: AppText.titleSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: LinearProgressIndicator(
            value: percent / 100,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 0,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      backgroundColor: AppTheme.appBarBackground,
      elevation: 2,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: AppText.labelSmall.copyWith(fontWeight: FontWeight.w600),
      unselectedLabelStyle: AppText.labelSmall.copyWith(fontWeight: FontWeight.w500),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.directions_walk_rounded),
          label: 'Steps',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_fire_department_rounded),
          label: 'Calories',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.fitness_center_rounded),
          label: 'Workouts',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.restaurant_rounded),
          label: 'Nutrition',
        ),
      ],
      onTap: (index) {
        switch (index) {
          case 1:
            Navigator.push(context, MaterialPageRoute(builder: (_) => const StepsScreen()));
            break;
          case 2:
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CaloriesScreen()));
            break;
          case 3:
            Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkoutsScreen()));
            break;
          case 4:
            Navigator.push(context, MaterialPageRoute(builder: (_) => const NutritionScreen()));
            break;
        }
      },
    );
  }

  Widget _buildTodayAchievement() {
    return Consumer<WorkoutsProvider>(
      builder: (context, provider, _) {
        final history = provider.workoutHistory;
        final now = DateTime.now();
        final todaySessions = history.where((s) =>
            s.completedAt.year == now.year &&
            s.completedAt.month == now.month &&
            s.completedAt.day == now.day).toList();

        if (todaySessions.isEmpty) return const SizedBox.shrink();

        final session = todaySessions.first;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today\'s Achievement',
                style: AppText.title.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              _buildWorkoutResultCard(session),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWorkoutResultCard(WorkoutSession session) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.workout.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.workout.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.workout,
              shape: BoxShape.circle,
              boxShadow: AppTheme.smallShadow,
            ),
            child: Icon(Icons.stars_rounded, color: AppColors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.workout.name,
                  style: AppText.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${session.duration} min • ${session.caloriesBurned} kcal burned',
                  style: AppText.caption.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}