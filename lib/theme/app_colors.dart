import 'package:flutter/material.dart';

/// Semantic color definitions for the app
/// These complement Material 3's ColorScheme but provide app-specific colors
/// that don't fit into the standard scheme
class AppColors {
  AppColors._(); // Private constructor

  // Seed color for Material 3 theme generation
  static const Color seedColor = Colors.deepPurple;

  // Status colors (semantic)
  static const Color success = Color(0xFF4CAF50); // Green
  static const Color warning = Color(0xFFFF9800); // Orange
  static const Color error = Color(0xFFF44336); // Red
  static const Color info = Color(0xFF2196F3); // Blue

  // Mood colors (for journal entries)
  static const Color moodAmazing = Color(0xFF4CAF50); // Green
  static const Color moodGood = Color(0xFF8BC34A); // Light green
  static const Color moodOkay = Color(0xFFFFEB3B); // Yellow
  static const Color moodBad = Color(0xFFFF9800); // Orange
  static const Color moodAwful = Color(0xFFF44336); // Red

  // Mood chip styling
  static const Color moodChipBackground = Color(0xFFFCE4EC); // Pink 50
  static const Color moodChipBorder = Color(0xFFF8BBD0); // Pink 200
  static const Color moodChipText = Color(0xFF880E4F); // Pink 900

  // Energy chip styling
  static const Color energyChipBackground = Color(0xFFFFF8E1); // Amber 50
  static const Color energyChipBorder = Color(0xFFFFE082); // Amber 200
  static const Color energyChipText = Color(0xFFFF6F00); // Amber 900

  // Blocker severity colors
  static const Color blockerLow = Color(0xFF2196F3); // Blue
  static const Color blockerMedium = Color(0xFFFF9800); // Orange
  static const Color blockerHigh = Color(0xFFF44336); // Red

  // Blocker status colors
  static const Color blockerDetected = Color(0xFFF44336); // Red
  static const Color blockerAcknowledged = Color(0xFFFF9800); // Orange
  static const Color blockerWorkingOn = Color(0xFF2196F3); // Blue
  static const Color blockerResolved = Color(0xFF4CAF50); // Green
  static const Color blockerDismissed = Color(0xFF9E9E9E); // Grey

  // Habit/Goal progress colors
  static const Color progressHigh = Color(0xFF4CAF50); // Green (>70%)
  static const Color progressMedium = Color(0xFFFF9800); // Orange (40-70%)
  static const Color progressLow = Color(0xFFF44336); // Red (<40%)

  // Category colors (for goals)
  static const Color categoryCareer = Color(0xFF2196F3); // Blue
  static const Color categoryHealth = Color(0xFF4CAF50); // Green
  static const Color categoryRelationships = Color(0xFFE91E63); // Pink
  static const Color categoryPersonal = Color(0xFF9C27B0); // Purple
  static const Color categoryFinancial = Color(0xFF4CAF50); // Green
  static const Color categoryLearning = Color(0xFFFF9800); // Orange
  static const Color categoryOther = Color(0xFF757575); // Grey

  // Streak colors
  static const Color streakFire = Color(0xFFFF9800); // Orange for fire emoji
  static const Color streakBackground = Color(0xFFFFF8E1); // Light orange background

  // Notification colors
  static const Color notificationBackground = Color(0xFFE3F2FD); // Light blue
  static const Color notificationBorder = Color(0xFF90CAF9); // Blue 200

  // Chart colors (for analytics/insights)
  static const List<Color> chartColors = [
    Color(0xFF2196F3), // Blue
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFFE91E63), // Pink
    Color(0xFF9C27B0), // Purple
    Color(0xFF00BCD4), // Cyan
    Color(0xFFFFEB3B), // Yellow
    Color(0xFFF44336), // Red
  ];

  // Overlay colors
  static const Color scrim = Color(0x80000000); // 50% black
  static const Color dimOverlay = Color(0x40000000); // 25% black

  // Border colors
  static const Color borderLight = Color(0xFFE0E0E0); // Grey 300
  static const Color borderMedium = Color(0xFFBDBDBD); // Grey 400
  static const Color borderDark = Color(0xFF757575); // Grey 600

  // Background variations (light theme)
  static const Color backgroundLight = Color(0xFFFAFAFA); // Grey 50
  static const Color surfaceLight = Color(0xFFFFFFFF); // White
  static const Color surfaceVariantLight = Color(0xFFF5F5F5); // Grey 100

  // Text colors (use sparingly - prefer theme colors)
  static const Color textPrimary = Color(0xFF212121); // Grey 900
  static const Color textSecondary = Color(0xFF757575); // Grey 600
  static const Color textDisabled = Color(0xFFBDBDBD); // Grey 400
  static const Color textWhite = Color(0xFFFFFFFF); // White
}

/// Extensions for working with colors
extension ColorExtensions on Color {
  /// Returns a lighter version of the color
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// Returns a darker version of the color
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// Returns the color with the specified opacity
  Color withAlpha(int alpha) {
    return Color.fromARGB(alpha, red, green, blue);
  }
}
