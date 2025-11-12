// lib/utils/icon_mapper.dart
// Maps icon names to const IconData instances for tree-shaking compatibility

import 'package:flutter/material.dart';

class IconMapper {
  // Map of icon names to const IconData instances
  static const Map<String, IconData> _iconMap = {
    'mood': Icons.mood,
    'favorite': Icons.favorite,
    'bolt': Icons.bolt,
    'local_fire_department': Icons.local_fire_department,
    'water_drop': Icons.water_drop,
    'spa': Icons.spa,
    'self_improvement': Icons.self_improvement,
    'psychology': Icons.psychology,
    'fitness_center': Icons.fitness_center,
    'bedtime': Icons.bedtime,
    'restaurant': Icons.restaurant,
    'work': Icons.work,
    'school': Icons.school,
    'family_restroom': Icons.family_restroom,
    'groups': Icons.groups,
    'favorite_border': Icons.favorite_border,
    'healing': Icons.healing,
    'monitor_heart': Icons.monitor_heart,
  };

  /// Get IconData from icon name
  static IconData getIcon(String iconName) {
    return _iconMap[iconName] ?? Icons.mood; // Default to mood if not found
  }

  /// Get all available icons for selection
  static List<MapEntry<String, IconData>> get availableIcons {
    return _iconMap.entries.toList();
  }
}
