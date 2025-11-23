import 'package:mentor_me/models/cognitive_distortion.dart';

/// Real-time cognitive distortion detection service
///
/// Analyzes user text for common cognitive distortions using keyword matching
/// and pattern recognition. Designed for real-time use (no AI calls needed).
class CognitiveDistortionDetector {
  /// Minimum text length to trigger detection (avoid false positives on short text)
  static const int minTextLength = 20;

  /// Minimum keyword matches required for detection
  static const int minKeywordMatches = 2;

  /// Detect cognitive distortions in the given text
  ///
  /// Returns list of detected distortions with confidence scores.
  /// Returns empty list if text is too short or no distortions found.
  List<DetectionResult> detectDistortions(String text) {
    if (text.length < minTextLength) {
      return [];
    }

    final lowerText = text.toLowerCase();
    final results = <DetectionResult>[];

    // Check each distortion type
    for (final distortionType in DistortionType.values) {
      final confidence = _calculateConfidence(lowerText, distortionType);

      // Only report if confidence is sufficient
      if (confidence >= 0.3) {
        // 30% threshold
        results.add(DetectionResult(
          type: distortionType,
          confidence: confidence,
          matchedKeywords: _getMatchedKeywords(lowerText, distortionType),
          suggestedText: _extractRelevantText(text, distortionType),
        ));
      }
    }

    // Sort by confidence (highest first)
    results.sort((a, b) => b.confidence.compareTo(a.confidence));

    // Return top 2 detections max (avoid overwhelming user)
    return results.take(2).toList();
  }

  /// Calculate confidence score for a distortion type (0.0 to 1.0)
  double _calculateConfidence(String lowerText, DistortionType type) {
    final keywords = type.detectionKeywords;
    int matchCount = 0;

    // Count keyword matches
    for (final keyword in keywords) {
      if (lowerText.contains(keyword.toLowerCase())) {
        matchCount++;
      }
    }

    // Special pattern detection for specific distortions
    matchCount += _detectSpecialPatterns(lowerText, type);

    // Calculate base confidence
    double confidence = matchCount / keywords.length;

    // Apply distortion-specific boosting
    confidence = _applyDistortionSpecificBoost(lowerText, type, confidence);

    return confidence.clamp(0.0, 1.0);
  }

  /// Detect special patterns that strongly indicate specific distortions
  int _detectSpecialPatterns(String lowerText, DistortionType type) {
    int bonusPoints = 0;

    switch (type) {
      case DistortionType.allOrNothingThinking:
        // Strong indicators: "never...always", "complete failure", "total disaster"
        if (_containsPattern(lowerText, ['never', 'always'])) bonusPoints += 2;
        if (_containsPattern(lowerText, ['complete', 'failure'])) bonusPoints += 2;
        if (_containsPattern(lowerText, ['total', 'disaster'])) bonusPoints += 2;
        break;

      case DistortionType.labeling:
        // Strong indicators: "I'm a [negative label]", "I am such a [label]"
        if (RegExp(r"i'?m\s+(a\s+)?(loser|failure|idiot|useless|worthless)")
            .hasMatch(lowerText)) {
          bonusPoints += 3;
        }
        break;

      case DistortionType.magnification:
        // Strong indicators: catastrophic language
        if (_containsPattern(
            lowerText, ['disaster', 'catastrophe', 'terrible', 'awful'])) {
          bonusPoints += 2;
        }
        break;

      case DistortionType.shouldStatements:
        // Strong indicators: "I should", "I must", "I ought"
        if (RegExp(r"i\s+(should|must|ought|have to)\s+").hasMatch(lowerText)) {
          bonusPoints += 3;
        }
        break;

      case DistortionType.overgeneralization:
        // Strong indicators: "always", "never", "every time"
        if (_containsPattern(lowerText, ['always', 'never'])) bonusPoints += 2;
        if (lowerText.contains('every time')) bonusPoints += 2;
        break;

      case DistortionType.emotionalReasoning:
        // Strong indicators: "I feel...so it must be"
        if (RegExp(r"i feel.*(so|therefore|must be)").hasMatch(lowerText)) {
          bonusPoints += 3;
        }
        break;

      case DistortionType.personalization:
        // Strong indicators: "my fault", "because of me"
        if (lowerText.contains('my fault')) bonusPoints += 3;
        if (lowerText.contains('because of me')) bonusPoints += 3;
        break;

      default:
        break;
    }

    return bonusPoints;
  }

  /// Check if text contains multiple keywords from a pattern
  bool _containsPattern(String text, List<String> keywords) {
    int matches = 0;
    for (final keyword in keywords) {
      if (text.contains(keyword)) matches++;
    }
    return matches >= keywords.length;
  }

  /// Apply distortion-specific confidence boosting
  double _applyDistortionSpecificBoost(
      String lowerText, DistortionType type, double baseConfidence) {
    // Some distortions are harder to detect with keywords alone
    // Boost confidence if we're fairly sure
    switch (type) {
      case DistortionType.labeling:
      case DistortionType.allOrNothingThinking:
      case DistortionType.shouldStatements:
        // These have strong linguistic markers
        return baseConfidence * 1.2;

      case DistortionType.mentalFilter:
      case DistortionType.discountingThePositive:
        // These are harder to detect without context
        return baseConfidence * 0.8;

      default:
        return baseConfidence;
    }
  }

  /// Get list of matched keywords for a distortion type
  List<String> _getMatchedKeywords(String lowerText, DistortionType type) {
    final matched = <String>[];
    for (final keyword in type.detectionKeywords) {
      if (lowerText.contains(keyword.toLowerCase())) {
        matched.add(keyword);
      }
    }
    return matched;
  }

  /// Extract the most relevant portion of text containing the distortion
  ///
  /// Returns a sentence or phrase that contains the distortion keywords
  String _extractRelevantText(String text, DistortionType type) {
    // Split into sentences
    final sentences = text.split(RegExp(r'[.!?]+'));

    // Find sentence(s) with highest keyword density
    String? bestSentence;
    int maxMatches = 0;

    for (final sentence in sentences) {
      if (sentence.trim().isEmpty) continue;

      int matches = 0;
      final lowerSentence = sentence.toLowerCase();

      for (final keyword in type.detectionKeywords) {
        if (lowerSentence.contains(keyword.toLowerCase())) {
          matches++;
        }
      }

      if (matches > maxMatches) {
        maxMatches = matches;
        bestSentence = sentence.trim();
      }
    }

    return bestSentence ?? text.trim();
  }

  /// Check if user text shows signs of already reframing (positive indicator)
  bool isReframingAttempt(String text) {
    final lowerText = text.toLowerCase();

    // Positive reframing indicators
    final reframingPhrases = [
      'on the other hand',
      'but i can',
      'however i',
      'even though',
      'i can still',
      'i have',
      'i\'ve succeeded',
      'what if i',
      'maybe i',
      'perhaps',
      'another way to look',
      'alternatively',
      'at the same time',
    ];

    for (final phrase in reframingPhrases) {
      if (lowerText.contains(phrase)) {
        return true;
      }
    }

    return false;
  }
}

/// Result of cognitive distortion detection
class DetectionResult {
  final DistortionType type;
  final double confidence; // 0.0 to 1.0
  final List<String> matchedKeywords;
  final String suggestedText; // Relevant portion of user's text

  DetectionResult({
    required this.type,
    required this.confidence,
    required this.matchedKeywords,
    required this.suggestedText,
  });

  @override
  String toString() {
    return 'DetectionResult(${type.displayName}, confidence: ${(confidence * 100).toStringAsFixed(0)}%, '
        'keywords: ${matchedKeywords.join(", ")})';
  }
}
