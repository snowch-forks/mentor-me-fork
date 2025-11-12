// lib/screens/pulse_type_management_screen.dart
// Manage pulse check types - add, edit, activate/deactivate

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pulse_type_provider.dart';
import '../models/pulse_type.dart';
import '../widgets/pulse_type_dialog.dart';
import '../utils/icon_mapper.dart';
import '../theme/app_spacing.dart';
import '../constants/app_strings.dart';

class PulseTypeManagementScreen extends StatelessWidget {
  const PulseTypeManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pulse Check Types'),
      ),
      body: Consumer<PulseTypeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.types.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    ),
                    AppSpacing.gapLg,
                    Text(
                      'No Pulse Types',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    AppSpacing.gapMd,
                    Text(
                      'Create custom types to track different aspects of your wellness',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                      textAlign: TextAlign.center,
                    ),
                    AppSpacing.gapXl,
                    FilledButton.icon(
                      onPressed: () => _addPulseType(context, provider),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Pulse Type'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              // Info banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    AppSpacing.gapHorizontalMd,
                    Expanded(
                      child: Text(
                        'Manage the types of pulse checks you can track',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),

              // List of pulse types
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: provider.types.length,
                  itemBuilder: (context, index) {
                    final type = provider.types[index];
                    final icon = IconMapper.getIcon(type.iconName);
                    final color = Color(
                      int.parse(type.colorHex, radix: 16),
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: color, size: 24),
                        ),
                        title: Text(
                          type.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: type.isActive
                                ? null
                                : Theme.of(context).disabledColor,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            Icon(
                              type.isActive ? Icons.check_circle : Icons.cancel,
                              size: 14,
                              color: type.isActive ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              type.isActive ? AppStrings.active : 'Inactive',
                              style: TextStyle(
                                fontSize: 12,
                                color: type.isActive
                                    ? Colors.green
                                    : Theme.of(context).disabledColor,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _editPulseType(context, provider, type),
                              tooltip: AppStrings.edit,
                            ),
                            IconButton(
                              icon: Icon(
                                type.isActive
                                    ? Icons.toggle_on
                                    : Icons.toggle_off,
                                size: 32,
                              ),
                              onPressed: () => _togglePulseType(context, provider, type),
                              tooltip: type.isActive ? 'Deactivate' : 'Activate',
                              color: type.isActive
                                  ? Colors.green
                                  : Theme.of(context).disabledColor,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Add button at bottom
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: FilledButton.icon(
                    onPressed: () => _addPulseType(context, provider),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Pulse Type'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addPulseType(BuildContext context, PulseTypeProvider provider) async {
    final result = await showDialog<PulseType>(
      context: context,
      builder: (context) => const PulseTypeDialog(),
    );

    if (result != null && context.mounted) {
      final newType = result.copyWith(
        order: provider.types.length + 1,
      );
      await provider.addType(newType);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.name} type added'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _editPulseType(
    BuildContext context,
    PulseTypeProvider provider,
    PulseType type,
  ) async {
    final result = await showDialog<PulseType>(
      context: context,
      builder: (context) => PulseTypeDialog(existingType: type),
    );

    if (result != null && context.mounted) {
      await provider.updateType(result);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.name} type updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _togglePulseType(
    BuildContext context,
    PulseTypeProvider provider,
    PulseType type,
  ) async {
    if (type.isActive) {
      await provider.deactivateType(type.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${type.name} type deactivated'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      await provider.activateType(type.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${type.name} type activated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
