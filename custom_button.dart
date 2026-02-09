// lib/widgets/custom_button.dart
import 'package:flutter/material.dart';
import '../utils/theme.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutline;
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double fontSize;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutline = false,
    this.width = double.infinity,
    this.height = 50,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isOutline ? Colors.transparent : AppColors.primary;
    final foregroundColor = isOutline ? AppColors.primary : AppColors.white;
    final borderColor = isOutline ? AppColors.primary : Colors.transparent;

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: BorderSide(
              color: borderColor,
              width: isOutline ? 2 : 0,
            ),
          ),
          elevation: isOutline ? 0 : 2,
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foregroundColor,
                ),
              )
            : Text(
                label,
                style: AppText.button.copyWith(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: foregroundColor,
                ),
              ),
      ),
    );
  }
}