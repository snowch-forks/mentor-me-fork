// lib/services/experiment_analysis_service.dart
// Statistical analysis service for N-of-1 experiments

import 'dart:math';
import '../models/experiment.dart';
import '../models/experiment_entry.dart';
import 'debug_service.dart';

/// Service for analyzing experiment data and generating statistical results.
///
/// Implements basic statistical analysis suitable for N-of-1 personal experiments:
/// - Descriptive statistics (mean, standard deviation)
/// - Effect size calculation (Cohen's d)
/// - Confidence estimation based on data quality
/// - User-friendly interpretation of results
class ExperimentAnalysisService {
  final DebugService _debug = DebugService();

  /// Analyze an experiment and generate results.
  ///
  /// Requires entries from both baseline and intervention phases.
  /// Returns null if insufficient data for analysis.
  Future<ExperimentResults?> analyzeExperiment({
    required Experiment experiment,
    required List<ExperimentEntry> entries,
  }) async {
    try {
      // Separate entries by phase
      final baselineEntries = entries
          .where((e) => e.phase == ExperimentPhase.baseline && e.outcomeValue != null)
          .toList();
      final interventionEntries = entries
          .where((e) => e.phase == ExperimentPhase.intervention && e.outcomeValue != null)
          .toList();

      // Check minimum data requirements
      if (baselineEntries.length < experiment.minimumDataPoints ||
          interventionEntries.length < experiment.minimumDataPoints) {
        await _debug.warning(
          'ExperimentAnalysisService',
          'Insufficient data for analysis',
          metadata: {
            'experimentId': experiment.id,
            'baselineCount': baselineEntries.length,
            'interventionCount': interventionEntries.length,
            'minimumRequired': experiment.minimumDataPoints,
          },
        );
        return null;
      }

      // Extract outcome values
      final baselineValues = baselineEntries
          .map((e) => e.outcomeValue!.toDouble())
          .toList();
      final interventionValues = interventionEntries
          .map((e) => e.outcomeValue!.toDouble())
          .toList();

      // Calculate descriptive statistics
      final baselineMean = _calculateMean(baselineValues);
      final baselineStdDev = _calculateStdDev(baselineValues, baselineMean);
      final interventionMean = _calculateMean(interventionValues);
      final interventionStdDev = _calculateStdDev(interventionValues, interventionMean);

      // Calculate effect size (Cohen's d)
      final effectSize = _calculateCohenD(
        baselineMean,
        baselineStdDev,
        interventionMean,
        interventionStdDev,
        baselineValues.length,
        interventionValues.length,
      );

      // Calculate percent change
      final percentChange = baselineMean != 0
          ? ((interventionMean - baselineMean) / baselineMean) * 100
          : 0.0;

      // Determine direction
      final direction = _determineDirection(effectSize, percentChange);

      // Estimate confidence level
      final confidenceLevel = _estimateConfidence(
        baselineValues.length,
        interventionValues.length,
        baselineStdDev,
        interventionStdDev,
        entries,
      );

      // Determine significance level
      final significance = _determineSignificance(effectSize.abs(), confidenceLevel);

      // Generate interpretation
      final summaryStatement = _generateSummary(
        experiment,
        direction,
        effectSize,
        percentChange,
        significance,
      );

      // Generate caveats
      final caveats = _generateCaveats(
        baselineValues.length,
        interventionValues.length,
        baselineStdDev,
        interventionStdDev,
        entries,
        experiment,
      );

      // Generate suggestions
      final suggestions = _generateSuggestions(
        experiment,
        direction,
        significance,
        entries,
      );

      final results = ExperimentResults(
        experimentId: experiment.id,
        baselineMean: baselineMean,
        baselineStdDev: baselineStdDev,
        baselineN: baselineValues.length,
        interventionMean: interventionMean,
        interventionStdDev: interventionStdDev,
        interventionN: interventionValues.length,
        effectSize: effectSize,
        percentChange: percentChange,
        direction: direction,
        confidenceLevel: confidenceLevel,
        significance: significance,
        summaryStatement: summaryStatement,
        caveats: caveats,
        suggestions: suggestions,
      );

      await _debug.info(
        'ExperimentAnalysisService',
        'Analysis complete for experiment: ${experiment.title}',
        metadata: {
          'effectSize': effectSize.toStringAsFixed(2),
          'direction': direction.name,
          'significance': significance.name,
        },
      );

      return results;
    } catch (e, stackTrace) {
      await _debug.error(
        'ExperimentAnalysisService',
        'Failed to analyze experiment: $e',
        stackTrace: stackTrace.toString(),
      );
      return null;
    }
  }

  /// Calculate the arithmetic mean of a list of values.
  double _calculateMean(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// Calculate the sample standard deviation.
  double _calculateStdDev(List<double> values, double mean) {
    if (values.length < 2) return 0.0;
    final sumSquaredDiff = values
        .map((v) => pow(v - mean, 2))
        .reduce((a, b) => a + b);
    return sqrt(sumSquaredDiff / (values.length - 1));
  }

  /// Calculate Cohen's d effect size using pooled standard deviation.
  ///
  /// Cohen's d interpretation:
  /// - 0.2: Small effect
  /// - 0.5: Medium effect
  /// - 0.8: Large effect
  double _calculateCohenD(
    double mean1,
    double stdDev1,
    double mean2,
    double stdDev2,
    int n1,
    int n2,
  ) {
    // Calculate pooled standard deviation
    final pooledVariance = ((n1 - 1) * pow(stdDev1, 2) + (n2 - 1) * pow(stdDev2, 2)) /
        (n1 + n2 - 2);
    final pooledStdDev = sqrt(pooledVariance);

    // Avoid division by zero
    if (pooledStdDev == 0) return 0.0;

    // Cohen's d = (M2 - M1) / pooled SD
    // Positive d means intervention > baseline
    return (mean2 - mean1) / pooledStdDev;
  }

  /// Determine the direction of the effect.
  EffectDirection _determineDirection(double effectSize, double percentChange) {
    // Use a threshold to determine meaningful change
    const threshold = 0.2; // Small effect size threshold

    if (effectSize.abs() < threshold) {
      return EffectDirection.noChange;
    } else if (effectSize > 0) {
      return EffectDirection.improved;
    } else {
      return EffectDirection.declined;
    }
  }

  /// Estimate confidence level based on data quality factors.
  ///
  /// Factors considered:
  /// - Sample size (more data = higher confidence)
  /// - Variability (lower variance = higher confidence)
  /// - Data completeness (fewer gaps = higher confidence)
  /// - Confounding factors (fewer = higher confidence)
  double _estimateConfidence(
    int baselineN,
    int interventionN,
    double baselineStdDev,
    double interventionStdDev,
    List<ExperimentEntry> entries,
  ) {
    var confidence = 0.5; // Start at 50%

    // Sample size bonus (up to +20%)
    final totalN = baselineN + interventionN;
    if (totalN >= 20) {
      confidence += 0.20;
    } else if (totalN >= 14) {
      confidence += 0.15;
    } else if (totalN >= 10) {
      confidence += 0.10;
    } else {
      confidence += 0.05;
    }

    // Low variability bonus (up to +15%)
    final avgStdDev = (baselineStdDev + interventionStdDev) / 2;
    if (avgStdDev < 0.5) {
      confidence += 0.15;
    } else if (avgStdDev < 1.0) {
      confidence += 0.10;
    } else if (avgStdDev < 1.5) {
      confidence += 0.05;
    }

    // Data completeness bonus (up to +10%)
    final completeEntries = entries.where((e) => e.isComplete).length;
    final completionRate = entries.isEmpty ? 0 : completeEntries / entries.length;
    if (completionRate >= 0.9) {
      confidence += 0.10;
    } else if (completionRate >= 0.7) {
      confidence += 0.05;
    }

    // Confounding factors penalty (up to -10%)
    final confoundingCount = entries.where((e) => e.hasConfoundingFactors).length;
    final confoundingRate = entries.isEmpty ? 0 : confoundingCount / entries.length;
    if (confoundingRate > 0.3) {
      confidence -= 0.10;
    } else if (confoundingRate > 0.1) {
      confidence -= 0.05;
    }

    return confidence.clamp(0.0, 1.0);
  }

  /// Determine significance level based on effect size and confidence.
  SignificanceLevel _determineSignificance(double absEffectSize, double confidence) {
    // High: Large effect + high confidence
    if (absEffectSize >= 0.8 && confidence >= 0.7) {
      return SignificanceLevel.high;
    }

    // Moderate: Medium effect or high confidence
    if ((absEffectSize >= 0.5 && confidence >= 0.5) ||
        (absEffectSize >= 0.3 && confidence >= 0.7)) {
      return SignificanceLevel.moderate;
    }

    // Low: Small effect with some confidence
    if (absEffectSize >= 0.2 && confidence >= 0.4) {
      return SignificanceLevel.low;
    }

    // Insufficient: Negligible effect or low confidence
    return SignificanceLevel.insufficient;
  }

  /// Generate a user-friendly summary statement.
  String _generateSummary(
    Experiment experiment,
    EffectDirection direction,
    double effectSize,
    double percentChange,
    SignificanceLevel significance,
  ) {
    final intervention = experiment.interventionName;
    final outcome = experiment.outcomeName;
    final absEffectSize = effectSize.abs();
    final absPercentChange = percentChange.abs();

    // Size description
    String sizeDesc;
    if (absEffectSize >= 0.8) {
      sizeDesc = 'large';
    } else if (absEffectSize >= 0.5) {
      sizeDesc = 'moderate';
    } else if (absEffectSize >= 0.2) {
      sizeDesc = 'small';
    } else {
      sizeDesc = 'minimal';
    }

    // Build summary based on direction
    switch (direction) {
      case EffectDirection.improved:
        if (significance == SignificanceLevel.high) {
          return '$intervention appears to have a $sizeDesc positive effect on $outcome '
              '(+${absPercentChange.toStringAsFixed(1)}% improvement). '
              'The evidence suggests this intervention is working for you.';
        } else if (significance == SignificanceLevel.moderate) {
          return '$intervention shows a $sizeDesc positive effect on $outcome '
              '(+${absPercentChange.toStringAsFixed(1)}%). '
              'Consider continuing the experiment for stronger evidence.';
        } else {
          return 'There may be a slight improvement in $outcome with $intervention, '
              'but more data is needed to be confident.';
        }

      case EffectDirection.declined:
        if (significance == SignificanceLevel.high ||
            significance == SignificanceLevel.moderate) {
          return '$intervention appears to have a negative effect on $outcome '
              '(${absPercentChange.toStringAsFixed(1)}% decline). '
              'You may want to reconsider this intervention.';
        } else {
          return 'There may be a slight decline in $outcome with $intervention, '
              'but more data is needed to be certain.';
        }

      case EffectDirection.noChange:
        return '$intervention does not appear to significantly affect $outcome. '
            'The baseline and intervention periods show similar results.';
    }
  }

  /// Generate caveats about the analysis.
  List<String> _generateCaveats(
    int baselineN,
    int interventionN,
    double baselineStdDev,
    double interventionStdDev,
    List<ExperimentEntry> entries,
    Experiment experiment,
  ) {
    final caveats = <String>[];

    // Sample size caveat
    final totalN = baselineN + interventionN;
    if (totalN < 14) {
      caveats.add('Limited data points (${totalN} entries) - results may be less reliable.');
    }

    // High variability caveat
    final avgStdDev = (baselineStdDev + interventionStdDev) / 2;
    if (avgStdDev > 1.5) {
      caveats.add('High day-to-day variability in your ratings makes patterns harder to detect.');
    }

    // Confounding factors caveat
    final confoundingCount = entries.where((e) => e.hasConfoundingFactors).length;
    if (confoundingCount > 0) {
      caveats.add('You marked $confoundingCount days with external factors that may have affected results.');
    }

    // Unequal phases caveat
    if ((baselineN - interventionN).abs() > 3) {
      caveats.add('Unequal number of baseline ($baselineN) and intervention ($interventionN) entries.');
    }

    // Missing data caveat
    final completeEntries = entries.where((e) => e.isComplete).length;
    final completionRate = entries.isEmpty ? 0 : completeEntries / entries.length;
    if (completionRate < 0.7) {
      caveats.add('Some entries are incomplete, which may affect accuracy.');
    }

    // Single-subject caveat (always include)
    caveats.add('This is a personal experiment (N-of-1) - results apply specifically to you.');

    return caveats;
  }

  /// Generate suggestions for the user.
  List<String> _generateSuggestions(
    Experiment experiment,
    EffectDirection direction,
    SignificanceLevel significance,
    List<ExperimentEntry> entries,
  ) {
    final suggestions = <String>[];

    switch (direction) {
      case EffectDirection.improved:
        if (significance == SignificanceLevel.high) {
          suggestions.add('Consider making ${experiment.interventionName} a regular habit.');
          suggestions.add('Try tracking this for a few more weeks to confirm the pattern holds.');
        } else if (significance == SignificanceLevel.moderate) {
          suggestions.add('Continue the experiment for another week to strengthen the evidence.');
          suggestions.add('Pay attention to other factors that might contribute to the improvement.');
        } else {
          suggestions.add('Collect more data before drawing conclusions.');
          suggestions.add('Try to be more consistent with the intervention timing.');
        }
        break;

      case EffectDirection.declined:
        if (significance == SignificanceLevel.high ||
            significance == SignificanceLevel.moderate) {
          suggestions.add('Consider stopping or modifying the intervention.');
          suggestions.add('Reflect on whether external factors may have caused the decline.');
          suggestions.add('Try a variation of the intervention in a new experiment.');
        } else {
          suggestions.add('The decline may be coincidental - continue monitoring.');
          suggestions.add('Look for patterns on specific days or contexts.');
        }
        break;

      case EffectDirection.noChange:
        suggestions.add('The intervention may not affect this particular outcome.');
        suggestions.add('Consider measuring a different outcome, or trying a different intervention.');
        suggestions.add('Ensure you\'re applying the intervention consistently.');
        break;
    }

    // Data quality suggestions
    final confoundingCount = entries.where((e) => e.hasConfoundingFactors).length;
    if (confoundingCount > entries.length * 0.2) {
      suggestions.add('Try to minimize external disruptions during your next experiment.');
    }

    return suggestions;
  }

  /// Quick check if experiment has enough data for meaningful analysis.
  bool hasMinimumDataForAnalysis(
    Experiment experiment,
    List<ExperimentEntry> entries,
  ) {
    final baselineCount = entries
        .where((e) => e.phase == ExperimentPhase.baseline && e.outcomeValue != null)
        .length;
    final interventionCount = entries
        .where((e) => e.phase == ExperimentPhase.intervention && e.outcomeValue != null)
        .length;

    return baselineCount >= experiment.minimumDataPoints &&
        interventionCount >= experiment.minimumDataPoints;
  }

  /// Get data quality metrics for display.
  DataQualityMetrics getDataQuality(
    Experiment experiment,
    List<ExperimentEntry> entries,
  ) {
    final baselineEntries = entries
        .where((e) => e.phase == ExperimentPhase.baseline)
        .toList();
    final interventionEntries = entries
        .where((e) => e.phase == ExperimentPhase.intervention)
        .toList();

    final completeEntries = entries.where((e) => e.isComplete).length;
    final confoundingEntries = entries.where((e) => e.hasConfoundingFactors).length;

    return DataQualityMetrics(
      baselineEntries: baselineEntries.length,
      interventionEntries: interventionEntries.length,
      minimumRequired: experiment.minimumDataPoints,
      completionRate: entries.isEmpty ? 0 : completeEntries / entries.length,
      confoundingRate: entries.isEmpty ? 0 : confoundingEntries / entries.length,
      baselineComplete: baselineEntries.length >= experiment.minimumDataPoints,
      interventionComplete: interventionEntries.length >= experiment.minimumDataPoints,
    );
  }
}

/// Data quality metrics for experiment progress display.
class DataQualityMetrics {
  final int baselineEntries;
  final int interventionEntries;
  final int minimumRequired;
  final double completionRate;
  final double confoundingRate;
  final bool baselineComplete;
  final bool interventionComplete;

  DataQualityMetrics({
    required this.baselineEntries,
    required this.interventionEntries,
    required this.minimumRequired,
    required this.completionRate,
    required this.confoundingRate,
    required this.baselineComplete,
    required this.interventionComplete,
  });

  bool get isReadyForAnalysis => baselineComplete && interventionComplete;

  double get baselineProgress =>
      (baselineEntries / minimumRequired).clamp(0.0, 1.0);

  double get interventionProgress =>
      (interventionEntries / minimumRequired).clamp(0.0, 1.0);

  String get qualityRating {
    if (completionRate >= 0.9 && confoundingRate < 0.1) {
      return 'Excellent';
    } else if (completionRate >= 0.7 && confoundingRate < 0.2) {
      return 'Good';
    } else if (completionRate >= 0.5) {
      return 'Fair';
    } else {
      return 'Needs Improvement';
    }
  }
}
