import 'package:flutter/foundation.dart';
import '../models/urge_surfing.dart';
import '../services/storage_service.dart';
import '../services/debug_service.dart';

/// Provider for managing urge surfing sessions
///
/// Tracks impulse management attempts and effectiveness
class UrgeSurfingProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final DebugService _debug = DebugService();

  List<UrgeSurfingSession> _sessions = [];
  bool _isLoading = false;

  List<UrgeSurfingSession> get sessions => List.unmodifiable(_sessions);
  bool get isLoading => _isLoading;

  /// Get sessions sorted by date (most recent first)
  List<UrgeSurfingSession> get sortedSessions {
    final sorted = List<UrgeSurfingSession>.from(_sessions);
    sorted.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return sorted;
  }

  /// Get sessions from the last N days
  List<UrgeSurfingSession> getRecentSessions({int days = 30}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return sortedSessions.where((s) => s.completedAt.isAfter(cutoff)).toList();
  }

  /// Get sessions by technique
  List<UrgeSurfingSession> getByTechnique(UrgeTechnique technique) {
    return sortedSessions.where((s) => s.technique == technique).toList();
  }

  /// Get sessions by urge category
  List<UrgeSurfingSession> getByCategory(UrgeCategory category) {
    return sortedSessions.where((s) => s.urgeCategory == category).toList();
  }

  /// Get sessions by trigger
  List<UrgeSurfingSession> getByTrigger(UrgeTrigger trigger) {
    return sortedSessions.where((s) => s.trigger == trigger).toList();
  }

  /// Calculate overall statistics
  UrgeSurfingStats get stats => UrgeSurfingStats.fromSessions(_sessions);

  /// Success rate (didn't act on urge)
  double get successRate {
    if (_sessions.isEmpty) return 0;
    final successful = _sessions.where((s) => !s.didActOnUrge).length;
    return (successful / _sessions.length) * 100;
  }

  /// Average intensity reduction
  double get averageIntensityReduction {
    final withAfter = _sessions.where((s) => s.urgeIntensityAfter != null);
    if (withAfter.isEmpty) return 0;

    final totalReduction = withAfter.fold<int>(
      0,
      (sum, s) => sum + (s.urgeIntensityBefore - s.urgeIntensityAfter!),
    );

    return totalReduction / withAfter.length;
  }

  /// Record a new urge surfing session
  Future<UrgeSurfingSession> addSession(UrgeSurfingSession session) async {
    try {
      _isLoading = true;
      notifyListeners();

      _sessions.add(session);
      await _saveToStorage();

      await _debug.info(
        'UrgeSurfingProvider',
        'Urge surfing session recorded: ${session.technique.displayName}',
        metadata: {
          'technique': session.technique.name,
          'category': session.urgeCategory?.name,
          'trigger': session.trigger?.name,
          'intensityBefore': session.urgeIntensityBefore,
          'didActOnUrge': session.didActOnUrge,
          'id': session.id,
        },
      );

      _isLoading = false;
      notifyListeners();

      return session;
    } catch (e, stackTrace) {
      await _debug.error(
        'UrgeSurfingProvider',
        'Failed to record urge surfing session',
        stackTrace: stackTrace.toString(),
      );
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Update an existing session (e.g., add post-session intensity)
  Future<void> updateSession(UrgeSurfingSession session) async {
    try {
      final index = _sessions.indexWhere((s) => s.id == session.id);
      if (index == -1) {
        throw Exception('Session not found');
      }

      _sessions[index] = session;
      await _saveToStorage();
      notifyListeners();

      await _debug.info(
        'UrgeSurfingProvider',
        'Urge surfing session updated',
        metadata: {'id': session.id},
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'UrgeSurfingProvider',
        'Failed to update urge surfing session',
        stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Delete a session
  Future<void> deleteSession(String id) async {
    try {
      _sessions.removeWhere((s) => s.id == id);
      await _saveToStorage();
      notifyListeners();

      await _debug.info(
        'UrgeSurfingProvider',
        'Urge surfing session deleted',
        metadata: {'id': id},
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'UrgeSurfingProvider',
        'Failed to delete urge surfing session',
        stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Load sessions from storage
  Future<void> loadSessions() async {
    try {
      _isLoading = true;
      notifyListeners();

      final data = await _storage.getUrgeSurfingSessions();
      if (data != null) {
        _sessions = data
            .map((json) => UrgeSurfingSession.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      await _debug.info(
        'UrgeSurfingProvider',
        'Loaded ${_sessions.length} urge surfing sessions from storage',
      );

      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      await _debug.error(
        'UrgeSurfingProvider',
        'Failed to load urge surfing sessions',
        stackTrace: stackTrace.toString(),
      );
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save sessions to storage
  Future<void> _saveToStorage() async {
    try {
      final json = _sessions.map((s) => s.toJson()).toList();
      await _storage.saveUrgeSurfingSessions(json);
    } catch (e, stackTrace) {
      await _debug.error(
        'UrgeSurfingProvider',
        'Failed to save urge surfing sessions',
        stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Clear all sessions (for testing/reset)
  Future<void> clearAllSessions() async {
    try {
      _sessions.clear();
      await _saveToStorage();
      notifyListeners();

      await _debug.info('UrgeSurfingProvider', 'All urge surfing sessions cleared');
    } catch (e, stackTrace) {
      await _debug.error(
        'UrgeSurfingProvider',
        'Failed to clear urge surfing sessions',
        stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Get most effective technique based on success rate
  UrgeTechnique? get mostEffectiveTechnique {
    if (_sessions.isEmpty) return null;

    final techniqueSuccess = <UrgeTechnique, List<bool>>{};
    for (final session in _sessions) {
      techniqueSuccess[session.technique] ??= [];
      techniqueSuccess[session.technique]!.add(!session.didActOnUrge);
    }

    UrgeTechnique? best;
    double bestRate = 0;

    for (final entry in techniqueSuccess.entries) {
      final successful = entry.value.where((s) => s).length;
      final rate = successful / entry.value.length;
      if (rate > bestRate) {
        bestRate = rate;
        best = entry.key;
      }
    }

    return best;
  }

  /// Get most common trigger
  UrgeTrigger? get mostCommonTrigger {
    final triggers = _sessions
        .where((s) => s.trigger != null)
        .map((s) => s.trigger!)
        .toList();

    if (triggers.isEmpty) return null;

    final counts = <UrgeTrigger, int>{};
    for (final trigger in triggers) {
      counts[trigger] = (counts[trigger] ?? 0) + 1;
    }

    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Get sessions linked to HALT checks
  List<UrgeSurfingSession> get sessionsLinkedToHalt {
    return sortedSessions.where((s) => s.linkedHaltCheckId != null).toList();
  }
}
