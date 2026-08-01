import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_medic/models/ask_response.dart';
import 'package:pocket_medic/models/history_entry.dart';
import 'package:pocket_medic/theme/app_tokens.dart';

void main() {
  test('AskCategory labels', () {
    expect(AskCategory.medical.label, 'Medical');
    expect(AskCategory.food.label, 'Food');
    expect(AskCategory.water.label, 'Water');
    expect(AskCategory.wildlife.label, 'Wildlife');
    expect(AskCategory.locate.label, 'Locate');
  });

  test('MockAskResponse creates valid response for medical', () {
    final response = MockAskResponse.fromInput(
      category: AskCategory.medical,
      query: 'Deep cut on palm, steady bleeding',
      hasImage: false,
    );

    expect(response.urgency, isNotEmpty);
    expect(response.title, isNotEmpty);
    expect(response.summary, isNotEmpty);
    expect(response.steps, isNotEmpty);
    expect(response.disclaimer, isNotEmpty);
  });

  test('MockAskResponse detects high urgency for heavy bleeding', () {
    final response = MockAskResponse.fromInput(
      category: AskCategory.medical,
      query: 'Heavy bleeding from wound',
      hasImage: false,
    );

    expect(response.urgency, 'high');
    expect(response.escalate, true);
  });

  test('MockAskResponse detects high urgency for mushroom', () {
    final response = MockAskResponse.fromInput(
      category: AskCategory.food,
      query: 'Can I eat these mushrooms?',
      hasImage: false,
    );

    expect(response.urgency, 'high');
  });

  test('HistoryEntry toMap and fromMap', () {
    final entry = HistoryEntry(
      id: 123,
      timestamp: DateTime(2026, 1, 15, 10, 30),
      inputType: 'text',
      category: 'Medical',
      urgency: 'low',
      summary: 'Test entry',
    );

    final map = entry.toMap();
    final restored = HistoryEntry.fromMap(map);

    expect(restored.id, entry.id);
    expect(restored.category, entry.category);
    expect(restored.urgency, entry.urgency);
    expect(restored.summary, entry.summary);
  });
}
