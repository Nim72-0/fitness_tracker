import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/workout_model.dart';
import '../models/exercise_model.dart';
import '../providers/workouts_provider.dart';
import '../utils/theme.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final Workout workout;

  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WorkoutsProvider>(context);
    
    final liveWorkout = provider.generatedPlan.firstWhere(
      (w) => w.id == widget.workout.id, 
      orElse: () => widget.workout
    );

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.workout,
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                liveWorkout.name,
                style: AppText.headlineSmall.copyWith(
                  color: AppColors.white,
                  shadows: const [Shadow(blurRadius: 10, color: Colors.black)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    liveWorkout.imageUrl.isNotEmpty ? liveWorkout.imageUrl : 'assets/workouts/strength/pushups.png',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8)
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsRow(liveWorkout),
                  const SizedBox(height: 24),
                  Text(
                    'Exercises',
                    style: AppText.headlineSmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap an exercise to view details or swap it.',
                    style: AppText.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: liveWorkout.exercises.length,
                    itemBuilder: (context, index) {
                      final ex = liveWorkout.exercises[index];
                      return _buildExerciseTile(context, provider, liveWorkout, ex, index);
                    },
                  ),
                  
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () => _startWorkout(context, provider, liveWorkout),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.workout,
                      foregroundColor: AppColors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: Text(
                      'MARK AS DONE',
                      style: AppText.button,
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatsRow(Workout w) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _statBadge(Icons.timer, '${w.duration} min'),
        _statBadge(Icons.local_fire_department, '${w.caloriesBurned} cal'),
        _statBadge(Icons.bar_chart, w.level.toUpperCase()),
      ],
    );
  }

  Widget _statBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppTheme.smallShadow,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.workout),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppText.label.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseTile(BuildContext context, WorkoutsProvider provider, Workout workout, Exercise exercise, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => _showExerciseDetails(context, provider, workout, exercise),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Image.asset(
                  exercise.imageUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    width: 70,
                    height: 70,
                    color: AppColors.surfaceVariant,
                    child: Icon(Icons.image, color: AppColors.textMuted),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: AppText.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${exercise.steps.length} steps • ${exercise.targetMuscleGroups.join(", ")}',
                      style: AppText.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.swap_horiz, color: AppColors.primary),
                onPressed: () => _showSwapDialog(context, provider, workout, exercise),
                tooltip: 'Replace Exercise',
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showExerciseDetails(BuildContext context, WorkoutsProvider provider, Workout workout, Exercise exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl))
          ),
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: controller,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  color: AppColors.border,
                ),
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Image.asset(
                  exercise.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    height: 200,
                    color: AppColors.surfaceVariant,
                    child: Center(
                      child: Icon(Icons.image, color: AppColors.textMuted, size: 60),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                exercise.name,
                style: AppText.headlineSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                exercise.description,
                style: AppText.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Steps',
                style: AppText.title.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              ...exercise.steps.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${e.key + 1}. ',
                      style: AppText.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        e.value,
                        style: AppText.body.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 20),
              Text(
                'Safety Tips',
                style: AppText.title.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              ...exercise.safetyTips.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.health_and_safety, size: 16, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e,
                        style: AppText.body.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _showSwapDialog(BuildContext context, WorkoutsProvider provider, Workout workout, Exercise current) {
    final options = provider.getReplacementOptions(current);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Swap Exercise',
          style: AppText.title.copyWith(color: AppColors.textPrimary),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: options.isEmpty 
              ? Text(
                  "No suitable replacements found.",
                  style: AppText.body.copyWith(color: AppColors.textSecondary),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (ctx, i) {
                    final opt = options[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: Image.asset(
                            opt.imageUrl,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              width: 40,
                              height: 40,
                              color: AppColors.surface,
                              child: Icon(Icons.image, color: AppColors.textMuted),
                            ),
                          ),
                        ),
                        title: Text(
                          opt.name,
                          style: AppText.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          opt.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.caption.copyWith(color: AppColors.textSecondary),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
                        onTap: () {
                          provider.replaceExerciseInWorkout(workout, current.id, opt);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Exercise swapped! Plan updated.',
                                style: AppText.body.copyWith(color: AppColors.white),
                              ),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppText.button.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  void _startWorkout(BuildContext context, WorkoutsProvider provider, Workout workout) {
    provider.logWorkoutSession(workout: workout, duration: workout.duration);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Workout Completed! Great Job!',
          style: AppText.body.copyWith(color: AppColors.white),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
    Navigator.pop(context);
  }
}