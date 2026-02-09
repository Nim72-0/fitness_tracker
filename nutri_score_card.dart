import 'package:flutter/material.dart';
import '../utils/theme.dart';

class NutriScoreCard extends StatelessWidget {
  final int score;
  final String goal;
  final Color color;

  const NutriScoreCard({
    super.key,
    required this.score,
    required this.goal,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    Color scoreColor;
    String scoreText;
    
    if (score >= 80) {
      scoreColor = AppColors.success;
      scoreText = 'Excellent!';
    } else if (score >= 60) {
      scoreColor = AppColors.info;
      scoreText = 'Good';
    } else if (score >= 40) {
      scoreColor = AppColors.warning;
      scoreText = 'Fair';
    } else {
      scoreColor = AppColors.error;
      scoreText = 'Needs Improvement';
    }

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NutriScore',
                      style: AppText.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      scoreText,
                      style: AppText.headlineMedium.copyWith(
                        color: scoreColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: score / 100,
                        strokeWidth: 8,
                        backgroundColor: color.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                      ),
                    ),
                    Text(
                      '$score',
                      style: AppText.displayMedium.copyWith(
                        color: scoreColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: LinearProgressIndicator(
                value: score / 100,
                minHeight: 8,
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '0',
                  style: AppText.caption.copyWith(color: AppColors.textMuted),
                ),
                Text(
                  'Nutrition Quality',
                  style: AppText.caption.copyWith(color: AppColors.textSecondary),
                ),
                Text(
                  '100',
                  style: AppText.caption.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}