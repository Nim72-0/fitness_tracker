import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout_model.dart';
import '../providers/workouts_provider.dart';
import '../providers/profile_provider.dart';
import '../utils/theme.dart';
import 'workout_detail_screen.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initData());
  }

  Future<void> _initData() async {
    final profile = Provider.of<ProfileProvider>(context, listen: false);
    final workouts = Provider.of<WorkoutsProvider>(context, listen: false);
    
    await workouts.setUserId(profile.uid);
    
    if (workouts.generatedPlan.isEmpty && profile.user != null) {
      workouts.generatePlan(
        goal: profile.user!.goal, 
        level: profile.user!.level,
        includeYoga: true
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final workoutsProvider = Provider.of<WorkoutsProvider>(context);
    final profile = Provider.of<ProfileProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarBackground,
        elevation: 0,
        title: Text(
          'Workouts',
          style: AppText.headlineMedium.copyWith(color: AppColors.textPrimary),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.textPrimary,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: AppText.titleSmall.copyWith(fontWeight: FontWeight.w800),
          unselectedLabelStyle: AppText.body,
          tabs: const [
            Tab(text: 'For You'),
            Tab(text: 'Yoga & Recovery'),
            Tab(text: 'History'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: () => _initData(),
          )
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildForYouTab(workoutsProvider, profile),
          _buildYogaTab(workoutsProvider),
          _buildHistoryTab(workoutsProvider),
        ],
      ),
    );
  }

  Widget _buildForYouTab(WorkoutsProvider provider, ProfileProvider profile) {
    if (provider.isLoading) return Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  top: -20,
                  child: Icon(
                    Icons.fitness_center,
                    color: AppColors.white.withOpacity(0.1),
                    size: 120,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Fitness Journey',
                      style: AppText.body.copyWith(
                        color: AppColors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Goal: ${profile.user?.goal ?? "Fitness"}',
                      style: AppText.headlineMedium.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _infoChip(Icons.trending_up, profile.user?.level ?? "Beginner"),
                        const SizedBox(width: 10),
                        _infoChip(Icons.calendar_today, 'Week 1'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
           
          const SizedBox(height: 24),
          Text(
            'Your Weekly Split',
            style: AppText.headlineSmall.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
           
          if (provider.generatedPlan.isEmpty)
            Center(
              child: Text(
                "No plan generated yet.",
                style: AppText.body.copyWith(color: AppColors.textSecondary),
              ),
            )
          else
            ...provider.generatedPlan.where((w) => w.category != 'YOGA').map((w) => _buildWorkoutCard(w)),
              
          const SizedBox(height: 24),
          Text(
            'Quick Access',
            style: AppText.headlineSmall.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildYogaTab(WorkoutsProvider provider) {
    final yogaWorkouts = provider.generatedPlan.where((w) => w.category == 'YOGA').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Recovery & Mind',
          style: AppText.headlineMedium.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          'Yoga is essential for flexibility and injury prevention, regardless of your goal.',
          style: AppText.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        if (yogaWorkouts.isEmpty)
          Center(
            child: Text(
              'No Yoga sessions scheduled.',
              style: AppText.body.copyWith(color: AppColors.textSecondary),
            ),
          )
        else
          ...yogaWorkouts.map((w) => _buildWorkoutCard(w, isYoga: true)),
      ],
    );
  }

  Widget _buildHistoryTab(WorkoutsProvider provider) {
    if (provider.stats.isEmpty) return Center(
      child: Text(
        "No history yet",
        style: AppText.body.copyWith(color: AppColors.textSecondary),
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatCard(
                'Workouts',
                '${provider.stats['totalWorkouts'] ?? 0}',
                Icons.check_circle_outline,
                AppColors.primary,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Calories',
                '${provider.stats['totalCalories'] ?? 0}',
                Icons.local_fire_department,
                AppColors.calories,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Minutes',
                '${provider.stats['totalMinutes'] ?? 0}',
                Icons.timer,
                AppColors.workout,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Recent Sessions',
            style: AppText.headlineSmall.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          ...provider.workoutHistory.take(10).map((s) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppTheme.cardShadow,
              border: Border.all(color: AppColors.border),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              title: Text(
                s.workout.name,
                style: AppText.titleSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                '${s.duration} min • ${s.caloriesBurned} kcal',
                style: AppText.caption.copyWith(color: AppColors.textSecondary),
              ),
              trailing: Text(
                "${s.completedAt.day}/${s.completedAt.month}",
                style: AppText.caption.copyWith(color: AppColors.textMuted),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppTheme.cardShadow,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppText.headlineSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: AppText.caption.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutCard(Workout workout, {bool isYoga = false}) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => WorkoutDetailScreen(workout: workout)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          image: DecorationImage(
            image: workout.imageUrl.isNotEmpty 
                ? AssetImage(workout.imageUrl) 
                : AssetImage('assets/workouts/strength/full_body_basics.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.4),
              BlendMode.darken,
            ),
          ),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isYoga ? AppColors.prayer : AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  workout.splitType.toUpperCase(),
                  style: AppText.labelSmall.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                workout.name,
                style: AppText.headlineSmall.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.timer, color: AppColors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${workout.duration} min',
                    style: AppText.caption.copyWith(color: AppColors.white),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.local_fire_department, color: AppColors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${workout.caloriesBurned} kcal',
                    style: AppText.caption.copyWith(color: AppColors.white),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppText.labelSmall.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}