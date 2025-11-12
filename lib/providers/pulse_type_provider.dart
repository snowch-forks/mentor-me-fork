// lib/providers/pulse_type_provider.dart
// Manages user-configurable pulse check types

import 'package:flutter/foundation.dart';
import '../models/pulse_type.dart';
import '../services/storage_service.dart';

class PulseTypeProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  List<PulseType> _types = [];
  bool _isLoading = false;

  List<PulseType> get types => _types;
  List<PulseType> get activeTypes => _types.where((t) => t.isActive).toList();
  bool get isLoading => _isLoading;

  PulseTypeProvider() {
    _loadTypes();
  }

  /// Reload types from storage (useful after import/restore)
  Future<void> reload() async {
    await _loadTypes();
  }

  Future<void> _loadTypes() async {
    _isLoading = true;
    notifyListeners();

    _types = await _storage.loadPulseTypes();

    // If no types exist, initialize with defaults
    if (_types.isEmpty) {
      _types = PulseType.getDefaults();
      await _storage.savePulseTypes(_types);
    }

    // Sort by order
    _types.sort((a, b) => a.order.compareTo(b.order));

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addType(PulseType type) async {
    _types.add(type);
    _types.sort((a, b) => a.order.compareTo(b.order));
    await _storage.savePulseTypes(_types);
    notifyListeners();
  }

  Future<void> updateType(PulseType updatedType) async {
    final index = _types.indexWhere((t) => t.id == updatedType.id);
    if (index != -1) {
      _types[index] = updatedType;
      _types.sort((a, b) => a.order.compareTo(b.order));
      await _storage.savePulseTypes(_types);
      notifyListeners();
    }
  }

  /// Deactivate a pulse type (soft delete)
  Future<void> deactivateType(String typeId) async {
    final index = _types.indexWhere((t) => t.id == typeId);
    if (index != -1) {
      _types[index] = _types[index].copyWith(
        isActive: false,
        updatedAt: DateTime.now(),
      );
      await _storage.savePulseTypes(_types);
      notifyListeners();
    }
  }

  /// Reactivate a pulse type
  Future<void> activateType(String typeId) async {
    final index = _types.indexWhere((t) => t.id == typeId);
    if (index != -1) {
      _types[index] = _types[index].copyWith(
        isActive: true,
        updatedAt: DateTime.now(),
      );
      await _storage.savePulseTypes(_types);
      notifyListeners();
    }
  }

  /// Permanently delete a pulse type
  Future<void> deleteType(String typeId) async {
    _types.removeWhere((t) => t.id == typeId);
    await _storage.savePulseTypes(_types);
    notifyListeners();
  }

  /// Reorder pulse types
  Future<void> reorderTypes(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final type = _types.removeAt(oldIndex);
    _types.insert(newIndex, type);

    // Update order field for all types
    for (int i = 0; i < _types.length; i++) {
      _types[i] = _types[i].copyWith(order: i + 1);
    }

    await _storage.savePulseTypes(_types);
    notifyListeners();
  }

  /// Get a specific pulse type by ID
  PulseType? getTypeById(String id) {
    try {
      return _types.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }
}
