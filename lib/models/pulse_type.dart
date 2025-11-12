import 'package:uuid/uuid.dart';

/// Represents a configurable pulse check type that users can create and manage
class PulseType {
  final String id;
  final String name;
  final String iconName; // Store icon name (e.g., 'mood', 'bolt')
  final String colorHex; // Store color as hex string (e.g., "FF5252")
  final bool isActive;
  final int order; // For sorting in UI
  final DateTime createdAt;
  final DateTime? updatedAt;

  PulseType({
    String? id,
    required this.name,
    required this.iconName,
    required this.colorHex,
    this.isActive = true,
    this.order = 0,
    DateTime? createdAt,
    this.updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconName': iconName,
      'colorHex': colorHex,
      'isActive': isActive,
      'order': order,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory PulseType.fromJson(Map<String, dynamic> json) {
    // Support backward compatibility with old 'iconCodePoint' field
    String iconName = json['iconName'] as String? ?? 'mood';
    if (json['iconCodePoint'] != null && json['iconName'] == null) {
      // Old format - try to map code point to name (best effort)
      // For simplicity, just use default
      iconName = 'mood';
    }

    return PulseType(
      id: json['id'],
      name: json['name'],
      iconName: iconName,
      colorHex: json['colorHex'],
      isActive: json['isActive'] ?? true,
      order: json['order'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  PulseType copyWith({
    String? name,
    String? iconName,
    String? colorHex,
    bool? isActive,
    int? order,
    DateTime? updatedAt,
  }) {
    return PulseType(
      id: id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Returns default pulse types for new users
  static List<PulseType> getDefaults() {
    return [
      PulseType(
        name: 'Mood',
        iconName: 'mood',
        colorHex: 'FFE91E63', // Pink
        order: 1,
      ),
      PulseType(
        name: 'Energy',
        iconName: 'bolt',
        colorHex: 'FFFFB300', // Amber
        order: 2,
      ),
      PulseType(
        name: 'Wellness',
        iconName: 'favorite',
        colorHex: 'FF2196F3', // Blue
        order: 3,
      ),
    ];
  }
}
