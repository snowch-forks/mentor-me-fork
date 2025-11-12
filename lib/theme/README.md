# MentorMe Design System

This directory contains the centralized design system for the MentorMe app. Use these files instead of hardcoded values to ensure consistency across the app.

## Files

### `app_theme.dart`
Main theme configuration with Material 3 design. Provides both light and dark themes.

**Usage:**
```dart
// Already configured in main.dart
MaterialApp(
  theme: AppTheme.lightTheme(),
  darkTheme: AppTheme.darkTheme(),
  themeMode: ThemeMode.system,
)
```

### `app_spacing.dart`
Spacing constants for padding, margins, gaps, and border radius.

**Usage:**
```dart
import 'package:mentor_me/theme/app_spacing.dart';

// Padding
Container(
  padding: AppSpacing.paddingLg,  // EdgeInsets.all(16)
  child: Text('Hello'),
)

// Gaps between widgets
Column(
  children: [
    Text('Item 1'),
    AppSpacing.gapMd,  // SizedBox(height: 12)
    Text('Item 2'),
  ],
)

// Border radius
Container(
  decoration: BoxDecoration(
    borderRadius: AppRadius.radiusLg,  // BorderRadius.circular(12)
  ),
)

// Icon sizes
Icon(Icons.star, size: AppIconSize.lg),  // 28
```

**Available sizes:**
- `xs` (4) - Extra small
- `sm` (8) - Small
- `md` (12) - Medium
- `lg` (16) - Large (default for most cases)
- `xl` (24) - Extra large
- `xxl` (32) - Double extra large
- `xxxl` (48) - Triple extra large

### `app_colors.dart`
Semantic color definitions that complement Material 3's ColorScheme.

**Usage:**
```dart
import 'package:mentor_me/theme/app_colors.dart';

// Status colors
Container(
  color: AppColors.success,  // Green
  child: Text('Success!'),
)

// Mood chip
Container(
  decoration: BoxDecoration(
    color: AppColors.moodChipBackground,
    border: Border.all(color: AppColors.moodChipBorder),
  ),
  child: Text('😊 Happy', style: TextStyle(color: AppColors.moodChipText)),
)

// Blocker severity
Container(
  color: AppColors.blockerHigh,  // Red for high severity
)

// Progress colors
Color getProgressColor(double progress) {
  if (progress > 0.7) return AppColors.progressHigh;
  if (progress > 0.4) return AppColors.progressMedium;
  return AppColors.progressLow;
}
```

**Color extensions:**
```dart
// Lighten or darken a color
final lighterBlue = AppColors.seedColor.lighten(0.2);
final darkerBlue = AppColors.seedColor.darken(0.2);
```

### `app_text_styles.dart`
Custom text styles that extend Material 3's text theme.

**Usage:**
```dart
import 'package:mentor_me/theme/app_text_styles.dart';

// Emoji styles
Text('🎉', style: AppTextStyles.emojiLarge),  // fontSize: 24

// Labels (small, bold, uppercase)
Text('NEW', style: AppTextStyles.labelSmall),  // fontSize: 11, bold

// Body text
Text('This is body text', style: AppTextStyles.bodyMedium),  // fontSize: 14

// Headings
Text('Section Title', style: AppTextStyles.headingMedium),  // fontSize: 20, semibold

// Stats/numbers
Text('42', style: AppTextStyles.statNumber),  // Large, bold number

// Apply theme colors
Text(
  'Primary text',
  style: AppTextStyles.bodyMedium.primary(context),  // Uses theme primary color
)

Text(
  'Muted text',
  style: AppTextStyles.bodySmall.muted(context),  // 60% opacity
)
```

**Text style helpers:**
```dart
.primary(context)    // Apply primary color
.secondary(context)  // Apply secondary color
.error(context)      // Apply error color
.onSurface(context)  // Apply default text color
.muted(context)      // 60% opacity
.disabled(context)   // 38% opacity
.white()             // White color (for colored backgrounds)
.withOpacity(0.5)    // Custom opacity
```

## Migration Guide

### Before (Hardcoded):
```dart
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.pink.shade50,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.pink.shade200, width: 1),
  ),
  child: Row(
    children: [
      Text('😊', style: const TextStyle(fontSize: 18)),
      const SizedBox(width: 8),
      Text(
        'Happy',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.pink.shade900,
        ),
      ),
    ],
  ),
)
```

### After (Design System):
```dart
Container(
  padding: AppSpacing.paddingLg,
  decoration: BoxDecoration(
    color: AppColors.moodChipBackground,
    borderRadius: AppRadius.radiusLg,
    border: Border.all(color: AppColors.moodChipBorder, width: 1),
  ),
  child: Row(
    children: [
      Text('😊', style: AppTextStyles.emojiMedium),
      AppSpacing.gapHorizontalSm,
      Text(
        'Happy',
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColors.moodChipText,
        ),
      ),
    ],
  ),
)
```

## Best Practices

1. **Always use theme colors first:**
   ```dart
   // ✅ Good - Uses theme
   Theme.of(context).colorScheme.primary

   // ❌ Bad - Hardcoded
   Colors.deepPurple
   ```

2. **Use AppColors for semantic colors:**
   ```dart
   // ✅ Good - Semantic
   AppColors.success

   // ❌ Bad - Non-semantic
   Colors.green
   ```

3. **Use spacing constants:**
   ```dart
   // ✅ Good
   padding: AppSpacing.paddingLg

   // ❌ Bad
   padding: const EdgeInsets.all(16)
   ```

4. **Use text styles from theme or AppTextStyles:**
   ```dart
   // ✅ Good - Theme text style
   style: Theme.of(context).textTheme.bodyMedium

   // ✅ Good - Custom text style
   style: AppTextStyles.bodyMedium

   // ❌ Bad - Hardcoded
   style: TextStyle(fontSize: 14)
   ```

5. **Use border radius constants:**
   ```dart
   // ✅ Good
   borderRadius: AppRadius.radiusLg

   // ❌ Bad
   borderRadius: BorderRadius.circular(12)
   ```

## Common Patterns

### Card with padding
```dart
Card(
  child: Padding(
    padding: AppSpacing.cardPadding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Title', style: Theme.of(context).textTheme.titleLarge),
        AppSpacing.gapMd,
        Text('Body', style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  ),
)
```

### Status chip
```dart
Container(
  padding: const EdgeInsets.symmetric(
    horizontal: AppSpacing.md,
    vertical: AppSpacing.xs,
  ),
  decoration: BoxDecoration(
    color: AppColors.success.withOpacity(0.1),
    borderRadius: AppRadius.radiusLg,
    border: Border.all(color: AppColors.success),
  ),
  child: Text(
    'Active',
    style: AppTextStyles.labelSmall.copyWith(color: AppColors.success),
  ),
)
```

### Button
```dart
FilledButton.icon(
  onPressed: () {},
  icon: Icon(Icons.add, size: AppIconSize.sm),
  label: Text('Add Item', style: AppTextStyles.buttonMedium),
)
```

## Dark Mode

The app automatically supports dark mode! All theme-based colors will adapt:

```dart
// This automatically uses the correct color for light/dark mode
Container(
  color: Theme.of(context).colorScheme.surface,
  child: Text(
    'Adaptive text',
    style: Theme.of(context).textTheme.bodyMedium,
  ),
)
```

## Future Enhancements

- [ ] Animation duration constants
- [ ] Shadow/elevation presets
- [ ] Responsive breakpoints
- [ ] Gradient definitions
- [ ] Custom component themes
