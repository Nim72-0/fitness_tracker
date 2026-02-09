import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/nutrition_provider.dart';
import '../providers/steps_provider.dart';
import '../providers/workouts_provider.dart';
import '../providers/profile_provider.dart';
import '../utils/theme.dart';
import '../widgets/calories_line_chart.dart';

class CaloriesScreen extends StatefulWidget {
  const CaloriesScreen({super.key});

  @override
  State<CaloriesScreen> createState() => _CaloriesScreenState();
}

class _CaloriesScreenState extends State<CaloriesScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ringController;
  late Animation<double> _ringAnimation;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _ringAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeOutCubic),
    );
    _ringController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  void _refreshData() {
    final uid = context.read<NutritionProvider>().user?.uid;
    if (uid != null) {
      context.read<NutritionProvider>().loadTodayData(uid);
      context.read<StepsProvider>().fetchTodaySteps();
      context.read<WorkoutsProvider>().setUserId(uid); 
    }
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  int _calculateStepCalories(int steps, double weightKg) {
    return ((weightKg / 70.0) * 0.04 * steps).round();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<NutritionProvider, StepsProvider, WorkoutsProvider>(
      builder: (context, nutrition, stepsProvider, workouts, _) {
        final profile = context.read<ProfileProvider>();
        final userGoal = nutrition.selectedGoal.toLowerCase();
        
        final double foodCalories = nutrition.totalCalories;
        final int stepsCount = stepsProvider.todaySteps.steps;
        final double userWeight = profile.user?.weight ?? 70.0;
        final int stepCalories = _calculateStepCalories(stepsCount, userWeight);

        final now = DateTime.now();
        final todayWorkouts = workouts.workoutHistory.where((w) {
          return w.completedAt.year == now.year &&
                 w.completedAt.month == now.month &&
                 w.completedAt.day == now.day;
        }).toList();
        final int workoutCalories = todayWorkouts.fold(0, (sum, w) => sum + w.caloriesBurned);

        final int totalActiveBurn = stepCalories + workoutCalories;
        final double baseTarget = nutrition.dailyGoals['Calories'] ?? 2000.0;
        final double adjustedTarget = baseTarget + totalActiveBurn;
        final double calorieBalance = adjustedTarget - foodCalories;
        final double netIntake = foodCalories - totalActiveBurn;
        
        String statusMessage = "";
        Color statusColor = AppTheme.primaryColor;
        double progressPercent = (foodCalories / adjustedTarget).clamp(0.0, 1.0);

        if (userGoal.contains("loss")) {
           if (calorieBalance < -200) {
             statusMessage = "Careful! You're over your limit.";
             statusColor = AppColors.error;
           } else if (calorieBalance < 200) {
             statusMessage = "Perfect spot! Keep it up.";
             statusColor = AppColors.success;
           } else {
             statusMessage = "You have plenty of room left.";
             statusColor = AppTheme.primaryColor;
           }
        } else if (userGoal.contains("gain") || userGoal.contains("muscle")) {
           if (calorieBalance > 500) {
             statusMessage = "Keep eating! You need more fuel.";
             statusColor = AppColors.warning;
           } else if (calorieBalance > 0) {
              statusMessage = "Almost there! One snack away.";
              statusColor = AppTheme.primaryColor;
           } else {
             statusMessage = "Great! You hit your surplus.";
             statusColor = AppColors.success;
           }
        } else {
           if (calorieBalance.abs() < 200) {
             statusMessage = "Perfectly balanced.";
             statusColor = AppColors.success;
           } else if (calorieBalance > 0) {
             statusMessage = "Under limit (Maintenance).";
             statusColor = AppTheme.primaryColor;
           } else {
             statusMessage = "Over limit (Maintenance).";
             statusColor = AppColors.warning;
           }
        }

        return Scaffold(
          backgroundColor: AppTheme.scaffoldBackground,
          body: CustomScrollView(
            slivers: [
              _buildAppBar(context),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildDynamicMessage(statusMessage, statusColor),
                      const SizedBox(height: 20),

                      _buildSmartRing(
                        context, 
                        foodCalories, 
                        totalActiveBurn, 
                        baseTarget, 
                        userGoal,
                        statusColor
                      ),
                      const SizedBox(height: 24),

                      _buildBreakdownRow(foodCalories, stepCalories, workoutCalories, stepsCount),
                      const SizedBox(height: 24),

                      if (userGoal.contains('gain') || userGoal.contains('muscle'))
                        _buildMacroHighlight(nutrition),

                      _buildActionButtons(context, userGoal),
                      const SizedBox(height: 24),

                      _buildHistorySection(context),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 80.0,
      floating: true,
      pinned: true,
      backgroundColor: AppTheme.appBarBackground,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: Text(
          'Calories & Energy',
          style: AppText.headlineMedium.copyWith(color: AppColors.textPrimary),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: AppColors.textSecondary),
          onPressed: _refreshData,
        ),
        IconButton(
          icon: Icon(Icons.settings_outlined, color: AppColors.textSecondary),
          onPressed: () {
            Navigator.pushNamed(context, '/profile'); 
          },
        ),
      ],
    );
  }

  Widget _buildDynamicMessage(String message, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insights, color: color, size: 20),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              message,
              style: AppText.body.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartRing(BuildContext context, double food, int burned, double baseGoal, String goal, Color statusColor) {
    final double net = food - burned;
    final double remaining = (baseGoal + burned) - food;
    final double denominator = baseGoal + burned;
    final double rawProgress = denominator > 0 ? food / denominator : 0.0;
    final double visualProgress = rawProgress.clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: _ringAnimation,
      builder: (context, child) {
        return Container(
          height: 320,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 220,
                width: 220,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 90,
                    startDegreeOffset: 270,
                    sections: [
                      PieChartSectionData(
                        color: statusColor,
                        value: visualProgress * _ringAnimation.value,
                        title: '',
                        radius: 20,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        color: AppColors.surfaceVariant,
                        value: 1 - (visualProgress * _ringAnimation.value),
                        title: '',
                        radius: 20,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
              ),
              
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Remaining',
                    style: AppText.label.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 4),
                  if (goal.contains('gain') && remaining < 0)
                    Text(
                      'SURPLUS',
                      style: AppText.titleMedium.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  else
                    Text(
                      remaining.toInt().toString(),
                      style: AppText.displayMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 48,
                      ),
                    ),
                  Text(
                    'kcal',
                    style: AppText.body.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
              
              Positioned(
                bottom: 24,
                child: Text(
                  'Daily Target: ${(baseGoal + burned).toInt()} kcal', 
                  style: AppText.bodySmall.copyWith(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildBreakdownRow(double food, int stepsCal, int workoutCal, int stepsCount) {
    return Row(
      children: [
        Expanded(
          child: _buildMiniCard(
            label: 'Eaten',
            value: '${food.toInt()}',
            icon: Icons.restaurant,
            color: AppColors.hydrationColor,
            sublabel: 'kcal',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniCard(
            label: 'Burned',
            value: '${stepsCal + workoutCal}',
            icon: Icons.local_fire_department,
            color: AppColors.calories,
            sublabel: '$stepsCount steps',
          ),
        ),
      ],
    );
  }

  Widget _buildMiniCard({
    required String label, 
    required String value, 
    required IconData icon, 
    required Color color, 
    String? sublabel
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const Spacer(),
              Text(label, style: AppText.labelSmall.copyWith(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: AppText.headlineMedium.copyWith(fontSize: 22)),
          if (sublabel != null)
            Text(sublabel, style: AppText.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
  
  Widget _buildMacroHighlight(NutritionProvider nutrition) {
    final protein = nutrition.totalProtein;
    final target = nutrition.dailyGoals['Protein'] ?? 150.0;
    final progress = (protein / target).clamp(0.0, 1.0);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.proteinColor.withOpacity(0.1),
            AppColors.proteinColor.withOpacity(0.05)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.proteinColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fitness_center, color: AppColors.proteinColor, size: 20),
              const SizedBox(width: 8),
              Text('Protein Focus', 
                style: AppText.titleSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.proteinColor
                )
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${protein.toInt()} / ${target.toInt()} g', 
                style: AppText.titleMedium
              ),
              Text('${(progress * 100).toInt()}%', 
                style: AppText.titleMedium.copyWith(color: AppColors.proteinColor)
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.surfaceVariant,
            color: AppColors.proteinColor,
            minHeight: 8,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          const SizedBox(height: 8),
          Text('Hit your protein goal to maximize muscle growth.', 
            style: AppText.caption.copyWith(color: AppColors.textMuted)
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, String goal) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                'Add Meal',
                Icons.add_circle_outline,
                AppColors.hydrationColor,
                () => Navigator.pushNamed(context, '/nutrition'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                'Log Workout',
                Icons.directions_run,
                AppColors.calories,
                () => Navigator.pushNamed(context, '/workouts'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (goal.contains('loss'))
          _buildFullWidthButton(
            context,
            'View Fat Burn Workouts',
            Icons.local_fire_department_outlined,
            AppColors.calories,
            () => Navigator.pushNamed(context, '/workouts'),
          )
        else if (goal.contains('stress') || goal == 'maintenance')
          _buildFullWidthButton(
            context,
            'Try Relaxation Yoga',
            Icons.self_improvement,
            AppColors.stepsColor,
            () => Navigator.pushNamed(context, '/workouts'),
          ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
          boxShadow: AppTheme.smallShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(label, style: AppText.labelLarge.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFullWidthButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(label, 
              style: AppText.labelLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: color
              )
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 14, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('History', style: AppText.headlineSmall),
              Text('Last 7 Days', style: AppText.label.copyWith(color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 16),
          const SizedBox(
            height: 200,
            child: CaloriesLineChart(data: []),
          ),
        ],
      ),
    );
  }
}