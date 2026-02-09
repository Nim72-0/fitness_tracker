import 'package:flutter/material.dart';

/// =========================
/// DESIGN TOKENS
/// =========================
class AppColors {
  static const primary = Color(0xFF2563EB);
  static const secondary = Color(0xFF8B5CF6);

  static const white = Colors.white;
  static const black = Color(0xFF0F172A);

  // Background & Surface
  static const background = Color(0xFFF8FAFC);
  static const surface = Colors.white;
  static const surfaceVariant = Color(0xFFF1F5F9);
  static const onSurface = Color(0xFF111827);
  static const onSurfaceVariant = Color(0xFF374151);
  
  // Card specific
  static const cardBackground = Colors.white;

  // Text colors - Darker for better contrast
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF374151);
  static const textMuted = Color(0xFF6B7280);
  static const onBackground = Color(0xFF111827);

  // Border colors
  static const border = Color(0xFFE5E7EB);
  
  // Status colors
  static const error = Color(0xFFEF4444);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF3B82F6);

  // Feature specific colors
  static const stepsColor = Color(0xFF059669);
  static const stepsColorLight = Color(0xFFD1FAE5);
  static const hydrationColor = Color(0xFF0EA5E9);
  static const hydrationColorLight = Color(0xFFE0F2FE);
  static const calories = Color(0xFFEF4444);
  static const caloriesLight = Color(0xFFFEE2E2);
  
  // Nutrition / Macro Colors
  static const protein = Color(0xFFEF4444);
  static const proteinColor = Color(0xFFEF4444);
  static const carbs = Color(0xFF3B82F6);
  static const carbColor = Color(0xFF3B82F6);
  static const fat = Color(0xFFF59E0B);
  static const fatColor = Color(0xFFF59E0B);
  static const fiber = Color(0xFF10B981);
  static const fiberColor = Color(0xFF10B981);
  
  // ✅ ADDED: Nutrition colors for compatibility
  static const nutrition = Color(0xFFF59E0B);
  static const nutritionColor = Color(0xFFF59E0B);
  
  // Other feature colors
  static const prayer = Color(0xFF8B5CF6);
  static const workout = Color(0xFF7C3AED);
  
  // ✅ ADDED: For hydration screen compatibility
  static const progressStart = Color(0xFFD1FAE5);
  static const screenBg = Color(0xFFF8FAFC);
  static const borderGrey = Color(0xFFE5E7EB);
  static const progressBg = Color(0xFFF1F5F9);
}

/// =========================
/// RADIUS & SHADOWS
/// =========================
class AppRadius {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
}

class AppShadows {
  static const small = [
    BoxShadow(
      color: Colors.black12,
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];
  
  static const card = [
    BoxShadow(
      color: Colors.black12,
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];
  
  static const elevated = [
    BoxShadow(
      color: Colors.black26,
      blurRadius: 12,
      offset: Offset(0, 6),
    ),
  ];
}

/// =========================
/// TEXT STYLES - BOLDER VERSION
/// =========================
class AppText {
  // Display styles
  static const TextStyle displayLarge = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.0,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle displayMedium = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );
  
  // Headline styles
  static const TextStyle headline = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );
  
  // Title styles
  static const TextStyle title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  
  // Body styles
  static const TextStyle body = TextStyle(
    fontSize: 14,
    height: 1.6,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    height: 1.6,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
  
  // Label styles
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );
  
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  
  // Button styles
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
  );
  
  // Caption styles
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
  
  // Section headers
  static const TextStyle section = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );
}

/// =========================
/// FEATURE COLORS
/// =========================
enum Feature { steps, hydration, nutrition, workout, calories }

class FeatureColors {
  static Color light(Feature feature) {
    switch (feature) {
      case Feature.steps:
        return AppColors.stepsColorLight;
      case Feature.hydration:
        return AppColors.hydrationColorLight;
      case Feature.nutrition:
        return const Color(0xFFFFF7D6);
      case Feature.workout:
        return const Color(0xFFEDE9FF);
      case Feature.calories:
        return AppColors.caloriesLight;
      default:
        return AppColors.primary.withOpacity(0.1);
    }
  }

  static Color dark(Feature feature) {
    switch (feature) {
      case Feature.steps:
        return AppColors.stepsColor;
      case Feature.hydration:
        return AppColors.hydrationColor;
      case Feature.nutrition:
        return AppColors.nutritionColor; // ✅ Now using AppColors.nutritionColor
      case Feature.workout:
        return AppColors.workout;
      case Feature.calories:
        return AppColors.calories;
      default:
        return AppColors.primary;
    }
  }
}

/// =========================
/// APP THEME - ONLY LIGHT THEME
/// =========================
class AppTheme {
  // Basic Colors
  static const scaffoldBackground = AppColors.background;
  static const primaryColor = AppColors.primary;
  static const cardBackground = AppColors.cardBackground;
  
  // Feature specific colors
  static final Color workoutColor = FeatureColors.dark(Feature.workout);
  static final Color nutritionColor = FeatureColors.dark(Feature.nutrition);
  
  static const successColor = AppColors.success;
  static const errorColor = AppColors.error;
  
  // Feature specific colors
  static const stepsColor = AppColors.stepsColor;
  static const stepsColorLight = AppColors.stepsColorLight;
  static const hydrationColor = AppColors.hydrationColor;
  static const caloriesColor = AppColors.calories;
  
  // Text colors
  static const textPrimary = AppColors.textPrimary;
  static const textSecondary = AppColors.textSecondary;
  static const textLight = AppColors.textMuted;
  static const textDark = AppColors.black;
  static const subTextColor = AppColors.textSecondary;
  
  // Card & Surface
  static const cardBg = AppColors.surface;
  static const appBarBackground = AppColors.surface;
  static const divider = AppColors.border;
  
  // Radius & Shadows
  static const radiusMedium = AppRadius.md;
  static const radiusLarge = AppRadius.lg;
  static const cardShadow = AppShadows.card;
  static const smallShadow = AppShadows.small;
  
  // Gradient
  static const primaryGradient = LinearGradient(
    colors: [AppColors.primary, AppColors.secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text Styles (for backward compatibility)
  static const TextStyle titleLarge = AppText.headlineMedium;
  static const TextStyle titleMedium = AppText.titleMedium;
  static const TextStyle bodyMedium = AppText.body;
  static const TextStyle bodyLarge = AppText.bodyLarge;
  static const TextStyle bodySmall = AppText.bodySmall;
  static const TextStyle headlineMedium = AppText.headlineMedium;
  static const TextStyle displayMedium = AppText.displayMedium;
  static const TextStyle labelLarge = AppText.labelLarge;
  static const TextStyle caption = AppText.caption;
  static const TextStyle button = AppText.button;
  static const TextStyle headline = AppText.headline;
  static const TextStyle headlineSmall = AppText.headlineSmall;
  static const TextStyle titleSmall = AppText.titleSmall;
  static const TextStyle displayLarge = AppText.displayLarge;

  /// =========================
  /// ONLY LIGHT THEME - FIXED VERSION
  /// =========================
  static ThemeData get lightTheme {
    return ThemeData.light().copyWith(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        background: AppColors.background,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      // FIXED: Use CardThemeData instead of CardTheme
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.white,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: AppText.displayLarge,
        displayMedium: AppText.displayMedium,
        headlineMedium: AppText.headlineMedium,
        headlineSmall: AppText.headlineSmall,
        titleLarge: AppText.headlineMedium,
        titleMedium: AppText.titleMedium,
        titleSmall: AppText.titleSmall,
        bodyLarge: AppText.bodyLarge,
        bodyMedium: AppText.body,
        bodySmall: AppText.bodySmall,
        labelLarge: AppText.labelLarge,
        labelMedium: AppText.label,
        labelSmall: AppText.labelSmall,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        elevation: 2,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
      ),
    );
  }

  /// =========================
  /// SIMPLE GETTER FOR HOME SCREEN
  /// =========================
  static ThemeData get theme => lightTheme;
}