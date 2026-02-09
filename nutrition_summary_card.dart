import 'package:flutter/material.dart';
import '../utils/theme.dart';

class NutritionSummaryCard extends StatelessWidget {
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double totalFiber;
  final Map<String, double> dailyGoals;
  final String goal;

  const NutritionSummaryCard({
    super.key,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.totalFiber,
    required this.dailyGoals,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    final goalColor = _getGoalColor();
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: goalColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'DAILY NUTRITION SUMMARY',
                  style: AppText.labelLarge.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Calories - Main Card
            _buildMacroCard(
              title: 'CALORIES',
              current: totalCalories,
              target: dailyGoals['Calories'] ?? 2200,
              unit: 'kcal',
              icon: Icons.local_fire_department,
              color: AppColors.calories,
              percentage: ((totalCalories / (dailyGoals['Calories'] ?? 2200)) * 100).clamp(0, 200),
            ),
            
            const SizedBox(height: 16),
            
            // Macronutrients Grid
            Row(
              children: [
                Expanded(
                  child: _buildMiniMacroCard(
                    title: 'PROTEIN',
                    current: totalProtein,
                    target: dailyGoals['Protein'] ?? 65,
                    unit: 'g',
                    color: AppColors.proteinColor,
                    icon: Icons.fitness_center,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMiniMacroCard(
                    title: 'CARBS',
                    current: totalCarbs,
                    target: dailyGoals['Carbs'] ?? 300,
                    unit: 'g',
                    color: AppColors.carbColor,
                    icon: Icons.energy_savings_leaf,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMiniMacroCard(
                    title: 'FAT',
                    current: totalFat,
                    target: dailyGoals['Fat'] ?? 70,
                    unit: 'g',
                    color: AppColors.fatColor,
                    icon: Icons.water_drop,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Fiber
            _buildFiberCard(),
            
            const SizedBox(height: 12),
            
            // Goal Status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: goalColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: goalColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    _getGoalIcon(),
                    color: goalColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Goal: $goal',
                          style: AppText.body.copyWith(
                            color: goalColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getGoalMessage(),
                          style: AppText.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroCard({
    required String title,
    required double current,
    required double target,
    required String unit,
    required IconData icon,
    required Color color,
    required double percentage,
  }) {
    final progress = (current / target).clamp(0.0, 1.5);
    final progressPercentage = (percentage.clamp(0, 100)).toInt();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: AppText.body.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  '$progressPercentage%',
                  style: AppText.bodySmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${current.toStringAsFixed(0)}$unit',
                    style: AppText.headline.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'consumed',
                    style: AppText.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${target.toStringAsFixed(0)}$unit',
                    style: AppText.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'daily goal',
                    style: AppText.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0$unit',
                style: AppText.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                progress > 1.0 ? 'Over target' : 'Progress',
                style: AppText.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${target.toStringAsFixed(0)}$unit',
                style: AppText.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMacroCard({
    required String title,
    required double current,
    required double target,
    required String unit,
    required Color color,
    required IconData icon,
  }) {
    final progress = (current / target).clamp(0.0, 1.0);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: AppText.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${current.toStringAsFixed(0)}$unit',
            style: AppText.titleSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            borderRadius: BorderRadius.circular(2),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: AppText.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '/${target.toStringAsFixed(0)}',
                style: AppText.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiberCard() {
    final fiberGoal = dailyGoals['Fiber'] ?? 30;
    final progress = (totalFiber / fiberGoal).clamp(0.0, 1.0);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.fiberColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.fiberColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.grass, color: AppColors.fiberColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FIBER',
                  style: AppText.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${totalFiber.toStringAsFixed(0)}g',
                      style: AppText.titleSmall.copyWith(
                        color: AppColors.fiberColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: AppColors.fiberColor.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.fiberColor),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '/${fiberGoal.toStringAsFixed(0)}g',
                      style: AppText.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getGoalColor() {
    switch (goal.toLowerCase()) {
      case 'weight loss':
        return AppColors.error; // Red color
      case 'muscle gain':
        return AppColors.primary; // Blue color
      case 'weight gain':
        return AppColors.warning; // Orange color
      default:
        return AppColors.primary;
    }
  }

  IconData _getGoalIcon() {
    switch (goal.toLowerCase()) {
      case 'weight loss':
        return Icons.trending_down;
      case 'muscle gain':
        return Icons.trending_up;
      case 'weight gain':
        return Icons.add_chart;
      default:
        return Icons.track_changes;
    }
  }

  String _getGoalMessage() {
    switch (goal.toLowerCase()) {
      case 'weight loss':
        return 'Focus on calorie deficit and high protein intake';
      case 'muscle gain':
        return 'Prioritize protein and calorie surplus';
      case 'weight gain':
        return 'Increase overall calories with healthy foods';
      default:
        return 'Maintain balanced macros for overall health';
    }
  }
}