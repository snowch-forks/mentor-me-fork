import 'package:flutter/foundation.dart';
import '../models/checkin.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

/// Simplified provider - only handles check-in scheduling/reminders
/// Actual check-in content is stored as journal entries
class CheckinProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final NotificationService _notifications = NotificationService();
  Checkin? _nextCheckin;
  DateTime? _lastCheckinCompletedAt;
  bool _isLoading = false;

  Checkin? get nextCheckin => _nextCheckin;
  DateTime? get lastCheckinCompletedAt => _lastCheckinCompletedAt;
  bool get isLoading => _isLoading;

  CheckinProvider() {
    _loadCheckin();
  }

  /// Reload check-in from storage (useful after import/restore)
  Future<void> reload() async {
    await _loadCheckin();
  }

  Future<void> _loadCheckin() async {
    _isLoading = true;
    notifyListeners();

    _nextCheckin = await _storage.loadCheckin();
    if (_nextCheckin?.lastCompletedAt != null) {
      _lastCheckinCompletedAt = _nextCheckin!.lastCompletedAt;
    }
    
    _isLoading = false;
    notifyListeners();
  }

  /// Schedule the next check-in reminder
  /// Returns true if successful, false if permissions are denied
  Future<bool> scheduleNextCheckin(DateTime when) async {
    debugPrint('📅 CheckinProvider.scheduleNextCheckin called for: $when');

    // Check if notifications are enabled
    final areEnabled = await _notifications.areNotificationsEnabled();
    if (!areEnabled) {
      debugPrint('⚠️  Notifications are not enabled');
      notifyListeners(); // Notify listeners even when permissions denied
      return false;
    }

    _nextCheckin = Checkin(
      id: _nextCheckin?.id,
      nextCheckinTime: when,
      lastCompletedAt: _lastCheckinCompletedAt,
    );
    await _storage.saveCheckin(_nextCheckin);
    debugPrint('📅 Checkin saved to storage');

    // Schedule notification
    debugPrint('📅 About to call NotificationService.scheduleCheckinNotification...');
    await _notifications.scheduleCheckinNotification(
      when,
      'Time for your daily reflection! 🌟',
    );
    debugPrint('📅 NotificationService.scheduleCheckinNotification completed');

    notifyListeners();
    return true;
  }

  /// Mark check-in as completed (called when journal entry is saved)
  Future<void> completeCheckin(Map<String, dynamic> responses) async {
    _lastCheckinCompletedAt = DateTime.now();
    _nextCheckin = Checkin(
      id: _nextCheckin?.id,
      nextCheckinTime: null, // Clear scheduled time
      lastCompletedAt: _lastCheckinCompletedAt,
      responses: responses,
    );
    await _storage.saveCheckin(_nextCheckin);

    // Cancel notification since check-in is complete
    try {
      await _notifications.cancelAllNotifications();
    } catch (e) {
      debugPrint('⚠️  Could not cancel notifications: $e');
      // Continue anyway - check-in is complete
    }

    notifyListeners();
  }

  /// Clear the scheduled check-in
  Future<void> clearNextCheckin() async {
    _nextCheckin = Checkin(
      id: _nextCheckin?.id,
      nextCheckinTime: null,
      lastCompletedAt: _lastCheckinCompletedAt,
    );
    await _storage.saveCheckin(_nextCheckin);

    // Cancel notification since check-in is cancelled
    try {
      await _notifications.cancelAllNotifications();
    } catch (e) {
      debugPrint('⚠️  Could not cancel notifications: $e');
      // Continue anyway - check-in is cleared
    }

    notifyListeners();
  }
}