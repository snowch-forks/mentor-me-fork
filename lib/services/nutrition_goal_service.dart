/// Service for LLM-assisted nutrition goal generation
///
/// Uses AI to generate personalized nutrition targets based on:
/// - User profile (weight, height, gender, age)
/// - Weight goals (lose/gain/maintain)
/// - Health concerns (free text like "I want to lower triglycerides")
/// - Activity level
library;

import 'dart:convert';
import '../models/food_entry.dart';
import '../models/weight_entry.dart';
import 'ai_service.dart';
import 'debug_service.dart';

/// Result of LLM-assisted nutrition goal generation
class NutritionGoalResult {
  final NutritionGoal goal;
  final String reasoning;
  final bool success;
  final String? errorMessage;

  const NutritionGoalResult({
    required this.goal,
    required this.reasoning,
    this.success = true,
    this.errorMessage,
  });

  factory NutritionGoalResult.error(String message) {
    return NutritionGoalResult(
      goal: NutritionGoal.defaultGoal,
      reasoning: '',
      success: false,
      errorMessage: message,
    );
  }
}

/// User profile data for nutrition goal calculation
class NutritionProfile {
  final double? weightKg;
  final double? heightCm;
  final String? gender; // 'male', 'female'
  final int? age;
  final String? activityLevel; // 'sedentary', 'light', 'moderate', 'active', 'very_active'
  final WeightGoal? weightGoal;
  final String? healthConcerns; // Free text like "I want to lower triglycerides"

  const NutritionProfile({
    this.weightKg,
    this.heightCm,
    this.gender,
    this.age,
    this.activityLevel,
    this.weightGoal,
    this.healthConcerns,
  });

  /// Get weight goal type description
  String get weightGoalDescription {
    if (weightGoal == null) return 'maintain weight';

    final current = weightKg;
    final target = weightGoal!.targetWeight; // in goal's unit

    if (current == null) {
      return 'reach ${target.toStringAsFixed(1)} ${weightGoal!.unit.displayName}';
    }

    // Convert current weight to goal's unit for comparison
    final currentInGoalUnit = _convertWeight(current, WeightUnit.kg, weightGoal!.unit);

    if (currentInGoalUnit > target + 1) {
      return 'lose weight (current: ${currentInGoalUnit.toStringAsFixed(1)}, target: ${target.toStringAsFixed(1)} ${weightGoal!.unit.displayName})';
    } else if (currentInGoalUnit < target - 1) {
      return 'gain weight (current: ${currentInGoalUnit.toStringAsFixed(1)}, target: ${target.toStringAsFixed(1)} ${weightGoal!.unit.displayName})';
    }
    return 'maintain weight';
  }

  double _convertWeight(double weight, WeightUnit from, WeightUnit to) {
    if (from == to) return weight;

    // Convert to kg first
    double weightInKg;
    switch (from) {
      case WeightUnit.kg:
        weightInKg = weight;
      case WeightUnit.lbs:
        weightInKg = weight / 2.20462;
      case WeightUnit.stone:
        weightInKg = weight * 6.35029;
    }

    // Convert from kg to target unit
    switch (to) {
      case WeightUnit.kg:
        return weightInKg;
      case WeightUnit.lbs:
        return weightInKg * 2.20462;
      case WeightUnit.stone:
        return weightInKg / 6.35029;
    }
  }

  /// Get activity level description
  String get activityDescription {
    switch (activityLevel) {
      case 'sedentary':
        return 'sedentary (little or no exercise)';
      case 'light':
        return 'lightly active (light exercise 1-3 days/week)';
      case 'moderate':
        return 'moderately active (moderate exercise 3-5 days/week)';
      case 'active':
        return 'active (hard exercise 6-7 days/week)';
      case 'very_active':
        return 'very active (very hard exercise, physical job)';
      default:
        return 'moderately active';
    }
  }
}

/// Service for generating AI-assisted nutrition goals
class NutritionGoalService {
  final AIService _ai = AIService();
  final DebugService _debug = DebugService();

  /// Generate personalized nutrition goals using LLM
  ///
  /// Takes user profile information and health concerns to generate
  /// appropriate calorie, macro, and micronutrient targets.
  Future<NutritionGoalResult> generateNutritionGoals(NutritionProfile profile) async {
    if (!_ai.hasApiKey()) {
      return NutritionGoalResult.error(
        'AI API key required for personalized nutrition goals. '
        'Please add your API key in Settings → AI Settings.',
      );
    }

    try {
      await _debug.info('NutritionGoalService', 'Generating nutrition goals', metadata: {
        'hasWeight': profile.weightKg != null,
        'hasHeight': profile.heightCm != null,
        'hasGender': profile.gender != null,
        'hasAge': profile.age != null,
        'activityLevel': profile.activityLevel,
        'hasWeightGoal': profile.weightGoal != null,
        'hasHealthConcerns': profile.healthConcerns?.isNotEmpty == true,
      });

      final prompt = _buildPrompt(profile);
      final response = await _ai.getCoachingResponse(prompt: prompt);

      // Parse the JSON response
      final jsonMatch = RegExp(r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}').firstMatch(response);
      if (jsonMatch == null) {
        await _debug.warning('NutritionGoalService', 'No JSON found in response', metadata: {
          'response': response,
        });
        return NutritionGoalResult.error('Unable to parse AI response. Please try again.');
      }

      final jsonString = jsonMatch.group(0)!;
      final Map<String, dynamic> parsed = json.decode(jsonString);

      // Parse integer values safely
      int parseIntSafe(dynamic value, int defaultValue) {
        if (value == null) return defaultValue;
        if (value is int) return value;
        if (value is double) return value.round();
        if (value is String) return int.tryParse(value) ?? defaultValue;
        return defaultValue;
      }

      // Extract the goal values
      final goal = NutritionGoal(
        targetCalories: parseIntSafe(parsed['targetCalories'], 2000),
        targetProteinGrams: parseIntSafe(parsed['targetProteinGrams'], 50),
        targetCarbsGrams: parseIntSafe(parsed['targetCarbsGrams'], 250),
        targetFatGrams: parseIntSafe(parsed['targetFatGrams'], 65),
        maxSodiumMg: parsed['maxSodiumMg'] != null ? parseIntSafe(parsed['maxSodiumMg'], 2300) : null,
        maxSugarGrams: parsed['maxSugarGrams'] != null ? parseIntSafe(parsed['maxSugarGrams'], 50) : null,
        minFiberGrams: parsed['minFiberGrams'] != null ? parseIntSafe(parsed['minFiberGrams'], 25) : null,
        maxCholesterolMg: parsed['maxCholesterolMg'] != null ? parseIntSafe(parsed['maxCholesterolMg'], 300) : null,
        minPotassiumMg: parsed['minPotassiumMg'] != null ? parseIntSafe(parsed['minPotassiumMg'], 2600) : null,
        healthConcerns: profile.healthConcerns,
        aiReasoning: parsed['reasoning']?.toString() ?? '',
        isAiGenerated: true,
        generatedAt: DateTime.now(),
        activityLevel: profile.activityLevel,
      );

      final reasoning = parsed['reasoning']?.toString() ??
          'Personalized nutrition targets generated based on your profile.';

      await _debug.info('NutritionGoalService', 'Generated nutrition goals', metadata: {
        'calories': goal.targetCalories,
        'protein': goal.targetProteinGrams,
        'carbs': goal.targetCarbsGrams,
        'fat': goal.targetFatGrams,
        'hasMicroTargets': goal.hasMicronutrientTargets,
      });

      return NutritionGoalResult(
        goal: goal,
        reasoning: reasoning,
        success: true,
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'NutritionGoalService',
        'Failed to generate nutrition goals: $e',
        stackTrace: stackTrace.toString(),
      );
      return NutritionGoalResult.error('Failed to generate goals: $e');
    }
  }

  String _buildPrompt(NutritionProfile profile) {
    final buffer = StringBuffer();

    buffer.writeln('Generate personalized daily nutrition goals for this user.');
    buffer.writeln();
    buffer.writeln('USER PROFILE:');

    if (profile.weightKg != null) {
      buffer.writeln('- Weight: ${profile.weightKg!.toStringAsFixed(1)} kg (${(profile.weightKg! * 2.20462).toStringAsFixed(1)} lbs)');
    }
    if (profile.heightCm != null) {
      final feet = (profile.heightCm! / 30.48).floor();
      final inches = ((profile.heightCm! / 2.54) % 12).round();
      buffer.writeln('- Height: ${profile.heightCm!.toStringAsFixed(0)} cm (${feet}\'${inches}")');
    }
    if (profile.gender != null) {
      buffer.writeln('- Gender: ${profile.gender}');
    }
    if (profile.age != null) {
      buffer.writeln('- Age: ${profile.age} years');
    }
    buffer.writeln('- Activity Level: ${profile.activityDescription}');
    buffer.writeln('- Weight Goal: ${profile.weightGoalDescription}');

    if (profile.healthConcerns?.isNotEmpty == true) {
      buffer.writeln();
      buffer.writeln('HEALTH CONCERNS:');
      buffer.writeln(profile.healthConcerns);
    }

    buffer.writeln();
    buffer.writeln('Based on this profile, provide personalized daily nutrition targets.');
    buffer.writeln();
    buffer.writeln('Respond with ONLY valid JSON in this exact format (no markdown):');
    buffer.writeln('{');
    buffer.writeln('  "targetCalories": 2000,');
    buffer.writeln('  "targetProteinGrams": 120,');
    buffer.writeln('  "targetCarbsGrams": 200,');
    buffer.writeln('  "targetFatGrams": 65,');
    buffer.writeln('  "maxSodiumMg": 2300,');
    buffer.writeln('  "maxSugarGrams": 36,');
    buffer.writeln('  "minFiberGrams": 30,');
    buffer.writeln('  "maxCholesterolMg": 300,');
    buffer.writeln('  "minPotassiumMg": 3400,');
    buffer.writeln('  "reasoning": "Brief explanation of why these targets are appropriate for this user"');
    buffer.writeln('}');
    buffer.writeln();
    buffer.writeln('GUIDELINES:');
    buffer.writeln('- Calculate calories using Mifflin-St Jeor equation with appropriate activity multiplier');
    buffer.writeln('- For weight loss: create 500 calorie deficit (1 lb/week loss)');
    buffer.writeln('- For weight gain: create 300-500 calorie surplus');
    buffer.writeln('- Protein: 0.7-1g per pound of body weight for muscle maintenance');
    buffer.writeln('- Fat: 25-35% of calories');
    buffer.writeln('- Carbs: remainder of calories');
    buffer.writeln();
    buffer.writeln('MICRONUTRIENT ADJUSTMENTS based on health concerns:');
    buffer.writeln('- High blood pressure: maxSodiumMg = 1500');
    buffer.writeln('- Heart disease/cholesterol concerns: maxCholesterolMg = 200, increase potassium');
    buffer.writeln('- Diabetes/triglycerides: maxSugarGrams = 25, increase fiber');
    buffer.writeln('- General health: use standard values');
    buffer.writeln();
    buffer.writeln('Only include micronutrient targets if relevant to the user\'s health concerns.');
    buffer.writeln('If no specific health concerns, omit the micronutrient fields.');
    buffer.writeln();
    buffer.writeln('JSON:');

    return buffer.toString();
  }
}
