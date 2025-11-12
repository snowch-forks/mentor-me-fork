import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mentor_me/constants/app_strings.dart';
import '../models/milestone.dart';
import '../providers/goal_provider.dart';

class AddMilestoneDialog extends StatefulWidget {
  final String goalId;
  
  const AddMilestoneDialog({super.key, required this.goalId});

  @override
  State<AddMilestoneDialog> createState() => _AddMilestoneDialogState();
}

class _AddMilestoneDialogState extends State<AddMilestoneDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _targetDate;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  AppStrings.addMilestone,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: AppStrings.milestoneTitle,
                    border: OutlineInputBorder(),
                    hintText: AppStrings.milestoneTitleHint,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppStrings.pleaseEnterTitle;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: AppStrings.description,
                    border: OutlineInputBorder(),
                    hintText: AppStrings.whatMilestoneInvolves,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(AppStrings.targetDateOptional),
                  subtitle: Text(
                    _targetDate != null
                        ? '${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year}'
                        : AppStrings.noTargetDateSet,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_targetDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _targetDate = null;
                            });
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _targetDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 3650)),
                          );
                          if (date != null) {
                            setState(() {
                              _targetDate = date;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(AppStrings.cancel),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _saveMilestone,
                      child: const Text(AppStrings.addMilestone),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveMilestone() async {
    if (_formKey.currentState!.validate()) {
      final goalProvider = context.read<GoalProvider>();
      final goal = goalProvider.getGoalById(widget.goalId);
      
      if (goal != null) {
        final nextOrder = goal.milestonesDetailed.isEmpty 
            ? 0 
            : goal.milestonesDetailed.map((m) => m.order).reduce((a, b) => a > b ? a : b) + 1;

        final milestone = Milestone(
          goalId: widget.goalId,
          title: _titleController.text,
          description: _descriptionController.text,
          targetDate: _targetDate,
          order: nextOrder,
        );
        
        await goalProvider.addMilestone(widget.goalId, milestone);
        
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.milestoneAdded)),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
