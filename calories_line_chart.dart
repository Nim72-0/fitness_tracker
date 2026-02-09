// lib/widgets/calories_line_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../utils/theme.dart';

class CaloriesLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const CaloriesLineChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return _buildEmptyState();

    final displayData = data.length > 7 ? data.sublist(data.length - 7) : data;

    final maxCalories = displayData
        .map((d) => (d['calories'] as num?)?.toDouble() ?? 0)
        .reduce((a, b) => a > b ? a : b);
    final maxGoal = displayData
        .map((d) => (d['goal'] as num?)?.toDouble() ?? 2000)
        .reduce((a, b) => a > b ? a : b);
    final maxY = (maxCalories > maxGoal ? maxCalories : maxGoal) * 1.15;
    final minY = 0.0;

    final List<String> dayLabels = displayData.map((d) {
      final dateStr = d['date']?.toString() ?? '';
      if (dateStr.contains('/')) return dateStr;
      final index = displayData.indexOf(d);
      final daysAgo = displayData.length - 1 - index;
      final date = DateTime.now().subtract(Duration(days: daysAgo));
      return '${date.day}/${date.month.toString().padLeft(2, '0')}';
    }).toList();

    return Container(
      height: 280,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Calories Progress",
                style: AppText.headlineSmall.copyWith(color: AppColors.textPrimary),
              ),
              Row(
                children: [
                  _buildLegendItem(AppColors.calories, "Consumed"),
                  const SizedBox(width: 16),
                  _buildLegendItem(AppColors.warning, "Goal"),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Last ${displayData.length} days",
            style: AppText.caption.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 5,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: value == 0 ? AppColors.border : AppColors.surfaceVariant,
                    strokeWidth: value == 0 ? 1.5 : 1,
                    dashArray: value == 0 ? null : [5, 5],
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= dayLabels.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            dayLabels[index],
                            style: AppText.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      interval: maxY / 5,
                      getTitlesWidget: (value, meta) {
                        if (value == 0 || value % 500 != 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '${value.toInt()}',
                            style: AppText.caption.copyWith(color: AppColors.textSecondary),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      displayData.length,
                      (i) => FlSpot(i.toDouble(), (displayData[i]['goal'] ?? 2000).toDouble()),
                    ),
                    isCurved: false,
                    barWidth: 2,
                    color: AppColors.warning,
                    dotData: const FlDotData(show: false),
                    dashArray: const [6, 4],
                  ),
                  LineChartBarData(
                    spots: List.generate(
                      displayData.length,
                      (i) => FlSpot(i.toDouble(), (displayData[i]['calories'] ?? 0).toDouble()),
                    ),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    barWidth: 3,
                    color: AppColors.calories,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: AppColors.calories,
                          strokeWidth: 3,
                          strokeColor: AppColors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.calories.withOpacity(0.35),
                          AppColors.calories.withOpacity(0.08),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    tooltipBorder: BorderSide(color: AppColors.border, width: 0.8),
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        if (index < 0 || index >= displayData.length) return null;

                        final cal = spot.y.toInt();
                        final goal = (displayData[index]['goal'] ?? 2000).toInt();
                        final diff = cal - goal;

                        final statusText = diff > 100
                            ? 'Above goal'
                            : diff < -100
                                ? 'Below goal'
                                : 'On target';

                        final statusColor = diff > 100
                            ? AppColors.error
                            : diff < -100
                                ? AppColors.success
                                : AppColors.primary;

                        return LineTooltipItem(
                          '$cal cal\nGoal: $goal\n$statusText',
                          AppText.caption.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          children: [
                            TextSpan(
                              text: ' ${diff > 0 ? '+' : ''}$diff',
                              style: AppText.caption.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        );
                      }).whereType<LineTooltipItem>().toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    "Tap points to see details",
                    style: AppText.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart_rounded,
              size: 70,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              "No calorie data yet",
              style: AppText.titleMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Track your meals to see progress",
              style: AppText.caption.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppText.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}