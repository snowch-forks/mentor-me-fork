import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/goal.dart';
import '../models/milestone.dart';
import 'ai_service.dart';

class GoalDecompositionService {
  final AIService _aiService = AIService();

  Future<List<Milestone>> suggestMilestones(Goal goal) async {
    // Check if API key is set
    if (!_aiService.hasApiKey()) {
      return [];
    }

    try {
      final prompt = _buildPrompt(goal);

      // Use AIService which handles web/mobile routing
      final response = await _aiService.getCoachingResponse(
        prompt: prompt,
        goals: [goal],
      );

      return _parseMilestones(response, goal.id);
    } catch (e) {
      debugPrint('Error suggesting milestones: $e');
      return [];
    }
  }

  String _buildPrompt(Goal goal) {
    final targetDateStr = goal.targetDate != null
        ? goal.targetDate!.toIso8601String().split('T')[0]
        : 'Not specified';

    return '''Break down this goal into 3-5 achievable milestones:

Goal: ${goal.title}
Description: ${goal.description}
Category: ${goal.category.displayName}
Target Date: $targetDateStr

Create 3-5 specific, measurable milestones with realistic timeframes. Return as JSON array with:
- title (short, actionable)
- description (1-2 sentences, specific steps)
- suggestedWeeksFromNow (number)

Be encouraging but realistic. Make milestones progressively build on each other.

Return ONLY valid JSON array, no other text.''';
  }

  List<Milestone> _parseMilestones(String response, String goalId) {
    try {
      // Extract JSON from response (may have additional text)
      final jsonStart = response.indexOf('[');
      final jsonEnd = response.lastIndexOf(']') + 1;
      
      if (jsonStart == -1 || jsonEnd == 0) {
        debugPrint('No JSON found in response');
        return [];
      }

      final jsonStr = response.substring(jsonStart, jsonEnd);
      final List<dynamic> parsed = json.decode(jsonStr);
      
      final milestones = <Milestone>[];
      final now = DateTime.now();

      for (int i = 0; i < parsed.length; i++) {
        final item = parsed[i];
        final weeksFromNow = (item['suggestedWeeksFromNow'] as num).toInt();
        final targetDate = now.add(Duration(days: weeksFromNow * 7));

        milestones.add(Milestone(
          goalId: goalId,
          title: item['title'],
          description: item['description'],
          targetDate: targetDate,
          order: i,
        ));
      }

      debugPrint('✓ Parsed ${milestones.length} milestones');
      return milestones;
    } catch (e) {
      debugPrint('Error parsing milestones: $e');
      debugPrint('Response was: ${response.substring(0, response.length > 200 ? 200 : response.length)}');
      return [];
    }
  }
}