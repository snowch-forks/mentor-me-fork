import 'package:flutter/foundation.dart';
import 'storage_service.dart';

/// Tracks notification engagement metrics to optimize notification effectiveness
/// and build a "mentor trust" score based on user responsiveness
class NotificationAnalyticsService {
  static final NotificationAnalyticsService _instance = NotificationAnalyticsService._internal();
  factory NotificationAnalyticsService() => _instance;
  NotificationAnalyticsService._internal();

  final StorageService _storage = StorageService();

  // Keys for storage
  static const String _notificationEventsKey = 'notification_events';
  static const String _mentorTrustScoreKey = 'mentor_trust_score';
  static const String _lastNotificationClickKey = 'last_notification_click';

  /// Track when a notification is sent
  Future<void> trackNotificationSent({
    required String notificationId,
    required String type, // 'mentor_reminder', 'streak_protection', 'critical', etc.
    String? title,
    String? body,
  }) async {
    try {
      final event = {
        'id': notificationId,
        'type': type,
        'title': title,
        'body': body,
        'sentAt': DateTime.now().toIso8601String(),
        'clicked': false,
        'activityCompleted': false,
      };

      final events = await _loadEvents();
      events.add(event);

      // Keep only last 100 events to prevent storage bloat
      if (events.length > 100) {
        events.removeRange(0, events.length - 100);
      }

      await _saveEvents(events);
      debugPrint('📊 Tracked notification sent: $type - $title');
    } catch (e) {
      debugPrint('❌ Error tracking notification sent: $e');
    }
  }

  /// Track when a notification is clicked
  Future<void> trackNotificationClicked({
    required String notificationId,
  }) async {
    try {
      final events = await _loadEvents();

      // Find the most recent matching notification
      final event = events.lastWhere(
        (e) => e['id'] == notificationId,
        orElse: () => <String, dynamic>{},
      );

      if (event.isNotEmpty) {
        event['clicked'] = true;
        event['clickedAt'] = DateTime.now().toIso8601String();
        await _saveEvents(events);

        // Store the click time for recent activity tracking
        final settings = await _storage.loadSettings();
        settings[_lastNotificationClickKey] = DateTime.now().toIso8601String();
        await _storage.saveSettings(settings);

        debugPrint('📊 Tracked notification clicked: ${event['type']}');

        // Update mentor trust score
        await _updateMentorTrustScore();
      }
    } catch (e) {
      debugPrint('❌ Error tracking notification clicked: $e');
    }
  }

  /// Track when an activity is completed (journal, habit, etc.)
  Future<void> trackActivityCompleted({
    required String activityType, // 'journal', 'habit', 'goal', 'checkin'
  }) async {
    try {
      final lastClickTime = await _getLastNotificationClickTime();

      // Only track if activity was completed within 30 minutes of notification click
      if (lastClickTime != null) {
        final timeSinceClick = DateTime.now().difference(lastClickTime);

        if (timeSinceClick.inMinutes <= 30) {
          final events = await _loadEvents();

          // Find the most recent clicked notification
          final recentClickedEvent = events.lastWhere(
            (e) => e['clicked'] == true && e['activityCompleted'] == false,
            orElse: () => <String, dynamic>{},
          );

          if (recentClickedEvent.isNotEmpty) {
            recentClickedEvent['activityCompleted'] = true;
            recentClickedEvent['activityType'] = activityType;
            recentClickedEvent['completedAt'] = DateTime.now().toIso8601String();
            await _saveEvents(events);

            debugPrint('📊 Tracked activity completed after notification: $activityType');

            // Update mentor trust score
            await _updateMentorTrustScore();
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error tracking activity completed: $e');
    }
  }

  /// Check if user recently clicked a notification (within last 30 minutes)
  /// This is used to show celebration messages
  Future<bool> wasRecentlyNotified() async {
    try {
      final lastClickTime = await _getLastNotificationClickTime();
      if (lastClickTime == null) return false;

      final timeSinceClick = DateTime.now().difference(lastClickTime);
      return timeSinceClick.inMinutes <= 30;
    } catch (e) {
      debugPrint('❌ Error checking recent notification: $e');
      return false;
    }
  }

  /// Get celebration message if activity was completed after notification
  Future<String?> getCelebrationMessage(String activityType) async {
    try {
      final wasNotified = await wasRecentlyNotified();

      if (wasNotified) {
        // Return contextual celebration message
        switch (activityType) {
          case 'journal':
            return "Great timing! You reflected right when your mentor reminded you 🌟";
          case 'habit':
            return "Perfect! You responded to your reminder and completed your habit 🎯";
          case 'goal':
            return "Excellent responsiveness! You took action right after your mentor's nudge 💪";
          case 'checkin':
            return "Wonderful! You checked in just when your mentor suggested 🌈";
          default:
            return "Nice work! You responded to your mentor's reminder ✨";
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error getting celebration message: $e');
      return null;
    }
  }

  /// Calculate mentor trust score (0-100)
  /// Based on notification response rate over last 30 days
  Future<double> getMentorTrustScore() async {
    try {
      final settings = await _storage.loadSettings();
      final score = settings[_mentorTrustScoreKey] as double?;
      return score ?? 50.0; // Default to 50 (neutral)
    } catch (e) {
      debugPrint('❌ Error getting mentor trust score: $e');
      return 50.0;
    }
  }

  /// Update mentor trust score based on recent engagement
  Future<void> _updateMentorTrustScore() async {
    try {
      final events = await _loadEvents();

      // Only consider events from last 30 days
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final recentEvents = events.where((e) {
        final sentAt = DateTime.tryParse(e['sentAt'] as String? ?? '');
        return sentAt != null && sentAt.isAfter(thirtyDaysAgo);
      }).toList();

      if (recentEvents.isEmpty) {
        return; // Not enough data yet
      }

      // Calculate metrics
      final totalNotifications = recentEvents.length;
      final clickedCount = recentEvents.where((e) => e['clicked'] == true).length;
      final completedCount = recentEvents.where((e) => e['activityCompleted'] == true).length;

      // Calculate score (weighted: 40% click rate, 60% completion rate)
      final clickRate = totalNotifications > 0 ? clickedCount / totalNotifications : 0.0;
      final completionRate = clickedCount > 0 ? completedCount / clickedCount : 0.0;

      final score = (clickRate * 40) + (completionRate * 60);

      // Store score
      final settings = await _storage.loadSettings();
      settings[_mentorTrustScoreKey] = score * 100; // Convert to 0-100 scale
      await _storage.saveSettings(settings);

      debugPrint('📊 Updated mentor trust score: ${(score * 100).toStringAsFixed(1)}%');
      debugPrint('   Click rate: ${(clickRate * 100).toStringAsFixed(1)}% ($clickedCount/$totalNotifications)');
      debugPrint('   Completion rate: ${(completionRate * 100).toStringAsFixed(1)}% ($completedCount/$clickedCount)');
    } catch (e) {
      debugPrint('❌ Error updating mentor trust score: $e');
    }
  }

  /// Get engagement statistics for debugging/analytics
  Future<Map<String, dynamic>> getEngagementStats() async {
    try {
      final events = await _loadEvents();
      final trustScore = await getMentorTrustScore();

      // Last 30 days
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final recentEvents = events.where((e) {
        final sentAt = DateTime.tryParse(e['sentAt'] as String? ?? '');
        return sentAt != null && sentAt.isAfter(thirtyDaysAgo);
      }).toList();

      final totalNotifications = recentEvents.length;
      final clickedCount = recentEvents.where((e) => e['clicked'] == true).length;
      final completedCount = recentEvents.where((e) => e['activityCompleted'] == true).length;

      return {
        'totalNotifications': totalNotifications,
        'clickedCount': clickedCount,
        'completedCount': completedCount,
        'clickRate': totalNotifications > 0 ? (clickedCount / totalNotifications * 100) : 0.0,
        'completionRate': clickedCount > 0 ? (completedCount / clickedCount * 100) : 0.0,
        'mentorTrustScore': trustScore,
      };
    } catch (e) {
      debugPrint('❌ Error getting engagement stats: $e');
      return {};
    }
  }

  /// Get time since last notification click
  Future<DateTime?> _getLastNotificationClickTime() async {
    try {
      final settings = await _storage.loadSettings();
      final lastClickStr = settings[_lastNotificationClickKey] as String?;

      if (lastClickStr != null) {
        return DateTime.tryParse(lastClickStr);
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error getting last notification click time: $e');
      return null;
    }
  }

  /// Load notification events from storage
  Future<List<Map<String, dynamic>>> _loadEvents() async {
    try {
      final settings = await _storage.loadSettings();
      final eventsList = settings[_notificationEventsKey] as List?;

      if (eventsList != null) {
        return List<Map<String, dynamic>>.from(
          eventsList.map((e) => Map<String, dynamic>.from(e as Map))
        );
      }

      return [];
    } catch (e) {
      debugPrint('❌ Error loading notification events: $e');
      return [];
    }
  }

  /// Save notification events to storage
  Future<void> _saveEvents(List<Map<String, dynamic>> events) async {
    try {
      final settings = await _storage.loadSettings();
      settings[_notificationEventsKey] = events;
      await _storage.saveSettings(settings);
    } catch (e) {
      debugPrint('❌ Error saving notification events: $e');
    }
  }

  /// Clear all analytics data (for testing or reset)
  Future<void> clearAnalytics() async {
    try {
      final settings = await _storage.loadSettings();
      settings.remove(_notificationEventsKey);
      settings.remove(_mentorTrustScoreKey);
      settings.remove(_lastNotificationClickKey);
      await _storage.saveSettings(settings);
      debugPrint('📊 Cleared all notification analytics');
    } catch (e) {
      debugPrint('❌ Error clearing analytics: $e');
    }
  }
}
