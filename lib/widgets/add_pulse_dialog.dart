// lib/widgets/add_pulse_dialog.dart
// Quick pulse check dialog - fast mood/energy logging without journaling

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pulse_entry.dart';
import '../models/pulse_type.dart';
import '../providers/pulse_provider.dart';
import '../providers/pulse_type_provider.dart';
import '../utils/icon_mapper.dart';
import '../constants/app_strings.dart';

class AddPulseDialog extends StatefulWidget {
  const AddPulseDialog({super.key});

  @override
  State<AddPulseDialog> createState() => _AddPulseDialogState();
}

class _AddPulseDialogState extends State<AddPulseDialog> {
  // Store pulse type values: pulse type name -> value (1-5)
  final Map<String, int> _pulseValues = {};

  bool get _canSave => _pulseValues.values.any((value) => value > 0);

  @override
  Widget build(BuildContext context) {
    final pulseTypeProvider = context.watch<PulseTypeProvider>();
    final activePulseTypes = pulseTypeProvider.activeTypes;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 500,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Icon(
                    Icons.favorite,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pulse Check',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          'How are you feeling right now?',
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

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Show loading state
                    if (pulseTypeProvider.isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    // Show message if no pulse types configured
                    else if (activePulseTypes.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No pulse types configured',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Configure pulse types in Settings',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[500],
                                    ),
                              ),
                            ],
                          ),
                        ),
                      )
                    // Show pulse type selectors
                    else
                      ...activePulseTypes.asMap().entries.map((entry) {
                        final index = entry.key;
                        final pulseType = entry.value;
                        final isLast = index == activePulseTypes.length - 1;

                        return Column(
                          children: [
                            _buildPulseTypeSelector(pulseType),
                            if (!isLast) const SizedBox(height: 20),
                          ],
                        );
                      }),

                    if (activePulseTypes.isNotEmpty) ...[
                      const SizedBox(height: 20),

                      // Save Button
                      FilledButton.icon(
                        onPressed: _canSave ? _savePulse : null,
                        icon: const Icon(Icons.check),
                        label: const Text(AppStrings.save),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),

                      // Helper text
                      if (!_canSave) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Select at least one pulse value',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPulseTypeSelector(PulseType pulseType) {
    final color = Color(int.parse('0x${pulseType.colorHex}'));
    final icon = IconMapper.getIcon(pulseType.iconName);
    final currentValue = _pulseValues[pulseType.name] ?? 0;

    // All types use 1-5 numeric scale
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type name with icon
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              pulseType.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 1-5 numeric scale selector
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                final level = index + 1;
                final isSelected = currentValue == level;
                return GestureDetector(
                  onTap: () => setState(() => _pulseValues[pulseType.name] = level),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withOpacity(0.2)
                          : Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? color : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        level.toString(),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? color : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 4),
            Text(
              currentValue == 0 ? 'Tap to select' : 'Level $currentValue/5',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: currentValue == 0 ? Colors.grey : color,
                    fontWeight: currentValue > 0 ? FontWeight.w600 : null,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _savePulse() async {
    // Create custom metrics map with only set values
    final customMetrics = Map<String, int>.from(
      _pulseValues.entries.where((entry) => entry.value > 0).fold({}, (map, entry) {
        map[entry.key] = entry.value;
        return map;
      }),
    );

    final pulseEntry = PulseEntry(
      customMetrics: customMetrics,
    );

    await context.read<PulseProvider>().addEntry(pulseEntry);

    if (!mounted) return;

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text('Pulse check logged!'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
