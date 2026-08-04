import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_medic/models/history_entry.dart';

void main() {
  group('HistoryEntry round-trip', () {
    test('toMap and fromMap preserve all fields', () {
      final entry = HistoryEntry(
        id: 42,
        timestamp: DateTime(2026, 3, 15, 14, 30, 0),
        inputType: 'image',
        category: 'Medical',
        urgency: 'high',
        summary: 'Test entry',
      );
      final map = entry.toMap();
      final restored = HistoryEntry.fromMap(map);
      expect(restored.id, entry.id);
      expect(restored.timestamp, entry.timestamp);
      expect(restored.inputType, entry.inputType);
      expect(restored.category, entry.category);
      expect(restored.urgency, entry.urgency);
      expect(restored.summary, entry.summary);
    });

    test('toMap produces correct types', () {
      final entry = HistoryEntry(
        id: 1,
        timestamp: DateTime(2026, 1, 1),
        inputType: 'text',
        category: 'Food',
        urgency: 'low',
        summary: 'Ate something safe',
      );
      final map = entry.toMap();
      expect(map['id'], isA<int>());
      expect(map['timestamp'], isA<int>());
      expect(map['inputType'], isA<String>());
      expect(map['category'], isA<String>());
      expect(map['urgency'], isA<String>());
      expect(map['summary'], isA<String>());
    });

    test('fromMap handles different urgency values', () {
      for (final urgency in ['low', 'medium', 'high']) {
        final entry = HistoryEntry(
          id: 1,
          timestamp: DateTime.now(),
          inputType: 'text',
          category: 'Medical',
          urgency: urgency,
          summary: 'Test',
        );
        final map = entry.toMap();
        final restored = HistoryEntry.fromMap(map);
        expect(restored.urgency, urgency);
      }
    });

    test('fromMap handles empty summary', () {
      final entry = HistoryEntry(
        id: 1,
        timestamp: DateTime.now(),
        inputType: 'text',
        category: 'Medical',
        urgency: 'low',
        summary: '',
      );
      final map = entry.toMap();
      final restored = HistoryEntry.fromMap(map);
      expect(restored.summary, '');
    });
  });
}