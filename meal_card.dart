import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/nutrition_model.dart';
import '../utils/theme.dart';

class MealCard extends StatelessWidget {
  final NutritionModel meal;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final Color goalColor;

  const MealCard({
    super.key,
    required this.meal,
    required this.onDelete,
    required this.onEdit,
    required this.goalColor,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(meal.id ?? UniqueKey().toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: AppColors.white, size: 30),
      ),
      onDismissed: (direction) => onDelete(),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
          boxShadow: AppTheme.smallShadow,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: meal.imageUrl != null && meal.imageUrl!.isNotEmpty
              ? CircleAvatar(
                  backgroundColor: goalColor.withOpacity(0.1),
                  radius: 22,
                  backgroundImage: meal.imageUrl!.startsWith('http')
                      ? NetworkImage(meal.imageUrl!) as ImageProvider
                      : AssetImage(meal.imageUrl!),
                )
              : CircleAvatar(
                  backgroundColor: goalColor.withOpacity(0.1),
                  radius: 22,
                  child: Icon(Icons.restaurant, color: goalColor, size: 20),
                ),
          title: Text(
            meal.name,
            style: AppText.titleSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                '${meal.calories.toStringAsFixed(0)} kcal',
                style: AppText.label.copyWith(
                  color: goalColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _buildMacroChip('P', '${meal.protein}g', AppColors.proteinColor),
                  const SizedBox(width: 6),
                  _buildMacroChip('C', '${meal.carbs}g', AppColors.carbColor),
                  const SizedBox(width: 6),
                  _buildMacroChip('F', '${meal.fat}g', AppColors.fatColor),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('h:mm a').format(meal.timestamp),
                style: AppText.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          trailing: IconButton(
            icon: Icon(Icons.edit, size: 20, color: AppColors.primary),
            onPressed: onEdit,
          ),
        ),
      ),
    );
  }

  Widget _buildMacroChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label:',
            style: AppText.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            value,
            style: AppText.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}