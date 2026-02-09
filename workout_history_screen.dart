import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/workouts_provider.dart';
import '../models/workout_model.dart';
import '../utils/theme.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  bool _isLoading = true;
  List<WorkoutSession> _workoutHistory = [];
  String? _uid;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      setState(() => _isLoading = true);
      
      final workoutsProvider = context.read<WorkoutsProvider>();
      _uid = workoutsProvider.uid;
      
      if (_uid != null) {
        _workoutHistory = await workoutsProvider.getWorkoutHistory(_uid!);
        _workoutHistory.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading workout history: $e');
      setState(() => _isLoading = false);
    }
  }

  Widget _buildStatsHeader() {
    if (_workoutHistory.isEmpty) return Container();

    final totalWorkouts = _workoutHistory.length;
    final totalMinutes = _workoutHistory.fold(0, (sum, session) => sum + session.duration);
    final totalCalories = _workoutHistory.fold(0, (sum, session) => sum + session.caloriesBurned);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.workout,
            AppColors.workout.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.fitness_center,
            value: '$totalWorkouts',
            label: 'Workouts',
          ),
          _buildStatItem(
            icon: Icons.timer,
            value: '$totalMinutes',
            label: 'Minutes',
          ),
          _buildStatItem(
            icon: Icons.local_fire_department,
            value: '$totalCalories',
            label: 'Calories',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, size: 28, color: AppColors.white),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppText.headlineSmall.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppText.caption.copyWith(
            color: AppColors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center_outlined,
              size: 80,
              color: AppColors.textMuted.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            Text(
              'No Workouts Yet',
              style: AppText.headlineMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Complete your first workout to see it here!',
              style: AppText.body.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.workout,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: Text(
                'Start Workout',
                style: AppText.button,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    final Map<String, List<WorkoutSession>> groupedSessions = {};

    for (var session in _workoutHistory) {
      final date = DateFormat('yyyy-MM-dd').format(session.completedAt);
      if (!groupedSessions.containsKey(date)) {
        groupedSessions[date] = [];
      }
      groupedSessions[date]!.add(session);
    }

    final sortedDates = groupedSessions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final sessions = groupedSessions[date]!;
        final dateTime = DateTime.parse(date);
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));

        String dateLabel;
        if (dateTime.year == today.year &&
            dateTime.month == today.month &&
            dateTime.day == today.day) {
          dateLabel = 'Today';
        } else if (dateTime.year == yesterday.year &&
            dateTime.month == yesterday.month &&
            dateTime.day == yesterday.day) {
          dateLabel = 'Yesterday';
        } else {
          dateLabel = DateFormat('MMM dd, yyyy').format(dateTime);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text(
                dateLabel,
                style: AppText.headlineSmall.copyWith(
                  color: AppColors.workout,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ...sessions.map((session) => _buildHistoryCard(session)),
          ],
        );
      },
    );
  }

  Widget _buildHistoryCard(WorkoutSession session) {
    final workout = session.workout;
    final time = DateFormat('hh:mm a').format(session.completedAt);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () {
            // Add navigation to workout details here if needed
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.workout.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    _getWorkoutIcon(workout.category),
                    size: 30,
                    color: AppColors.workout,
                  ),
                ),
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout.name,
                        style: AppText.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${workout.category} • ${workout.level}',
                        style: AppText.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.timer, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${workout.duration} min',
                            style: AppText.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.local_fire_department, size: 14, color: AppColors.calories),
                          const SizedBox(width: 4),
                          Text(
                            '${workout.caloriesBurned} cal',
                            style: AppText.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      time,
                      style: AppText.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      Icons.check_circle,
                      size: 20,
                      color: AppColors.success,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getWorkoutIcon(String category) {
    switch (category.toLowerCase()) {
      case 'cardio':
        return Icons.directions_run;
      case 'hiit':
        return Icons.flash_on;
      case 'strength':
        return Icons.fitness_center;
      case 'yoga':
        return Icons.self_improvement;
      case 'mixed':
        return Icons.directions_bike;
      default:
        return Icons.fitness_center;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          'Workout History',
          style: AppText.headlineMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: AppTheme.appBarBackground,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: _loadHistory,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.workout,
              ),
            )
          : _workoutHistory.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: AppColors.workout,
                  onRefresh: _loadHistory,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsHeader(),
                        const SizedBox(height: 16),
                        _buildHistoryList(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }
}