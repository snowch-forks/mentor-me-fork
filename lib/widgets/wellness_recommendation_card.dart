// lib/widgets/wellness_recommendation_card.dart
// "What are you struggling with?" card for the home page
// Shows wellness tool recommendations based on user's current struggle

import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import 'wellness_recommendation_dialog.dart';

/// A card widget that provides quick access to wellness tool recommendations
/// Shows on the home screen and can be arranged with other dashboard widgets
class WellnessRecommendationCard extends StatelessWidget {
  const WellnessRecommendationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => WellnessRecommendationDialog.show(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.spa,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Wellness Tools',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Main question
              Text(
                'What are you struggling with?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              // Description
              Text(
                'Get personalized tool recommendations based on how you\'re feeling',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Quick preview icons of struggle types
              Row(
                children: [
                  _buildStruggleIcon('😰', colorScheme),
                  const SizedBox(width: AppSpacing.xs),
                  _buildStruggleIcon('💭', colorScheme),
                  const SizedBox(width: AppSpacing.xs),
                  _buildStruggleIcon('🌊', colorScheme),
                  const SizedBox(width: AppSpacing.xs),
                  _buildStruggleIcon('😔', colorScheme),
                  const SizedBox(width: AppSpacing.xs),
                  _buildStruggleIcon('🔥', colorScheme),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '+3 more',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStruggleIcon(String emoji, ColorScheme colorScheme) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surfaceContainerHighest,
      ),
      child: Center(
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
