import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/workouts_provider.dart';
import '../utils/theme.dart';
import '../models/workout_model.dart';

class WorkoutStatsScreen extends StatefulWidget {
  const WorkoutStatsScreen({super.key});

  @override
  State<WorkoutStatsScreen> createState() => _WorkoutStatsScreenState();
}

class _WorkoutStatsScreenState extends State<WorkoutStatsScreen> {
  bool _isLoading = true;
  String _selectedTimeframe = 'week';
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _weeklyData = [];
  String? _uid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStats();
    });
  }

  Future<void> _loadStats() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final workoutsProvider = Provider.of<WorkoutsProvider>(context, listen: false);
      _uid = workoutsProvider.uid;

      if (_uid != null && _uid!.isNotEmpty) {
        final history = await workoutsProvider.getWorkoutHistory(_uid!);

        if (mounted) {
          _calculateStats(history);
          _calculateWeeklyData(history);
        }
      }
    } catch (e, stack) {
      debugPrint('Error loading workout stats: $e');
      debugPrint(stack.toString());
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _calculateStats(List<WorkoutSession> history) {
    if (history.isEmpty) {
      _stats = {
        'weekCalories': 0,
        'monthCalories': 0,
        'totalCalories': 0,
        'weekMinutes': 0,
        'monthMinutes': 0,
        'totalMinutes': 0,
        'weekWorkouts': 0,
        'monthWorkouts': 0,
        'totalWorkouts': 0,
        'mostFrequentWorkout': 'None',
        'avgCaloriesPerWorkout': 0,
        'avgMinutesPerWorkout': 0,
      };
      return;
    }

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final monthAgo = now.subtract(const Duration(days: 30));

    int weekCalories = 0;
    int monthCalories = 0;
    int totalCalories = 0;
    int weekMinutes = 0;
    int monthMinutes = 0;
    int totalMinutes = 0;
    int weekWorkouts = 0;
    int monthWorkouts = 0;
    final int totalWorkouts = history.length;

    final Map<String, int> workoutFrequency = {};

    for (var session in history) {
      final calories = session.caloriesBurned ?? 0;
      final minutes = session.duration ?? 0;
      final workoutName = session.workout.name ?? 'Unknown';

      workoutFrequency.update(
        workoutName,
        (value) => value + 1,
        ifAbsent: () => 1,
      );

      totalCalories += calories;
      totalMinutes += minutes;

      if (session.completedAt.isAfter(weekAgo)) {
        weekCalories += calories;
        weekMinutes += minutes;
        weekWorkouts++;
      }

      if (session.completedAt.isAfter(monthAgo)) {
        monthCalories += calories;
        monthMinutes += minutes;
        monthWorkouts++;
      }
    }

    String mostFrequentWorkout = 'None';
    if (workoutFrequency.isNotEmpty) {
      final entry = workoutFrequency.entries.reduce((a, b) => a.value > b.value ? a : b);
      mostFrequentWorkout = entry.key;
    }

    _stats = {
      'weekCalories': weekCalories,
      'monthCalories': monthCalories,
      'totalCalories': totalCalories,
      'weekMinutes': weekMinutes,
      'monthMinutes': monthMinutes,
      'totalMinutes': totalMinutes,
      'weekWorkouts': weekWorkouts,
      'monthWorkouts': monthWorkouts,
      'totalWorkouts': totalWorkouts,
      'mostFrequentWorkout': mostFrequentWorkout,
      'avgCaloriesPerWorkout': totalWorkouts > 0 ? totalCalories ~/ totalWorkouts : 0,
      'avgMinutesPerWorkout': totalWorkouts > 0 ? totalMinutes ~/ totalWorkouts : 0,
    };
  }

  void _calculateWeeklyData(List<WorkoutSession> history) {
    final now = DateTime.now();
    final List<Map<String, dynamic>> weeklyData = [];

    for (int i = 0; i < 4; i++) {
      final endDate = now.subtract(Duration(days: i * 7));
      final startDate = endDate.subtract(const Duration(days: 7));

      int weekCalories = 0;
      int weekMinutes = 0;
      int weekWorkouts = 0;

      for (var session in history) {
        if (session.completedAt.isAfter(startDate) &&
            session.completedAt.isBefore(endDate)) {
          weekCalories += session.caloriesBurned ?? 0;
          weekMinutes += session.duration ?? 0;
          weekWorkouts++;
        }
      }

      weeklyData.add({
        'label': 'Week ${4 - i}',
        'calories': weekCalories,
        'minutes': weekMinutes,
        'workouts': weekWorkouts,
      });
    }

    _weeklyData = weeklyData.reversed.toList();
  }

  Widget _buildTimeframeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'week', label: Text('Week')),
          ButtonSegment(value: 'month', label: Text('Month')),
          ButtonSegment(value: 'all', label: Text('All Time')),
        ],
        selected: {_selectedTimeframe},
        onSelectionChanged: (newSelection) {
          setState(() {
            _selectedTimeframe = newSelection.first;
          });
        },
        style: SegmentedButton.styleFrom(
          backgroundColor: AppColors.surfaceVariant,
          foregroundColor: AppColors.textSecondary,
          selectedBackgroundColor: AppColors.workout,
          selectedForegroundColor: AppColors.white,
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int value, String unit, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.workout.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, color: AppColors.workout, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppText.label.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$value $unit',
                        style: AppText.headlineSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainStats() {
    final calories = _selectedTimeframe == 'week'
        ? _stats['weekCalories'] ?? 0
        : _selectedTimeframe == 'month'
            ? _stats['monthCalories'] ?? 0
            : _stats['totalCalories'] ?? 0;

    final minutes = _selectedTimeframe == 'week'
        ? _stats['weekMinutes'] ?? 0
        : _selectedTimeframe == 'month'
            ? _stats['monthMinutes'] ?? 0
            : _stats['totalMinutes'] ?? 0;

    final workouts = _selectedTimeframe == 'week'
        ? _stats['weekWorkouts'] ?? 0
        : _selectedTimeframe == 'month'
            ? _stats['monthWorkouts'] ?? 0
            : _stats['totalWorkouts'] ?? 0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.35,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _buildStatCard('Calories', calories, 'kcal', Icons.local_fire_department),
        _buildStatCard('Time', minutes, 'min', Icons.timer),
        _buildStatCard('Workouts', workouts, '', Icons.fitness_center),
        _buildStatCard('Avg. Cal', _stats['avgCaloriesPerWorkout'] ?? 0, 'kcal', Icons.trending_up),
      ],
    );
  }

  Widget _buildWeeklyProgress() {
    if (_weeklyData.isEmpty) return const SizedBox.shrink();

    final maxCalories = _weeklyData
        .map((d) => d['calories'] as int)
        .fold(0, (max, v) => v > max ? v : max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            'Last 4 Weeks',
            style: AppText.headlineSmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _weeklyData.length,
            itemBuilder: (context, index) {
              final data = _weeklyData[index];
              final height = maxCalories > 0 ? (data['calories'] / maxCalories) * 160 : 8.0;

              return SizedBox(
                width: 90,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${data['calories']}',
                      style: AppText.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: height,
                      width: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.workout,
                            AppColors.workout.withOpacity(0.5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data['label'],
                      style: AppText.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${data['workouts']} sess',
                      style: AppText.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAchievements() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Highlights',
            style: AppText.headlineSmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildAchievementItem(
            'Most Frequent',
            _stats['mostFrequentWorkout'] ?? 'None',
            Icons.emoji_events,
          ),
          const SizedBox(height: 12),
          _buildAchievementItem(
            'Avg Duration',
            '${_stats['avgMinutesPerWorkout'] ?? 0} min',
            Icons.timer_outlined,
          ),
          const SizedBox(height: 12),
          _buildAchievementItem(
            'Total Sessions',
            '${_stats['totalWorkouts'] ?? 0}',
            Icons.fitness_center,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementItem(String title, String value, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppTheme.smallShadow,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.workout.withOpacity(0.1),
          child: Icon(icon, color: AppColors.workout),
        ),
        title: Text(
          title,
          style: AppText.labelLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          value,
          style: AppText.titleMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
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
              Icons.bar_chart_outlined,
              size: 90,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 24),
            Text(
              "No workout data yet",
              style: AppText.headlineMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Complete your first workout to start tracking progress!",
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: Icon(Icons.fitness_center, color: AppColors.white),
              label: Text(
                "Start Training",
                style: AppText.button,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.workout,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          'Workout Progress',
          style: AppText.headlineMedium.copyWith(color: AppColors.textPrimary),
        ),
        backgroundColor: AppTheme.appBarBackground,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: _loadStats,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _stats.isEmpty && !_isLoading
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadStats,
                  color: AppColors.workout,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        _buildTimeframeSelector(),
                        _buildMainStats(),
                        _buildWeeklyProgress(),
                        _buildAchievements(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
    );
  }
}