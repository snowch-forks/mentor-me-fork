// lib/screens/profile_settings_screen.dart
// Screen for managing user profile settings

import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../theme/app_spacing.dart';
import '../constants/app_strings.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _storage = StorageService();
  final _nameController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    final settings = await _storage.loadSettings();
    final name = settings['userName'] as String?;

    if (name != null) {
      _userName = name;
      _nameController.text = name;
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveName() async {
    final newName = _nameController.text.trim();

    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.pleaseEnterYourName),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newName == _userName) {
      // No change
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Save to storage
      final settings = await _storage.loadSettings();
      settings['userName'] = newName;
      await _storage.saveSettings(settings);

      setState(() {
        _userName = newName;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.nameUpdatedSuccessfully),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profile),
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
                    Icons.person,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  AppSpacing.gapHorizontalMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Profile',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        AppSpacing.gapSm,
                        Text(
                          'Manage your personal information and preferences.',
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

          // Name Section
          Text(
            AppStrings.yourName,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          AppSpacing.gapMd,
          Text(
            'This name is used throughout the app to personalize your experience',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
          AppSpacing.gapLg,

          // Name input field
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: AppStrings.yourName,
              hintText: 'Enter your first name',
              prefixIcon: Icon(Icons.badge),
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (_) {
              // Auto-save on change with debounce could be added here
            },
          ),

          AppSpacing.gapLg,

          // Save button
          FilledButton.icon(
            onPressed: _isSaving ? null : _saveName,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(_isSaving ? '${AppStrings.save}...' : AppStrings.saveChanges),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              minimumSize: const Size(double.infinity, 56),
            ),
          ),

          AppSpacing.gapXl,

          const Divider(),

          AppSpacing.gapXl,

          // Future settings placeholder
          Text(
            'Additional Settings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          AppSpacing.gapMd,
          Container(
            padding: AppSpacing.paddingMd,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: AppRadius.radiusMd,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                AppSpacing.gapHorizontalMd,
                Expanded(
                  child: Text(
                    'More profile settings (email, photo, preferences) can be added here in the future.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
