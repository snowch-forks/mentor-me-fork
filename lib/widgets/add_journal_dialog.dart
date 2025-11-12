// lib/widgets/add_journal_dialog.dart
// Quick entry dialog for fast journaling
// Used alongside GuidedJournalingScreen for users who want a quick note

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/journal_entry.dart';
import '../models/goal.dart';
import '../providers/journal_provider.dart';
import '../providers/goal_provider.dart';
import 'package:mentor_me/constants/app_strings.dart';

class AddJournalDialog extends StatefulWidget {
  const AddJournalDialog({super.key});

  @override
  State<AddJournalDialog> createState() => _AddJournalDialogState();
}

class _AddJournalDialogState extends State<AddJournalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final List<String> _selectedGoalIds = [];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goals = context.watch<GoalProvider>().activeGoals;

    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fixed header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_note,
                      color: Theme.of(context).colorScheme.primary,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.quickEntry,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            'Capture thoughts, moments, or progress',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Main text field
                      TextFormField(
                        controller: _contentController,
                        decoration: InputDecoration(
                          labelText: 'What\'s on your mind?',
                          border: const OutlineInputBorder(),
                          hintText: 'Quick wins, challenges, observations, or anything else...',
                          helperText: 'Tip: Mention specific goals, actions, or feelings to track patterns over time',
                          helperMaxLines: 2,
                        ),
                        maxLines: 12,
                        autofocus: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppStrings.pleaseWriteSomething;
                          }
                          return null;
                        },
                      ),

                      // Related goals (optional)
                      if (goals.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Related Goals (Optional)',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: goals.map((goal) {
                            final isSelected = _selectedGoalIds.contains(goal.id);
                            return FilterChip(
                              label: Text(goal.title),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedGoalIds.add(goal.id);
                                  } else {
                                    _selectedGoalIds.remove(goal.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],

                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _saveEntry,
                        icon: const Icon(Icons.check),
                        label: Text('${AppStrings.save} ${AppStrings.journalEntry}'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(height: 24), // Extra padding at bottom
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveEntry() async {
    if (_formKey.currentState!.validate()) {
      final entry = JournalEntry(
        type: JournalEntryType.quickNote,
        content: _contentController.text,
        goalIds: _selectedGoalIds,
      );

      await context.read<JournalProvider>().addEntry(entry);

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.savedSuccessfully)),
      );
    }
  }
}
