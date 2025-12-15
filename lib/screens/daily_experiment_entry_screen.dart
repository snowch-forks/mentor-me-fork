// lib/screens/daily_experiment_entry_screen.dart
// Screen for logging daily experiment data

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/experiment.dart';
import '../models/experiment_entry.dart';
import '../providers/experiment_provider.dart';
import '../theme/app_spacing.dart';

class DailyExperimentEntryScreen extends StatefulWidget {
  final String experimentId;
  final DateTime? date; // If null, defaults to today

  const DailyExperimentEntryScreen({
    super.key,
    required this.experimentId,
    this.date,
  });

  @override
  State<DailyExperimentEntryScreen> createState() =>
      _DailyExperimentEntryScreenState();
}

class _DailyExperimentEntryScreenState extends State<DailyExperimentEntryScreen> {
  late DateTime _selectedDate;
  int? _outcomeValue;
  bool? _interventionApplied;
  int? _interventionIntensity;
  bool _hasConfoundingFactors = false;
  final _notesController = TextEditingController();

  ExperimentEntry? _existingEntry;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.date ?? DateTime.now();
    _loadExistingEntry();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _loadExistingEntry() {
    final provider = context.read<ExperimentProvider>();
    final entry = provider.getEntryForDate(widget.experimentId, _selectedDate);

    if (entry != null) {
      setState(() {
        _existingEntry = entry;
        _isEditing = true;
        _outcomeValue = entry.outcomeValue;
        _interventionApplied = entry.interventionApplied;
        _interventionIntensity = entry.interventionIntensity;
        _hasConfoundingFactors = entry.hasConfoundingFactors;
        _notesController.text = entry.notes ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<ExperimentProvider>();
    final experiment = provider.getExperimentById(widget.experimentId);

    if (experiment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Log Entry')),
        body: const Center(child: Text('Experiment not found')),
      );
    }

    final isIntervention = experiment.status == ExperimentStatus.active;
    final currentPhase = isIntervention
        ? ExperimentPhase.intervention
        : ExperimentPhase.baseline;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Entry' : 'Log Entry'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context),
              tooltip: 'Delete Entry',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date selector
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(_formatDate(_selectedDate)),
                subtitle: Text(currentPhase.displayName),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _selectDate(context),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Outcome rating
            Text(
              'How was your ${experiment.outcomeName} today?',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Rate from 1 (lowest) to 5 (highest)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _RatingSelector(
              value: _outcomeValue,
              onChanged: (value) => setState(() => _outcomeValue = value),
              label: experiment.outcomeName,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Intervention tracking (only in active phase)
            if (isIntervention) ...[
              Text(
                'Did you do "${experiment.interventionName}" today?',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _SelectionButton(
                      label: 'Yes',
                      icon: Icons.check_circle,
                      isSelected: _interventionApplied == true,
                      color: Colors.green,
                      onTap: () => setState(() => _interventionApplied = true),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _SelectionButton(
                      label: 'No',
                      icon: Icons.cancel,
                      isSelected: _interventionApplied == false,
                      color: Colors.red,
                      onTap: () => setState(() => _interventionApplied = false),
                    ),
                  ),
                ],
              ),
              if (_interventionApplied == true) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Intensity (optional)',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                _RatingSelector(
                  value: _interventionIntensity,
                  onChanged: (value) =>
                      setState(() => _interventionIntensity = value),
                  label: 'Intensity',
                  lowLabel: 'Light',
                  highLabel: 'Intense',
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
            ],

            // Confounding factors
            Card(
              child: CheckboxListTile(
                title: const Text('External factors'),
                subtitle: const Text(
                  'Something unusual happened today that might affect results',
                ),
                value: _hasConfoundingFactors,
                onChanged: (value) =>
                    setState(() => _hasConfoundingFactors = value ?? false),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Notes
            Text(
              'Notes (optional)',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'Any observations about today...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _canSave() ? () => _saveEntry(context, experiment) : null,
                icon: Icon(_isEditing ? Icons.save : Icons.check),
                label: Text(_isEditing ? 'Update Entry' : 'Save Entry'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  bool _canSave() {
    // Must have outcome rating
    if (_outcomeValue == null) return false;

    // In intervention phase, must indicate if intervention was done
    final provider = context.read<ExperimentProvider>();
    final experiment = provider.getExperimentById(widget.experimentId);
    if (experiment?.status == ExperimentStatus.active &&
        _interventionApplied == null) {
      return false;
    }

    return true;
  }

  Future<void> _selectDate(BuildContext context) async {
    final provider = context.read<ExperimentProvider>();
    final experiment = provider.getExperimentById(widget.experimentId);
    if (experiment == null) return;

    final firstDate = experiment.startedAt ?? experiment.createdAt;
    final lastDate = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // Reset form and check for existing entry
        _outcomeValue = null;
        _interventionApplied = null;
        _interventionIntensity = null;
        _hasConfoundingFactors = false;
        _notesController.clear();
        _existingEntry = null;
        _isEditing = false;
      });
      _loadExistingEntry();
    }
  }

  Future<void> _saveEntry(BuildContext context, Experiment experiment) async {
    final provider = context.read<ExperimentProvider>();

    final currentPhase = experiment.status == ExperimentStatus.active
        ? ExperimentPhase.intervention
        : ExperimentPhase.baseline;

    final entry = ExperimentEntry(
      id: _existingEntry?.id,
      experimentId: widget.experimentId,
      date: _selectedDate,
      phase: currentPhase,
      outcomeValue: _outcomeValue,
      outcomeTime: DateTime.now(),
      interventionApplied: _interventionApplied,
      interventionIntensity: _interventionIntensity,
      hasConfoundingFactors: _hasConfoundingFactors,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    if (_isEditing) {
      await provider.updateEntry(entry);
    } else {
      await provider.addEntry(entry);
    }

    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Entry updated' : 'Entry saved'),
        ),
      );
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (_existingEntry != null) {
                await context
                    .read<ExperimentProvider>()
                    .deleteEntry(_existingEntry!.id);
              }
              if (context.mounted) {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDate = DateTime(date.year, date.month, date.day);

    if (entryDate == today) return 'Today';
    if (entryDate == today.subtract(const Duration(days: 1))) return 'Yesterday';

    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _RatingSelector extends StatelessWidget {
  final int? value;
  final ValueChanged<int> onChanged;
  final String label;
  final String lowLabel;
  final String highLabel;

  const _RatingSelector({
    required this.value,
    required this.onChanged,
    required this.label,
    this.lowLabel = 'Low',
    this.highLabel = 'High',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              lowLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              highLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: List.generate(5, (index) {
            final rating = index + 1;
            final isSelected = value == rating;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 0 : 4,
                  right: index == 4 ? 0 : 4,
                ),
                child: Material(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => onChanged(rating),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 56,
                      alignment: Alignment.center,
                      child: Text(
                        '$rating',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _SelectionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _SelectionButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected ? color.withOpacity(0.2) : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? color : theme.colorScheme.outline,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? color : theme.colorScheme.onSurfaceVariant,
                size: 32,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: isSelected ? color : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
