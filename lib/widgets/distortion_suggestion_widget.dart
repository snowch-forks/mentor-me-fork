import 'package:flutter/material.dart';
import 'package:mentor_me/models/cognitive_distortion.dart';
import 'package:mentor_me/services/cognitive_distortion_detector.dart';
import 'package:mentor_me/theme/app_spacing.dart';

/// Gentle inline prompt that suggests exploring detected cognitive distortions
///
/// Appears below text input when a distortion is detected, offering the user
/// the option to explore and reframe their thought using Socratic questioning.
class DistortionSuggestionWidget extends StatelessWidget {
  final DetectionResult detection;
  final VoidCallback onExplore;
  final VoidCallback onDismiss;

  const DistortionSuggestionWidget({
    super.key,
    required this.detection,
    required this.onExplore,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.tertiary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with emoji and distortion type
          Row(
            children: [
              Text(
                detection.type.emoji,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'I noticed some ${detection.type.displayName.toLowerCase()} here',
                  style: textTheme.titleSmall?.copyWith(
                    color: colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Close button
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: colorScheme.onTertiaryContainer.withValues(alpha: 0.6),
                onPressed: onDismiss,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Short description of the distortion
          Text(
            detection.type.shortDescription,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onTertiaryContainer.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 12),

          // Action prompt
          Text(
            'Would you like to explore this thought together?',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onTertiaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 12),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Dismiss button
              TextButton(
                onPressed: onDismiss,
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.onTertiaryContainer
                      .withValues(alpha: 0.7),
                ),
                child: const Text('No, keep writing'),
              ),
              const SizedBox(width: 8),

              // Explore button (primary action)
              FilledButton.tonal(
                onPressed: onExplore,
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.tertiary,
                  foregroundColor: colorScheme.onTertiary,
                ),
                child: const Text('Yes, help me reframe'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Controller for managing distortion suggestion state
///
/// Handles detection triggers, dismissals, and timing to avoid
/// overwhelming the user with too many suggestions.
class DistortionSuggestionController extends ChangeNotifier {
  DetectionResult? _currentDetection;
  DateTime? _lastSuggestionTime;
  final Set<DistortionType> _dismissedInSession = {};

  /// Minimum time between suggestions (seconds)
  static const int minTimeBetweenSuggestions = 30;

  DetectionResult? get currentDetection => _currentDetection;
  bool get hasSuggestion => _currentDetection != null;

  /// Show a new distortion suggestion
  ///
  /// Will be ignored if:
  /// - A suggestion is already showing
  /// - This distortion type was recently dismissed
  /// - Last suggestion was too recent (rate limiting)
  void showSuggestion(DetectionResult detection) {
    // Don't show if already showing a suggestion
    if (_currentDetection != null) return;

    // Don't show if this type was dismissed in this session
    if (_dismissedInSession.contains(detection.type)) return;

    // Rate limiting - don't show too frequently
    if (_lastSuggestionTime != null) {
      final timeSince = DateTime.now().difference(_lastSuggestionTime!);
      if (timeSince.inSeconds < minTimeBetweenSuggestions) return;
    }

    _currentDetection = detection;
    _lastSuggestionTime = DateTime.now();
    notifyListeners();
  }

  /// Dismiss the current suggestion
  ///
  /// Optionally remember the dismissal to avoid showing the same
  /// distortion type again in this session.
  void dismiss({bool rememberDismissal = true}) {
    if (_currentDetection != null && rememberDismissal) {
      _dismissedInSession.add(_currentDetection!.type);
    }
    _currentDetection = null;
    notifyListeners();
  }

  /// Clear the current suggestion (e.g., user clicked "explore")
  void clear() {
    _currentDetection = null;
    notifyListeners();
  }

  /// Reset the controller (e.g., new journal entry started)
  void reset() {
    _currentDetection = null;
    _lastSuggestionTime = null;
    _dismissedInSession.clear();
    notifyListeners();
  }
}
