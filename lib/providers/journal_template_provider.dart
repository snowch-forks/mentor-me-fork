import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mentor_me/models/journal_template.dart';
import 'package:mentor_me/models/structured_journaling_session.dart';
import 'package:mentor_me/services/storage_service.dart';
import 'package:mentor_me/services/debug_service.dart';

/// Provider for managing journal templates and structured journaling sessions
class JournalTemplateProvider with ChangeNotifier {
  final _storage = StorageService();
  final _debug = DebugService();

  List<JournalTemplate> _customTemplates = [];
  List<JournalTemplate> _systemTemplates = [];
  List<StructuredJournalingSession> _sessions = [];

  bool _isLoading = false;

  List<JournalTemplate> get customTemplates => _customTemplates;
  List<JournalTemplate> get systemTemplates => _systemTemplates;
  List<JournalTemplate> get allTemplates => [..._systemTemplates, ..._customTemplates];
  List<StructuredJournalingSession> get sessions => _sessions;
  bool get isLoading => _isLoading;

  /// Get active (incomplete) sessions
  List<StructuredJournalingSession> get activeSessions =>
      _sessions.where((s) => !s.isComplete).toList();

  /// Get completed sessions
  List<StructuredJournalingSession> get completedSessions =>
      _sessions.where((s) => s.isComplete).toList();

  JournalTemplateProvider() {
    _loadTemplates();
    _loadSessions();
  }

  /// Load custom templates from storage
  Future<void> _loadTemplates() async {
    try {
      _isLoading = true;
      notifyListeners();

      final data = await _storage.loadTemplates();
      if (data != null) {
        final List<dynamic> jsonList = jsonDecode(data);
        _customTemplates = jsonList
            .map((json) => JournalTemplate.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      await _debug.info(
        'JournalTemplateProvider',
        'Loaded ${_customTemplates.length} custom templates',
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'JournalTemplateProvider',
        'Failed to load custom templates',
        stackTrace: stackTrace.toString(),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load sessions from storage
  Future<void> _loadSessions() async {
    try {
      final data = await _storage.loadSessions();
      if (data != null) {
        final List<dynamic> jsonList = jsonDecode(data);
        _sessions = jsonList
            .map((json) => StructuredJournalingSession.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      await _debug.info(
        'JournalTemplateProvider',
        'Loaded ${_sessions.length} sessions',
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'JournalTemplateProvider',
        'Failed to load sessions',
        stackTrace: stackTrace.toString(),
      );
    }
  }

  /// Save custom templates to storage
  Future<void> _saveTemplates() async {
    try {
      final jsonList = _customTemplates.map((t) => t.toJson()).toList();
      await _storage.saveTemplates(jsonEncode(jsonList));

      await _debug.info(
        'JournalTemplateProvider',
        'Saved ${_customTemplates.length} custom templates',
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'JournalTemplateProvider',
        'Failed to save custom templates',
        stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Save sessions to storage
  Future<void> _saveSessions() async {
    try {
      final jsonList = _sessions.map((s) => s.toJson()).toList();
      await _storage.saveSessions(jsonEncode(jsonList));

      await _debug.info(
        'JournalTemplateProvider',
        'Saved ${_sessions.length} sessions',
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'JournalTemplateProvider',
        'Failed to save sessions',
        stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Set system templates (called by StructuredJournalingService)
  void setSystemTemplates(List<JournalTemplate> templates) {
    _systemTemplates = templates;
    notifyListeners();
  }

  /// Add a custom template
  Future<void> addTemplate(JournalTemplate template) async {
    try {
      _customTemplates.add(template);
      await _saveTemplates();
      notifyListeners();

      await _debug.info(
        'JournalTemplateProvider',
        'Added custom template: ${template.name}',
        metadata: {'templateId': template.id},
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'JournalTemplateProvider',
        'Failed to add template',
        
        stackTrace: stackTrace.toString(),
        metadata: {'templateId': template.id},
      );
      rethrow;
    }
  }

  /// Update a custom template
  Future<void> updateTemplate(JournalTemplate template) async {
    try {
      final index = _customTemplates.indexWhere((t) => t.id == template.id);
      if (index == -1) {
        throw Exception('Template not found: ${template.id}');
      }

      _customTemplates[index] = template;
      await _saveTemplates();
      notifyListeners();

      await _debug.info(
        'JournalTemplateProvider',
        'Updated template: ${template.name}',
        metadata: {'templateId': template.id},
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'JournalTemplateProvider',
        'Failed to update template',
        
        stackTrace: stackTrace.toString(),
        metadata: {'templateId': template.id},
      );
      rethrow;
    }
  }

  /// Delete a custom template
  Future<void> deleteTemplate(String templateId) async {
    try {
      final template = _customTemplates.firstWhere((t) => t.id == templateId);

      if (template.isSystemDefined) {
        throw Exception('Cannot delete system-defined templates');
      }

      _customTemplates.removeWhere((t) => t.id == templateId);
      await _saveTemplates();
      notifyListeners();

      await _debug.info(
        'JournalTemplateProvider',
        'Deleted template: ${template.name}',
        metadata: {'templateId': templateId},
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'JournalTemplateProvider',
        'Failed to delete template',
        
        stackTrace: stackTrace.toString(),
        metadata: {'templateId': templateId},
      );
      rethrow;
    }
  }

  /// Get template by ID
  JournalTemplate? getTemplateById(String id) {
    try {
      return allTemplates.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Start a new journaling session
  Future<StructuredJournalingSession> startSession(
    JournalTemplate template,
  ) async {
    try {
      final session = StructuredJournalingSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        templateId: template.id,
        templateName: template.name,
        conversation: [],
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
        isComplete: false,
        totalSteps: template.fields.length,
        currentStep: 0,
      );

      _sessions.add(session);
      await _saveSessions();
      notifyListeners();

      await _debug.info(
        'JournalTemplateProvider',
        'Started session: ${template.name}',
        metadata: {
          'sessionId': session.id,
          'templateId': template.id,
        },
      );

      return session;
    } catch (e, stackTrace) {
      await _debug.error(
        'JournalTemplateProvider',
        'Failed to start session',
        
        stackTrace: stackTrace.toString(),
        metadata: {'templateId': template.id},
      );
      rethrow;
    }
  }

  /// Update a session
  Future<void> updateSession(StructuredJournalingSession session) async {
    try {
      final index = _sessions.indexWhere((s) => s.id == session.id);
      if (index == -1) {
        throw Exception('Session not found: ${session.id}');
      }

      _sessions[index] = session.copyWith(lastUpdated: DateTime.now());
      await _saveSessions();
      notifyListeners();

      await _debug.info(
        'JournalTemplateProvider',
        'Updated session',
        metadata: {'sessionId': session.id},
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'JournalTemplateProvider',
        'Failed to update session',
        
        stackTrace: stackTrace.toString(),
        metadata: {'sessionId': session.id},
      );
      rethrow;
    }
  }

  /// Get session by ID
  StructuredJournalingSession? getSessionById(String id) {
    try {
      return _sessions.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Delete a session
  Future<void> deleteSession(String sessionId) async {
    try {
      _sessions.removeWhere((s) => s.id == sessionId);
      await _saveSessions();
      notifyListeners();

      await _debug.info(
        'JournalTemplateProvider',
        'Deleted session',
        metadata: {'sessionId': sessionId},
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'JournalTemplateProvider',
        'Failed to delete session',
        
        stackTrace: stackTrace.toString(),
        metadata: {'sessionId': sessionId},
      );
      rethrow;
    }
  }

  /// Get templates by category
  List<JournalTemplate> getTemplatesByCategory(TemplateCategory category) {
    return allTemplates.where((t) => t.category == category).toList();
  }

  /// Duplicate a template (for users to customize system templates)
  Future<JournalTemplate> duplicateTemplate(String templateId) async {
    try {
      final template = getTemplateById(templateId);
      if (template == null) {
        throw Exception('Template not found: $templateId');
      }

      final duplicate = template.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: '${template.name} (Copy)',
        isSystemDefined: false,
        createdAt: DateTime.now(),
        lastModified: DateTime.now(),
      );

      await addTemplate(duplicate);
      return duplicate;
    } catch (e, stackTrace) {
      await _debug.error(
        'JournalTemplateProvider',
        'Failed to duplicate template',
        
        stackTrace: stackTrace.toString(),
        metadata: {'templateId': templateId},
      );
      rethrow;
    }
  }
}
