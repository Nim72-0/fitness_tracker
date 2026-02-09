// lib/utils/platform_utils.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class PlatformUtils {
  // ===== Basic Checks =====
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isIOS => !kIsWeb && Platform.isIOS;
  static bool get isWeb => kIsWeb;
  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  // ===== Platform Name =====
  static String get platformName {
    if (kIsWeb) return 'Web';
    if (!kIsWeb) {
      if (Platform.isAndroid) return 'Android';
      if (Platform.isIOS) return 'iOS';
    }
    return 'Unknown';
  }

  // ===== Example: Platform-specific padding or sizes =====
  static double get defaultPadding {
    if (isWeb) return 24;
    return 16;
  }

  static double get defaultFontSize {
    if (isWeb) return 18;
    return 16;
  }
}
