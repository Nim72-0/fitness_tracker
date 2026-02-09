import 'package:flutter/material.dart';
import '../models/workout_model.dart';
import '../utils/theme.dart';

class WorkoutCard extends StatelessWidget {
  final Workout workout;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;
  final bool showFavorite;

  const WorkoutCard({
    super.key,
    required this.workout,
    required this.onTap,
    this.onFavoriteToggle,
    this.showFavorite = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Workout Image / Placeholder
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        color: _getCategoryColor(workout.category),
                        image: workout.imageUrl.isNotEmpty
                            ? DecorationImage(
                                image: AssetImage(workout.imageUrl),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  Colors.black.withAlpha(64),
                                  BlendMode.darken,
                                ),
                              )
                            : DecorationImage(
                                image: AssetImage('assets/workouts/strength/full_body_basics.png'),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  Colors.black.withAlpha(64),
                                  BlendMode.darken,
                                ),
                              ),
                      ),
                      child: workout.imageUrl.isEmpty
                          ? Center(
                              child: Icon(
                                _getCategoryIcon(workout.category),
                                size: 42,
                                color: AppColors.white,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),

                    // Main Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  workout.name,
                                  style: AppText.titleMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (showFavorite && onFavoriteToggle != null)
                                IconButton(
                                  icon: Icon(
                                    workout.isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    size: 22,
                                    color: workout.isFavorite
                                        ? AppColors.error
                                        : AppColors.textSecondary,
                                  ),
                                  onPressed: onFavoriteToggle,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${workout.category} • ${workout.level.capitalize()}',
                            style: AppText.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Stats
                          Row(
                            children: [
                              _buildStatItem(
                                icon: Icons.timer_outlined,
                                value: '${workout.duration}',
                                unit: 'min',
                              ),
                              const SizedBox(width: 20),
                              _buildStatItem(
                                icon: Icons.local_fire_department_outlined,
                                value: '${workout.caloriesBurned}',
                                unit: 'kcal',
                              ),
                            ],
                          ),

                          // Equipment tags
                          if (workout.equipment.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: workout.equipment.take(3).map((eq) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.workout.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                    ),
                                    child: Text(
                                      eq,
                                      style: AppText.label.copyWith(
                                        color: AppColors.workout,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Goal Badge
              if (workout.goal.isNotEmpty)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _getGoalColor(workout.goal),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      _getGoalAbbreviation(workout.goal),
                      style: AppText.labelSmall.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String unit,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          value,
          style: AppText.body.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          unit,
          style: AppText.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'cardio':
        return AppColors.error.withOpacity(0.9);
      case 'hiit':
        return AppColors.warning.withOpacity(0.9);
      case 'strength':
        return AppColors.primary.withOpacity(0.9);
      case 'yoga':
        return AppColors.prayer.withOpacity(0.9);
      case 'mixed':
        return AppColors.success.withOpacity(0.9);
      default:
        return AppColors.workout.withOpacity(0.9);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'cardio':
        return Icons.directions_run;
      case 'hiit':
        return Icons.flash_on;
      case 'strength':
        return Icons.fitness_center;
      case 'yoga':
        return Icons.self_improvement;
      default:
        return Icons.fitness_center;
    }
  }

  Color _getGoalColor(String goal) {
    switch (goal) {
      case 'Weight Loss':
        return AppColors.success;
      case 'Muscle Gain':
        return AppColors.primary;
      case 'Weight Gain':
        return AppColors.warning;
      case 'Maintenance':
        return AppColors.prayer;
      default:
        return AppColors.workout;
    }
  }

  String _getGoalAbbreviation(String goal) {
    switch (goal) {
      case 'Weight Loss':
        return 'WL';
      case 'Muscle Gain':
        return 'MG';
      case 'Weight Gain':
        return 'WG';
      case 'Maintenance':
        return 'MT';
      default:
        return goal.substring(0, 2).toUpperCase();
    }
  }
}

// Small extension for capitalize
extension StringExtension on String {
  String capitalize() {
    return isEmpty ? this : this[0].toUpperCase() + substring(1).toLowerCase();
  }
}