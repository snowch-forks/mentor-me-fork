// test/providers/pulse_type_provider_test.dart
// Unit tests for PulseTypeProvider

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mentor_me/providers/pulse_type_provider.dart';
import 'package:mentor_me/models/pulse_type.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PulseTypeProvider', () {
    late PulseTypeProvider provider;

    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      provider = PulseTypeProvider();
      // Wait for initial load to complete
      await Future.delayed(const Duration(milliseconds: 100));
    });

    group('Initialization', () {
      test('should initialize with default types if storage is empty', () {
        expect(provider.types, isNotEmpty);
        expect(provider.types.length, 3); // Mood, Energy, Wellness
        expect(provider.types.map((t) => t.name), containsAll(['Mood', 'Energy', 'Wellness']));
      });

      test('should load types from storage on init', () async {
        // Setup: Add custom types to storage
        SharedPreferences.setMockInitialValues({
          'pulse_types': '[{"id":"1","name":"Focus","iconName":"visibility","colorHex":"FF4CAF50","isActive":true,"order":1,"createdAt":"2025-01-01T00:00:00.000Z"}]'
        });

        // Create new provider (loads from storage)
        final newProvider = PulseTypeProvider();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(newProvider.types.length, 1);
        expect(newProvider.types.first.name, 'Focus');
      });

      test('should handle corrupted storage data gracefully', () async {
        SharedPreferences.setMockInitialValues({
          'pulse_types': 'invalid json'
        });

        final newProvider = PulseTypeProvider();
        await Future.delayed(const Duration(milliseconds: 100));

        // Should fall back to defaults
        expect(newProvider.types.length, 3);
      });

      test('should sort types by order field', () {
        final types = provider.types;
        for (int i = 0; i < types.length - 1; i++) {
          expect(types[i].order, lessThanOrEqualTo(types[i + 1].order));
        }
      });

      test('should not be loading after initialization', () async {
        await Future.delayed(const Duration(milliseconds: 100));
        expect(provider.isLoading, isFalse);
      });
    });

    group('Add Type', () {
      test('should add a new pulse type', () async {
        final initialCount = provider.types.length;

        final newType = PulseType(
          name: 'Focus',
          iconName: 'visibility',
          colorHex: 'FF4CAF50',
          order: 10,
        );

        await provider.addType(newType);

        expect(provider.types.length, initialCount + 1);
        expect(provider.types.any((t) => t.name == 'Focus'), isTrue);
      });

      test('should generate unique ID for each type', () async {
        final type1 = PulseType(
          name: 'Type 1',
          iconName: 'star',
          colorHex: 'FF000000',
        );
        final type2 = PulseType(
          name: 'Type 2',
          iconName: 'favorite',
          colorHex: 'FFFFFFFF',
        );

        await provider.addType(type1);
        await provider.addType(type2);

        final ids = provider.types.map((t) => t.id).toSet();
        expect(ids.length, provider.types.length); // All unique
      });

      test('should maintain sort order after adding', () async {
        final newType = PulseType(
          name: 'Focus',
          iconName: 'visibility',
          colorHex: 'FF4CAF50',
          order: 2, // Insert in middle
        );

        await provider.addType(newType);

        final types = provider.types;
        for (int i = 0; i < types.length - 1; i++) {
          expect(types[i].order, lessThanOrEqualTo(types[i + 1].order));
        }
      });

      test('should notify listeners when type added', () async {
        var notified = false;
        provider.addListener(() => notified = true);

        final newType = PulseType(
          name: 'Focus',
          iconName: 'visibility',
          colorHex: 'FF4CAF50',
        );
        await provider.addType(newType);

        expect(notified, isTrue);
      });

      test('should persist type to storage', () async {
        final newType = PulseType(
          name: 'Custom Type',
          iconName: 'star',
          colorHex: 'FFFF0000',
        );

        await provider.addType(newType);

        // Create new provider to verify persistence
        final newProvider = PulseTypeProvider();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(newProvider.types.any((t) => t.name == 'Custom Type'), isTrue);
      });
    });

    group('Update Type', () {
      late PulseType existingType;

      setUp(() {
        existingType = provider.types.first;
      });

      test('should update existing type', () async {
        final updatedType = existingType.copyWith(
          name: 'Updated Mood',
          colorHex: 'FF000000',
        );

        await provider.updateType(updatedType);

        final found = provider.types.firstWhere((t) => t.id == existingType.id);
        expect(found.name, 'Updated Mood');
        expect(found.colorHex, 'FF000000');
      });

      test('should not add new type if ID does not exist', () async {
        final initialCount = provider.types.length;

        final nonExistentType = PulseType(
          id: 'non-existent-id',
          name: 'Test',
          iconName: 'star',
          colorHex: 'FF000000',
        );

        await provider.updateType(nonExistentType);

        expect(provider.types.length, initialCount);
      });

      test('should maintain sort order after updating', () async {
        final updatedType = existingType.copyWith(
          order: 100, // Move to end
        );

        await provider.updateType(updatedType);

        final types = provider.types;
        for (int i = 0; i < types.length - 1; i++) {
          expect(types[i].order, lessThanOrEqualTo(types[i + 1].order));
        }
      });

      test('should notify listeners when type updated', () async {
        var notifiedCount = 0;
        provider.addListener(() => notifiedCount++);

        final updatedType = existingType.copyWith(name: 'Updated');
        await provider.updateType(updatedType);

        expect(notifiedCount, 1);
      });

      test('should update updatedAt timestamp', () async {
        final beforeUpdate = DateTime.now();

        final updatedType = existingType.copyWith(name: 'Updated');
        await provider.updateType(updatedType);

        final found = provider.types.firstWhere((t) => t.id == existingType.id);
        expect(found.updatedAt, isNotNull);
        expect(found.updatedAt!.isAfter(beforeUpdate.subtract(const Duration(seconds: 1))), isTrue);
      });
    });

    group('Deactivate Type', () {
      late PulseType existingType;

      setUp(() {
        existingType = provider.types.first;
      });

      test('should deactivate (soft delete) a type', () async {
        expect(existingType.isActive, isTrue);

        await provider.deactivateType(existingType.id);

        final found = provider.types.firstWhere((t) => t.id == existingType.id);
        expect(found.isActive, isFalse);
      });

      test('should not remove deactivated type from list', () async {
        final initialCount = provider.types.length;

        await provider.deactivateType(existingType.id);

        expect(provider.types.length, initialCount);
      });

      test('should exclude deactivated types from activeTypes', () async {
        await provider.deactivateType(existingType.id);

        expect(provider.activeTypes.any((t) => t.id == existingType.id), isFalse);
      });

      test('should notify listeners when type deactivated', () async {
        var notified = false;
        provider.addListener(() => notified = true);

        await provider.deactivateType(existingType.id);

        expect(notified, isTrue);
      });

      test('should handle deactivating non-existent type', () async {
        final initialCount = provider.types.length;

        await provider.deactivateType('non-existent-id');

        expect(provider.types.length, initialCount);
      });
    });

    group('Activate Type', () {
      late PulseType deactivatedType;

      setUp(() async {
        deactivatedType = provider.types.first;
        await provider.deactivateType(deactivatedType.id);
      });

      test('should reactivate a deactivated type', () async {
        expect(provider.getTypeById(deactivatedType.id)!.isActive, isFalse);

        await provider.activateType(deactivatedType.id);

        final found = provider.types.firstWhere((t) => t.id == deactivatedType.id);
        expect(found.isActive, isTrue);
      });

      test('should include reactivated type in activeTypes', () async {
        await provider.activateType(deactivatedType.id);

        expect(provider.activeTypes.any((t) => t.id == deactivatedType.id), isTrue);
      });

      test('should notify listeners when type activated', () async {
        var notifiedCount = 0;
        provider.addListener(() => notifiedCount++);

        await provider.activateType(deactivatedType.id);

        expect(notifiedCount, 1);
      });

      test('should handle activating non-existent type', () async {
        final initialCount = provider.types.length;

        await provider.activateType('non-existent-id');

        expect(provider.types.length, initialCount);
      });
    });

    group('Delete Type', () {
      late PulseType existingType;

      setUp(() {
        existingType = provider.types.first;
      });

      test('should permanently delete a type', () async {
        final initialCount = provider.types.length;

        await provider.deleteType(existingType.id);

        expect(provider.types.length, initialCount - 1);
        expect(provider.types.any((t) => t.id == existingType.id), isFalse);
      });

      test('should handle deleting non-existent type', () async {
        final initialCount = provider.types.length;

        await provider.deleteType('non-existent-id');

        expect(provider.types.length, initialCount);
      });

      test('should notify listeners when type deleted', () async {
        var notified = false;
        provider.addListener(() => notified = true);

        await provider.deleteType(existingType.id);

        expect(notified, isTrue);
      });

      test('should persist deletion to storage', () async {
        final typeId = existingType.id;
        await provider.deleteType(typeId);

        // Create new provider to verify persistence
        final newProvider = PulseTypeProvider();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(newProvider.types.any((t) => t.id == typeId), isFalse);
      });
    });

    group('Reorder Types', () {
      test('should reorder types from lower to higher index', () async {
        final initialOrder = provider.types.map((t) => t.name).toList();

        // Move first item to last position
        await provider.reorderTypes(0, provider.types.length);

        final newOrder = provider.types.map((t) => t.name).toList();
        expect(newOrder[0], isNot(initialOrder[0]));
        expect(newOrder.last, initialOrder[0]);
      });

      test('should reorder types from higher to lower index', () async {
        final initialOrder = provider.types.map((t) => t.name).toList();

        // Move last item to first position
        await provider.reorderTypes(provider.types.length - 1, 0);

        final newOrder = provider.types.map((t) => t.name).toList();
        expect(newOrder[0], initialOrder.last);
      });

      test('should update order field for all types after reordering', () async {
        await provider.reorderTypes(0, 2);

        final types = provider.types;
        for (int i = 0; i < types.length; i++) {
          expect(types[i].order, i + 1); // Order should be 1-indexed
        }
      });

      test('should notify listeners when types reordered', () async {
        var notified = false;
        provider.addListener(() => notified = true);

        await provider.reorderTypes(0, 1);

        expect(notified, isTrue);
      });

      test('should persist reorder to storage', () async {
        await provider.reorderTypes(0, 2);
        final newOrder = provider.types.map((t) => t.name).toList();

        // Create new provider to verify persistence
        final newProvider = PulseTypeProvider();
        await Future.delayed(const Duration(milliseconds: 100));

        final persistedOrder = newProvider.types.map((t) => t.name).toList();
        expect(persistedOrder, equals(newOrder));
      });
    });

    group('Get Type By ID', () {
      test('should return type if ID exists', () {
        final existingType = provider.types.first;

        final found = provider.getTypeById(existingType.id);

        expect(found, isNotNull);
        expect(found!.id, existingType.id);
        expect(found.name, existingType.name);
      });

      test('should return null if ID does not exist', () {
        final found = provider.getTypeById('non-existent-id');

        expect(found, isNull);
      });
    });

    group('Active Types', () {
      test('should return only active types', () async {
        final type1 = provider.types[0];
        await provider.deactivateType(type1.id);

        final activeTypes = provider.activeTypes;

        expect(activeTypes.every((t) => t.isActive), isTrue);
        expect(activeTypes.any((t) => t.id == type1.id), isFalse);
      });

      test('should return empty list if all types are deactivated', () async {
        for (final type in provider.types) {
          await provider.deactivateType(type.id);
        }

        expect(provider.activeTypes, isEmpty);
      });
    });

    group('Reload', () {
      test('should reload types from storage', () async {
        // Add a type
        final newType = PulseType(
          name: 'Custom',
          iconName: 'star',
          colorHex: 'FF000000',
        );
        await provider.addType(newType);

        // Modify storage directly
        SharedPreferences.setMockInitialValues({
          'pulse_types': '[{"id":"reloaded-id","name":"Reloaded","iconName":"refresh","colorHex":"FFFFFFFF","isActive":true,"order":1,"createdAt":"2025-01-01T00:00:00.000Z"}]'
        });

        await provider.reload();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(provider.types.length, 1);
        expect(provider.types.first.name, 'Reloaded');
      });

      test('should initialize with defaults if storage is empty after reload', () async {
        // Clear storage
        SharedPreferences.setMockInitialValues({});

        await provider.reload();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(provider.types.length, 3); // Default types
      });
    });

    group('Edge Cases', () {
      test('should handle multiple rapid adds', () async {
        final initialCount = provider.types.length;
        final futures = List.generate(10, (i) {
          return provider.addType(PulseType(
            name: 'Type $i',
            iconName: 'star',
            colorHex: 'FF000000',
            order: i + 100,
          ));
        });

        await Future.wait(futures);

        expect(provider.types.length, initialCount + 10);
      });

      test('should handle type with all fields populated', () async {
        final type = PulseType(
          name: 'Complete Type',
          iconName: 'favorite',
          colorHex: 'FFFF5722',
          isActive: true,
          order: 5,
          updatedAt: DateTime.now(),
        );

        await provider.addType(type);

        final found = provider.types.firstWhere((t) => t.name == 'Complete Type');
        expect(found.name, 'Complete Type');
        expect(found.iconName, 'favorite');
        expect(found.colorHex, 'FFFF5722');
        expect(found.isActive, isTrue);
        expect(found.order, 5);
      });

      test('should preserve all type fields during update', () async {
        final type = PulseType(
          name: 'Original',
          iconName: 'mood',
          colorHex: 'FF2196F3',
          order: 10,
        );
        await provider.addType(type);

        final updatedType = type.copyWith(name: 'Updated');
        await provider.updateType(updatedType);

        final found = provider.getTypeById(type.id);
        expect(found!.name, 'Updated');
        expect(found.iconName, 'mood'); // Preserved
        expect(found.colorHex, 'FF2196F3'); // Preserved
        expect(found.order, 10); // Preserved
      });

      test('should handle reordering with single item', () async {
        // Delete all but one type
        while (provider.types.length > 1) {
          await provider.deleteType(provider.types.last.id);
        }

        // Try to reorder single item
        await provider.reorderTypes(0, 0);

        expect(provider.types.length, 1);
      });

      test('should handle deactivate and reactivate cycle', () async {
        final type = provider.types.first;

        // Deactivate
        await provider.deactivateType(type.id);
        expect(provider.getTypeById(type.id)!.isActive, isFalse);

        // Reactivate
        await provider.activateType(type.id);
        expect(provider.getTypeById(type.id)!.isActive, isTrue);

        // Deactivate again
        await provider.deactivateType(type.id);
        expect(provider.getTypeById(type.id)!.isActive, isFalse);
      });
    });
  });
}
