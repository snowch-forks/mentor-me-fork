import 'package:flutter/material.dart';
import 'package:mentor_me/models/cognitive_distortion.dart';
import 'package:mentor_me/services/cognitive_distortion_detector.dart';
import 'package:mentor_me/theme/app_spacing.dart';

/// Interactive dialog for Socratic questioning and thought reframing
///
/// Guides users through CBT-based Socratic questioning to help them
/// challenge and reframe cognitive distortions. Returns an alternative
/// thought if the user completes the process.
class SocraticQuestioningDialog extends StatefulWidget {
  final DetectionResult detection;
  final String originalText;

  const SocraticQuestioningDialog({
    super.key,
    required this.detection,
    required this.originalText,
  });

  /// Show the dialog and return the alternative thought if completed
  static Future<String?> show({
    required BuildContext context,
    required DetectionResult detection,
    required String originalText,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SocraticQuestioningDialog(
        detection: detection,
        originalText: originalText,
      ),
    );
  }

  @override
  State<SocraticQuestioningDialog> createState() =>
      _SocraticQuestioningDialogState();
}

class _SocraticQuestioningDialogState
    extends State<SocraticQuestioningDialog> {
  int _currentStep = 0;
  final _responseController = TextEditingController();
  final _alternativeThoughtController = TextEditingController();
  final List<String> _responses = [];

  @override
  void dispose() {
    _responseController.dispose();
    _alternativeThoughtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                Text(
                  widget.detection.type.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Let\'s Explore This Thought',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Progress indicator
            LinearProgressIndicator(
              value: (_currentStep + 1) / 3,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),

            const SizedBox(height: 8),

            Text(
              'Step ${_currentStep + 1} of 3',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),

            const SizedBox(height: 24),

            // Step content
            if (_currentStep == 0) _buildStep1(),
            if (_currentStep == 1) _buildStep2(),
            if (_currentStep == 2) _buildStep3(),

            const SizedBox(height: 20),

            // Navigation buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _currentStep--;
                        _responseController.clear();
                      });
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                  )
                else
                  const SizedBox.shrink(),
                FilledButton(
                  onPressed: _handleNext,
                  child: Text(_currentStep == 2 ? 'Save Reframe' : 'Continue'),
                ),
              ],
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Distortion type card
        Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .errorContainer
                .withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Original Thought',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '"${widget.detection.suggestedText}"',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .onErrorContainer
                        .withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'This shows ${widget.detection.type.displayName.toLowerCase()}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onErrorContainer
                                .withValues(alpha: 0.8),
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Challenge question
        Text(
          'Let\'s Examine This',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 12),

        Text(
          widget.detection.type.challengeQuestion,
          style: Theme.of(context).textTheme.bodyLarge,
        ),

        const SizedBox(height: 16),

        // Response input
        TextField(
          controller: _responseController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Take your time to reflect...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Great Reflection!',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 12),

        Text(
          'Your response helped you see another perspective. '
          'Now let\'s think about evidence.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),

        const SizedBox(height: 16),

        // Additional challenge question based on distortion type
        Text(
          _getStep2Question(),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),

        const SizedBox(height: 16),

        TextField(
          controller: _responseController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'What comes to mind?',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create a Balanced Thought',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 12),

        Text(
          'Based on your reflections, what would be a more balanced, '
          'realistic way to think about this situation?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),

        const SizedBox(height: 16),

        // Show previous responses for context
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '💡 Your insights:',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
              const SizedBox(height: 6),
              for (int i = 0; i < _responses.length; i++)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '• ${_responses[i]}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer
                              .withValues(alpha: 0.8),
                        ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Alternative thought input
        TextField(
          controller: _alternativeThoughtController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Write your balanced thought here...',
            helperText:
                'Example: "I\'m struggling right now, but I\'ve overcome challenges before"',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }

  String _getStep2Question() {
    switch (widget.detection.type) {
      case DistortionType.allOrNothingThinking:
        return 'What are some examples that don\'t fit the "all or nothing" pattern?';
      case DistortionType.overgeneralization:
        return 'Can you think of times when this wasn\'t true?';
      case DistortionType.mentalFilter:
        return 'What positive aspects might you be filtering out?';
      case DistortionType.discountingThePositive:
        return 'Why might those positive things actually count?';
      case DistortionType.jumpingToConclusions:
        return 'What other explanations could there be?';
      case DistortionType.magnification:
        return 'How might you view this in a year from now?';
      case DistortionType.emotionalReasoning:
        return 'What are the actual facts, separate from your feelings?';
      case DistortionType.shouldStatements:
        return 'What would be a more compassionate expectation?';
      case DistortionType.labeling:
        return 'Can you describe the specific behavior without the label?';
      case DistortionType.personalization:
        return 'What factors outside your control may have contributed?';
    }
  }

  void _handleNext() {
    if (_currentStep < 2) {
      // Save response and move to next step
      if (_responseController.text.trim().isNotEmpty) {
        setState(() {
          _responses.add(_responseController.text.trim());
          _currentStep++;
          _responseController.clear();
        });
      } else {
        // Show validation message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please write a response before continuing'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Final step - return alternative thought
      final alternativeThought = _alternativeThoughtController.text.trim();
      if (alternativeThought.isNotEmpty) {
        Navigator.of(context).pop(alternativeThought);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please write your balanced thought'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
