import 'package:flutter/material.dart';

/// Custom text styles that extend Material 3's text theme.
///
/// This is a comprehensive design system library providing consistent typography
/// across the app. While not all styles are currently in use, they are intentionally
/// defined to ensure design consistency as the app grows.
///
/// For usage examples, see theme/README.md
class AppTextStyles {
  AppTextStyles._(); // Private constructor

  // Font weights
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  // Emoji styles (larger than normal text)
  static const TextStyle emojiSmall = TextStyle(fontSize: 16);
  static const TextStyle emojiMedium = TextStyle(fontSize: 20);
  static const TextStyle emojiLarge = TextStyle(fontSize: 24);
  static const TextStyle emojiXLarge = TextStyle(fontSize: 32);
  static const TextStyle emojiHero = TextStyle(fontSize: 48);

  // Label styles (small, uppercase, bold labels)
  static const TextStyle labelTiny = TextStyle(
    fontSize: 10,
    fontWeight: bold,
    letterSpacing: 0.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: medium,
    letterSpacing: 0.5,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: medium,
    letterSpacing: 0.5,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: medium,
    letterSpacing: 0.3,
  );

  // Caption styles (for metadata, timestamps, etc.)
  static const TextStyle captionTiny = TextStyle(
    fontSize: 10,
    fontWeight: regular,
  );

  static const TextStyle captionSmall = TextStyle(
    fontSize: 11,
    fontWeight: regular,
  );

  static const TextStyle captionMedium = TextStyle(
    fontSize: 12,
    fontWeight: regular,
  );

  // Body text styles
  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: regular,
    height: 1.4,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: regular,
    height: 1.5,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: regular,
    height: 1.5,
  );

  // Emphasized body text
  static const TextStyle bodySmallBold = TextStyle(
    fontSize: 13,
    fontWeight: bold,
  );

  static const TextStyle bodyMediumBold = TextStyle(
    fontSize: 14,
    fontWeight: bold,
  );

  static const TextStyle bodyLargeBold = TextStyle(
    fontSize: 16,
    fontWeight: bold,
  );

  // Heading styles
  static const TextStyle headingSmall = TextStyle(
    fontSize: 18,
    fontWeight: semiBold,
    height: 1.3,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 20,
    fontWeight: semiBold,
    height: 1.3,
  );

  static const TextStyle headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: bold,
    height: 1.2,
  );

  static const TextStyle headingXLarge = TextStyle(
    fontSize: 28,
    fontWeight: bold,
    height: 1.2,
  );

  // Display styles (for hero text)
  static const TextStyle displaySmall = TextStyle(
    fontSize: 32,
    fontWeight: bold,
    height: 1.1,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 40,
    fontWeight: bold,
    height: 1.1,
  );

  static const TextStyle displayLarge = TextStyle(
    fontSize: 48,
    fontWeight: bold,
    height: 1.0,
  );

  // Button text styles
  static const TextStyle buttonSmall = TextStyle(
    fontSize: 12,
    fontWeight: medium,
    letterSpacing: 0.5,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontSize: 14,
    fontWeight: medium,
    letterSpacing: 0.5,
  );

  static const TextStyle buttonLarge = TextStyle(
    fontSize: 16,
    fontWeight: medium,
    letterSpacing: 0.5,
  );

  // Monospace (for code, debug logs, etc.)
  static const TextStyle monospace = TextStyle(
    fontFamily: 'monospace',
    fontSize: 12,
  );

  static const TextStyle monospaceSmall = TextStyle(
    fontFamily: 'monospace',
    fontSize: 10,
  );

  // Stats/numbers (for metrics, progress, etc.)
  static const TextStyle statNumber = TextStyle(
    fontSize: 32,
    fontWeight: bold,
    letterSpacing: -0.5,
  );

  static const TextStyle statLabel = TextStyle(
    fontSize: 11,
    fontWeight: medium,
    letterSpacing: 0.5,
  );
}

/// Helper methods for applying theme colors to text styles
extension TextStyleHelpers on TextStyle {
  /// Apply primary color from theme
  TextStyle primary(BuildContext context) {
    return copyWith(color: Theme.of(context).colorScheme.primary);
  }

  /// Apply secondary color from theme
  TextStyle secondary(BuildContext context) {
    return copyWith(color: Theme.of(context).colorScheme.secondary);
  }

  /// Apply error color from theme
  TextStyle error(BuildContext context) {
    return copyWith(color: Theme.of(context).colorScheme.error);
  }

  /// Apply on-surface color (default text color)
  TextStyle onSurface(BuildContext context) {
    return copyWith(color: Theme.of(context).colorScheme.onSurface);
  }

  /// Apply muted text color (lower contrast)
  TextStyle muted(BuildContext context) {
    return copyWith(
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
    );
  }

  /// Apply disabled text color
  TextStyle disabled(BuildContext context) {
    return copyWith(
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
    );
  }

  /// Apply white color (use on colored backgrounds)
  TextStyle white() {
    return copyWith(color: Colors.white);
  }

  /// Apply custom opacity
  TextStyle withOpacity(double opacity) {
    return copyWith(color: color?.withOpacity(opacity));
  }
}
