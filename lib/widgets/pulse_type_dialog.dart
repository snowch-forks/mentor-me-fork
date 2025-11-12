// lib/widgets/pulse_type_dialog.dart
// Dialog for adding or editing pulse check types

import 'package:flutter/material.dart';
import '../models/pulse_type.dart';
import '../utils/icon_mapper.dart';
import '../constants/app_strings.dart';

class PulseTypeDialog extends StatefulWidget {
  final PulseType? existingType;

  const PulseTypeDialog({super.key, this.existingType});

  @override
  State<PulseTypeDialog> createState() => _PulseTypeDialogState();
}

class _PulseTypeDialogState extends State<PulseTypeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  late String _selectedIconName;
  late Color _selectedColor;

  // Get available icons from mapper
  late final List<MapEntry<String, IconData>> _availableIcons;

  // Common colors for pulse types
  final List<Color> _availableColors = [
    const Color(0xFFE91E63), // Pink
    const Color(0xFF2196F3), // Blue
    const Color(0xFFFFB300), // Amber
    const Color(0xFF4CAF50), // Green
    const Color(0xFF9C27B0), // Purple
    const Color(0xFFFF5722), // Deep Orange
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFF8BC34A), // Light Green
    const Color(0xFFFF9800), // Orange
    const Color(0xFF3F51B5), // Indigo
    const Color(0xFFE91E63), // Pink
    const Color(0xFF607D8B), // Blue Grey
  ];

  @override
  void initState() {
    super.initState();

    _availableIcons = IconMapper.availableIcons;

    if (widget.existingType != null) {
      _nameController.text = widget.existingType!.name;
      _selectedIconName = widget.existingType!.iconName;
      _selectedColor = Color(
        int.parse(widget.existingType!.colorHex, radix: 16),
      );
    } else {
      _selectedIconName = 'mood';
      _selectedColor = const Color(0xFF2196F3);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingType != null;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    isEditing ? 'Edit Pulse Type' : 'Add Pulse Type',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),

                  // Name field
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., Mood, Energy, Focus',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 24),

                  // Icon selector
                  Text(
                    'Icon',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: _availableIcons.length,
                      itemBuilder: (context, index) {
                        final iconEntry = _availableIcons[index];
                        final iconName = iconEntry.key;
                        final icon = iconEntry.value;
                        final isSelected = iconName == _selectedIconName;

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedIconName = iconName;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primaryContainer
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              icon,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey.shade700,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Color selector
                  Text(
                    'Color',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _availableColors.map((color) {
                      final isSelected = color.value == _selectedColor.value;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedColor = color;
                          });
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.black : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Preview
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Preview:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _selectedColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                IconMapper.getIcon(_selectedIconName),
                                color: _selectedColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _nameController.text.isEmpty
                                    ? 'Type Name'
                                    : _nameController.text,
                                style: TextStyle(
                                  color: _selectedColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(AppStrings.cancel),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _savePulseType,
                        child: Text(isEditing ? AppStrings.saveChanges : 'Add Type'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _savePulseType() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final pulseType = PulseType(
      id: widget.existingType?.id,
      name: _nameController.text.trim(),
      iconName: _selectedIconName,
      colorHex: _selectedColor.value.toRadixString(16).toUpperCase(),
      isActive: widget.existingType?.isActive ?? true,
      order: widget.existingType?.order ?? 0,
      createdAt: widget.existingType?.createdAt,
    );

    Navigator.pop(context, pulseType);
  }
}
