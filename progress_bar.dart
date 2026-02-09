// Enhanced ProgressBar with percentage display
class EnhancedProgressBar extends StatelessWidget {
  final double value;
  final String label;
  final bool showPercentage;
  final Color? backgroundColor;
  final Color? progressColor;
  final double height;

  const EnhancedProgressBar({
    super.key,
    required this.value,
    this.label = '',
    this.showPercentage = true,
    this.backgroundColor,
    this.progressColor,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    final progress = value.clamp(0.0, 1.0);
    final percentage = (progress * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty || showPercentage)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (label.isNotEmpty)
                  Text(
                    label,
                    style: AppText.body.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (showPercentage)
                  Text(
                    '$percentage%',
                    style: AppText.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: height,
            backgroundColor: backgroundColor ?? AppColors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(
              progressColor ?? AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}