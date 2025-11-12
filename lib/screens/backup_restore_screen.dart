// lib/screens/backup_restore_screen.dart
// Screen for managing data backup and restore operations

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../services/backup_service.dart';
import '../providers/goal_provider.dart';
import '../providers/journal_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/checkin_provider.dart';
import '../providers/pulse_provider.dart';
import '../providers/pulse_type_provider.dart';
import '../providers/chat_provider.dart';
import '../theme/app_spacing.dart';
import '../theme/app_colors.dart';
import '../constants/app_strings.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  final _backupService = BackupService();
  bool _isExporting = false;
  bool _isImporting = false;

  Future<void> _exportBackup() async {
    setState(() => _isExporting = true);

    try {
      final result = await _backupService.exportBackup();

      if (!mounted) return;

      if (result.success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // If we have a file path (Android/mobile), show it in a dialog
        if (result.filePath != null) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 12),
                  Text(AppStrings.backupSaved),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(AppStrings.yourBackupSavedTo),
                  AppSpacing.gapMd,
                  Container(
                    padding: AppSpacing.paddingMd,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: AppRadius.radiusMd,
                    ),
                    child: SelectableText(
                      result.filePath!,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(AppStrings.ok),
                ),
              ],
            ),
          );
        }
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.exportFailed}: ${result.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _importBackup() async {
    setState(() => _isImporting = true);

    try {
      final result = await _backupService.importBackup();

      if (!mounted) return;

      if (result.success) {
        // Reload all providers with imported data
        await _reloadAllProviders();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.green,
          ),
        );

        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 12),
                Text(AppStrings.importSuccessful),
              ],
            ),
            content: const Text(
              AppStrings.dataRestoredFromBackup,
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Return to settings
                },
                child: const Text(AppStrings.ok),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.importFailed}: ${result.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  Future<void> _reloadAllProviders() async {
    // Reload all providers to refresh UI with imported data
    if (mounted) {
      await Future.wait([
        context.read<GoalProvider>().reload(),
        context.read<JournalProvider>().reload(),
        context.read<HabitProvider>().reload(),
        context.read<CheckinProvider>().reload(),
        context.read<PulseProvider>().reload(),
        context.read<PulseTypeProvider>().reload(),
        context.read<ChatProvider>().reload(),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.backupAndRestore),
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          // Header info
          Card(
            child: Padding(
              padding: AppSpacing.paddingLg,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  AppSpacing.gapHorizontalMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.aboutBackups,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        AppSpacing.gapSm,
                        Text(
                          AppStrings.backupsDescription,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          AppSpacing.gapXl,

          // Export Section
          Text(
            AppStrings.exportData,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          AppSpacing.gapMd,
          Text(
            AppStrings.saveCopyOfData,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
          AppSpacing.gapLg,

          FilledButton.tonalIcon(
            onPressed: _isExporting || _isImporting ? null : _exportBackup,
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload),
            label: Text(_isExporting ? AppStrings.exporting : AppStrings.exportAllData),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              minimumSize: const Size(double.infinity, 56),
            ),
          ),

          AppSpacing.gapXl,

          const Divider(),

          AppSpacing.gapXl,

          // Import Section
          Text(
            AppStrings.importData,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          AppSpacing.gapMd,
          Text(
            AppStrings.restoreFromBackup,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
          AppSpacing.gapLg,

          OutlinedButton.icon(
            onPressed: _isExporting || _isImporting ? null : _importBackup,
            icon: _isImporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            label: Text(_isImporting ? AppStrings.importing : AppStrings.importFromBackup),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              minimumSize: const Size(double.infinity, 56),
            ),
          ),

          AppSpacing.gapLg,

          // Warning card
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: AppSpacing.paddingMd,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Colors.orange.shade700,
                  ),
                  AppSpacing.gapHorizontalMd,
                  Expanded(
                    child: Text(
                      AppStrings.importingBackupWarning,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange.shade900,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
