import 'package:flutter/widgets.dart';

/// Centralized spacing constants for consistent padding, margins, and gaps
/// throughout the app. Use these instead of magic numbers.
class AppSpacing {
  AppSpacing._(); // Private constructor to prevent instantiation

  // Base spacing units
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;

  // Common EdgeInsets patterns
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);
  static const EdgeInsets paddingXxl = EdgeInsets.all(xxl);

  // Horizontal padding
  static const EdgeInsets paddingHorizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets paddingHorizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingHorizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets paddingHorizontalXl = EdgeInsets.symmetric(horizontal: xl);

  // Vertical padding
  static const EdgeInsets paddingVerticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets paddingVerticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets paddingVerticalLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets paddingVerticalXl = EdgeInsets.symmetric(vertical: xl);

  // Common SizedBox gaps
  static const SizedBox gapXs = SizedBox(width: xs, height: xs);
  static const SizedBox gapSm = SizedBox(width: sm, height: sm);
  static const SizedBox gapMd = SizedBox(width: md, height: md);
  static const SizedBox gapLg = SizedBox(width: lg, height: lg);
  static const SizedBox gapXl = SizedBox(width: xl, height: xl);
  static const SizedBox gapXxl = SizedBox(width: xxl, height: xxl);

  // Horizontal gaps
  static const SizedBox gapHorizontalXs = SizedBox(width: xs);
  static const SizedBox gapHorizontalSm = SizedBox(width: sm);
  static const SizedBox gapHorizontalMd = SizedBox(width: md);
  static const SizedBox gapHorizontalLg = SizedBox(width: lg);
  static const SizedBox gapHorizontalXl = SizedBox(width: xl);

  // Vertical gaps
  static const SizedBox gapVerticalXs = SizedBox(height: xs);
  static const SizedBox gapVerticalSm = SizedBox(height: sm);
  static const SizedBox gapVerticalMd = SizedBox(height: md);
  static const SizedBox gapVerticalLg = SizedBox(height: lg);
  static const SizedBox gapVerticalXl = SizedBox(height: xl);

  // Screen padding (for ListView, etc.)
  static const EdgeInsets screenPadding = EdgeInsets.all(lg);
  static const EdgeInsets screenPaddingHorizontal = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets screenPaddingVertical = EdgeInsets.symmetric(vertical: lg);

  // Card padding
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(xl);

  // Button padding
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: xl, vertical: md);
  static const EdgeInsets buttonPaddingLarge = EdgeInsets.all(lg);

  // Dialog padding
  static const EdgeInsets dialogPadding = EdgeInsets.all(xl);
}

/// Border radius constants for consistent rounded corners
class AppRadius {
  AppRadius._(); // Private constructor

  static const double xs = 4.0;
  static const double sm = 6.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double xxl = 24.0;

  // Common BorderRadius patterns
  static final BorderRadius radiusXs = BorderRadius.circular(xs);
  static final BorderRadius radiusSm = BorderRadius.circular(sm);
  static final BorderRadius radiusMd = BorderRadius.circular(md);
  static final BorderRadius radiusLg = BorderRadius.circular(lg);
  static final BorderRadius radiusXl = BorderRadius.circular(xl);
  static final BorderRadius radiusXxl = BorderRadius.circular(xxl);

  // Circular (for avatars, etc.)
  static const BorderRadius circular = BorderRadius.all(Radius.circular(999));
}

/// Icon size constants
class AppIconSize {
  AppIconSize._(); // Private constructor

  static const double xs = 16.0;
  static const double sm = 20.0;
  static const double md = 24.0; // Default Flutter icon size
  static const double lg = 28.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double hero = 64.0;
}
