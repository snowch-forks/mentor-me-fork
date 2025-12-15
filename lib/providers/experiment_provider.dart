// lib/providers/experiment_provider.dart
// Manages experiments for the Lab feature (hypothesis testing)

import 'package:flutter/foundation.dart';
import '../models/experiment.dart';
import '../models/experiment_entry.dart';
import '../services/storage_service.dart';
import '../services/debug_service.dart';

class ExperimentProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final DebugService _debug = DebugService();

  List<Experiment> _experiments = [];
  List<ExperimentEntry> _entries = [];
  bool _isLoading = false;

  // Getters
  List<Experiment> get experiments => _experiments;
  List<ExperimentEntry> get entries => _entries;
  bool get isLoading => _isLoading;

  /// Get experiments that are currently running (baseline or active)
  List<Experiment> get activeExperiments => _experiments
      .where((e) => e.status == ExperimentStatus.baseline ||
                    e.status == ExperimentStatus.active)
      .toList();

  /// Get completed experiments
  List<Experiment> get completedExperiments => _experiments
      .where((e) => e.status == ExperimentStatus.completed)
      .toList();

  /// Get draft experiments
  List<Experiment> get draftExperiments => _experiments
      .where((e) => e.status == ExperimentStatus.draft)
      .toList();

  /// Get abandoned experiments
  List<Experiment> get abandonedExperiments => _experiments
      .where((e) => e.status == ExperimentStatus.abandoned)
      .toList();

  ExperimentProvider() {
    _loadData();
  }

  /// Reload data from storage (useful after import/restore)
  Future<void> reload() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _experiments = await _storage.loadExperiments();
      _entries = await _storage.loadExperimentEntries();

      // Sort experiments by created date (most recent first)
      _experiments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Sort entries by date (most recent first)
      _entries.sort((a, b) => b.date.compareTo(a.date));

      await _debug.info('ExperimentProvider',
        'Loaded ${_experiments.length} experiments and ${_entries.length} entries');
    } catch (e, stackTrace) {
      await _debug.error('ExperimentProvider', 'Failed to load data: $e',
        stackTrace: stackTrace.toString());
    }

    _isLoading = false;
    notifyListeners();
  }

  // ==================== EXPERIMENT CRUD ====================

  /// Add a new experiment
  Future<void> addExperiment(Experiment experiment) async {
    _experiments.insert(0, experiment);
    await _storage.saveExperiments(_experiments);
    notifyListeners();

    await _debug.info('ExperimentProvider',
      'Added experiment: ${experiment.title}',
      metadata: {'id': experiment.id});
  }

  /// Update an existing experiment
  Future<void> updateExperiment(Experiment experiment) async {
    final index = _experiments.indexWhere((e) => e.id == experiment.id);
    if (index != -1) {
      _experiments[index] = experiment;
      await _storage.saveExperiments(_experiments);
      notifyListeners();

      await _debug.info('ExperimentProvider',
        'Updated experiment: ${experiment.title}',
        metadata: {'id': experiment.id, 'status': experiment.status.name});
    }
  }

  /// Delete an experiment and its entries
  Future<void> deleteExperiment(String experimentId) async {
    final experiment = getExperimentById(experimentId);
    _experiments.removeWhere((e) => e.id == experimentId);
    _entries.removeWhere((e) => e.experimentId == experimentId);

    await _storage.saveExperiments(_experiments);
    await _storage.saveExperimentEntries(_entries);
    notifyListeners();

    await _debug.info('ExperimentProvider',
      'Deleted experiment: ${experiment?.title ?? experimentId}');
  }

  /// Get experiment by ID
  Experiment? getExperimentById(String id) {
    try {
      return _experiments.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  // ==================== PHASE TRANSITIONS ====================

  /// Start the baseline phase of an experiment
  Future<void> startBaseline(String experimentId) async {
    final experiment = getExperimentById(experimentId);
    if (experiment == null) return;
    if (experiment.status != ExperimentStatus.draft) return;

    final updated = experiment.copyWith(
      status: ExperimentStatus.baseline,
      startedAt: DateTime.now(),
    );
    await updateExperiment(updated);

    await _debug.info('ExperimentProvider',
      'Started baseline for: ${experiment.title}');
  }

  /// Transition from baseline to intervention phase
  Future<void> startIntervention(String experimentId) async {
    final experiment = getExperimentById(experimentId);
    if (experiment == null) return;
    if (experiment.status != ExperimentStatus.baseline) return;

    final updated = experiment.copyWith(
      status: ExperimentStatus.active,
      interventionStartedAt: DateTime.now(),
    );
    await updateExperiment(updated);

    await _debug.info('ExperimentProvider',
      'Started intervention for: ${experiment.title}');
  }

  /// Complete an experiment with results
  Future<void> completeExperiment(String experimentId, ExperimentResults results) async {
    final experiment = getExperimentById(experimentId);
    if (experiment == null) return;
    if (experiment.status != ExperimentStatus.active) return;

    final updated = experiment.copyWith(
      status: ExperimentStatus.completed,
      completedAt: DateTime.now(),
      results: results,
    );
    await updateExperiment(updated);

    await _debug.info('ExperimentProvider',
      'Completed experiment: ${experiment.title}',
      metadata: {'effectSize': results.effectSize, 'direction': results.direction.name});
  }

  /// Abandon an experiment early
  Future<void> abandonExperiment(String experimentId, {String? reason}) async {
    final experiment = getExperimentById(experimentId);
    if (experiment == null) return;
    if (experiment.status.isFinished) return;

    final notes = experiment.notes.toList();
    if (reason != null) {
      notes.add(ExperimentNote(
        content: 'Abandoned: $reason',
        type: ExperimentNoteType.observation,
      ));
    }

    final updated = experiment.copyWith(
      status: ExperimentStatus.abandoned,
      completedAt: DateTime.now(),
      notes: notes,
    );
    await updateExperiment(updated);

    await _debug.info('ExperimentProvider',
      'Abandoned experiment: ${experiment.title}',
      metadata: {'reason': reason});
  }

  // ==================== ENTRY MANAGEMENT ====================

  /// Add an entry for an experiment
  Future<void> addEntry(ExperimentEntry entry) async {
    _entries.insert(0, entry);
    await _storage.saveExperimentEntries(_entries);
    notifyListeners();

    await _debug.info('ExperimentProvider',
      'Added entry for experiment',
      metadata: {
        'experimentId': entry.experimentId,
        'phase': entry.phase.name,
        'outcomeValue': entry.outcomeValue,
      });
  }

  /// Update an existing entry
  Future<void> updateEntry(ExperimentEntry entry) async {
    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      _entries[index] = entry;
      await _storage.saveExperimentEntries(_entries);
      notifyListeners();
    }
  }

  /// Delete an entry
  Future<void> deleteEntry(String entryId) async {
    _entries.removeWhere((e) => e.id == entryId);
    await _storage.saveExperimentEntries(_entries);
    notifyListeners();
  }

  /// Get all entries for an experiment
  List<ExperimentEntry> getEntriesForExperiment(String experimentId) {
    return _entries
        .where((e) => e.experimentId == experimentId)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date)); // Chronological for analysis
  }

  /// Get baseline entries for an experiment
  List<ExperimentEntry> getBaselineEntries(String experimentId) {
    return getEntriesForExperiment(experimentId)
        .where((e) => e.phase == ExperimentPhase.baseline)
        .toList();
  }

  /// Get intervention entries for an experiment
  List<ExperimentEntry> getInterventionEntries(String experimentId) {
    return getEntriesForExperiment(experimentId)
        .where((e) => e.phase == ExperimentPhase.intervention)
        .toList();
  }

  /// Get entry for a specific date (if exists)
  ExperimentEntry? getEntryForDate(String experimentId, DateTime date) {
    try {
      return _entries.firstWhere((e) =>
          e.experimentId == experimentId &&
          e.date.year == date.year &&
          e.date.month == date.month &&
          e.date.day == date.day);
    } catch (e) {
      return null;
    }
  }

  /// Check if entry exists for today
  bool hasEntryForToday(String experimentId) {
    final today = DateTime.now();
    return getEntryForDate(experimentId, today) != null;
  }

  /// Get complete entries (have both intervention and outcome data)
  List<ExperimentEntry> getCompleteEntries(String experimentId) {
    return getEntriesForExperiment(experimentId)
        .where((e) => e.isComplete)
        .toList();
  }

  // ==================== NOTES MANAGEMENT ====================

  /// Add a note to an experiment
  Future<void> addNote(String experimentId, ExperimentNote note) async {
    final experiment = getExperimentById(experimentId);
    if (experiment == null) return;

    final notes = experiment.notes.toList()..add(note);
    final updated = experiment.copyWith(notes: notes);
    await updateExperiment(updated);
  }

  /// Remove a note from an experiment
  Future<void> removeNote(String experimentId, String noteId) async {
    final experiment = getExperimentById(experimentId);
    if (experiment == null) return;

    final notes = experiment.notes.where((n) => n.id != noteId).toList();
    final updated = experiment.copyWith(notes: notes);
    await updateExperiment(updated);
  }

  // ==================== STATISTICS / HELPERS ====================

  /// Get outcome values for baseline phase
  List<int> getBaselineOutcomes(String experimentId) {
    return getBaselineEntries(experimentId)
        .where((e) => e.outcomeValue != null)
        .map((e) => e.outcomeValue!)
        .toList();
  }

  /// Get outcome values for intervention phase
  List<int> getInterventionOutcomes(String experimentId) {
    return getInterventionEntries(experimentId)
        .where((e) => e.outcomeValue != null)
        .map((e) => e.outcomeValue!)
        .toList();
  }

  /// Check if experiment has enough data for analysis
  bool hasMinimumData(String experimentId) {
    final experiment = getExperimentById(experimentId);
    if (experiment == null) return false;

    final baselineCount = getBaselineOutcomes(experimentId).length;
    final interventionCount = getInterventionOutcomes(experimentId).length;

    return baselineCount >= experiment.minimumDataPoints &&
           interventionCount >= experiment.minimumDataPoints;
  }

  /// Get experiments that need data entry today
  List<Experiment> getExperimentsNeedingEntry() {
    return activeExperiments
        .where((e) => !hasEntryForToday(e.id))
        .toList();
  }

  /// Get experiments linked to a specific goal
  List<Experiment> getExperimentsForGoal(String goalId) {
    return _experiments
        .where((e) => e.linkedGoalId == goalId)
        .toList();
  }

  /// Get experiments linked to a specific habit
  List<Experiment> getExperimentsForHabit(String habitId) {
    return _experiments
        .where((e) => e.linkedHabitId == habitId)
        .toList();
  }
}
