import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/steps_provider.dart';
import '../providers/profile_provider.dart';
import '../utils/theme.dart';

class StepsScreen extends StatefulWidget {
  const StepsScreen({super.key});

  @override
  State<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends State<StepsScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initData());
  }

  Future<void> _initData() async {
    final stepsProvider = context.read<StepsProvider>();
    final profileProvider = context.read<ProfileProvider>();
    
    if (profileProvider.user != null) {
      stepsProvider.setUserId(profileProvider.user!.uid);
      stepsProvider.setGoalBasedOnUserType(profileProvider.user!.goal);
    }

    await stepsProvider.fetchTodaySteps();
    await stepsProvider.fetchHistory();
    
    setState(() => _isLoading = false);
  }

  void _showGoalDialog(BuildContext context, StepsProvider provider) {
    final controller = TextEditingController(text: provider.goal.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Set Daily Goal',
          style: AppText.title.copyWith(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: AppText.body.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Steps Goal',
            suffixText: 'steps',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppText.button.copyWith(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val > 0) {
                provider.updateGoal(val);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text(
              'Save',
              style: AppText.button.copyWith(color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StepsProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: AppTheme.scaffoldBackground,
          appBar: AppBar(
            backgroundColor: AppTheme.appBarBackground,
            elevation: 0,
            title: Text(
              'Steps Tracker',
              style: AppText.headlineMedium.copyWith(color: AppColors.textPrimary),
            ),
            centerTitle: false,
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: AppColors.textSecondary),
                onPressed: () {
                  provider.fetchTodaySteps();
                  provider.fetchHistory();
                },
              )
            ],
          ),
          body: _isLoading 
              ? Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ) 
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildCircularProgress(provider),
                      const SizedBox(height: 24),
                      _buildStatsGrid(provider),
                      const SizedBox(height: 24),
                      Text(
                        "Weekly Progress",
                        style: AppText.headlineSmall.copyWith(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 16),
                      _buildWeeklyChart(provider),
                      const SizedBox(height: 24),
                      _buildGoalCard(provider),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildCircularProgress(StepsProvider provider) {
    final double size = 220;
    final double strokeWidth = 20;
    final double progress = provider.todaySteps.progress;
    
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: strokeWidth,
              color: AppColors.stepsColorLight,
            ),
          ),
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: strokeWidth,
              color: AppColors.stepsColor,
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.directions_walk,
                size: 40,
                color: AppColors.stepsColor,
              ),
              const SizedBox(height: 8),
              Text(
                NumberFormat.decimalPattern().format(provider.steps),
                style: AppText.displayMedium.copyWith(
                  color: AppColors.textPrimary,
                  height: 1,
                  fontSize: 48,
                ),
              ),
              Text(
                '/ ${NumberFormat.compact().format(provider.goal)} steps',
                style: AppText.body.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(StepsProvider provider) {
    final calories = (provider.steps * 0.04).toStringAsFixed(0);
    final distance = (provider.steps * 0.000762).toStringAsFixed(2);
    final time = (provider.steps / 100).ceil().toString();

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            Icons.local_fire_department,
            calories,
            'kcal',
            AppColors.calories,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            Icons.place,
            distance,
            'km',
            AppColors.hydrationColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            Icons.timer,
            time,
            'min',
            AppColors.workout,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
            unit,
            style: AppText.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(StepsProvider provider) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppColors.border),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (provider.goal * 1.5).toDouble(),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.surface,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value.toInt() >= 0 && value.toInt() < provider.history.length) {
                    final date = provider.history[value.toInt()].date;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat('E').format(date).substring(0, 1),
                        style: AppText.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          barGroups: List.generate(provider.history.length, (index) {
            final item = provider.history.reversed.toList()[index];
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: item.steps.toDouble(),
                  color: item.steps >= item.goal ? AppColors.success : AppColors.stepsColor,
                  width: 14,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: (provider.goal * 1.2),
                    color: AppColors.stepsColorLight.withOpacity(0.5),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildGoalCard(StepsProvider provider) {
    return GestureDetector(
      onTap: () => _showGoalDialog(context, provider),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.stepsColor,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Goal',
                  style: AppText.titleSmall.copyWith(color: AppColors.white.withOpacity(0.9)),
                ),
                const SizedBox(height: 4),
                Text(
                  '${NumberFormat.decimalPattern().format(provider.goal)} steps',
                  style: AppText.headlineMedium.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            Icon(Icons.edit, color: AppColors.white),
          ],
        ),
      ),
    );
  }
}