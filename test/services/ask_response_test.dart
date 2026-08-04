import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_medic/models/ask_response.dart';
import 'package:pocket_medic/theme/app_tokens.dart';

void main() {
  group('MockAskResponse.fromInput', () {
    test('medical category returns valid response', () {
      final response = MockAskResponse.fromInput(
        category: AskCategory.medical,
        query: 'Minor cut on finger',
        hasImage: false,
      );
      expect(response.urgency, isNotEmpty);
      expect(response.title, isNotEmpty);
      expect(response.summary, isNotEmpty);
      expect(response.steps, isNotEmpty);
      expect(response.disclaimer, isNotEmpty);
    });

    test('food category with mushroom query returns high urgency', () {
      final response = MockAskResponse.fromInput(
        category: AskCategory.food,
        query: 'Can I eat these mushrooms?',
        hasImage: false,
      );
      expect(response.urgency, 'high');
    });

    test('food category with berry query returns high urgency', () {
      final response = MockAskResponse.fromInput(
        category: AskCategory.food,
        query: 'poisonous berry identification',
        hasImage: false,
      );
      expect(response.urgency, 'high');
    });

    test('food category with no risk keywords returns medium urgency', () {
      final response = MockAskResponse.fromInput(
        category: AskCategory.food,
        query: 'What can I forage?',
        hasImage: false,
      );
      expect(response.urgency, 'medium');
    });

    test('water category returns medium urgency', () {
      final response = MockAskResponse.fromInput(
        category: AskCategory.water,
        query: 'Is this stream safe?',
        hasImage: false,
      );
      expect(response.urgency, 'medium');
    });

    test('wildlife category with snake query returns high urgency', () {
      final response = MockAskResponse.fromInput(
        category: AskCategory.wildlife,
        query: 'Snake nearby what should I do',
        hasImage: false,
      );
      expect(response.urgency, 'high');
    });

    test('wildlife category with bear query returns high urgency', () {
      final response = MockAskResponse.fromInput(
        category: AskCategory.wildlife,
        query: 'Bear approaching camp',
        hasImage: false,
      );
      expect(response.urgency, 'high');
    });

    test('wildlife category with non-danger query returns medium urgency', () {
      final response = MockAskResponse.fromInput(
        category: AskCategory.wildlife,
        query: 'How to avoid insects',
        hasImage: false,
      );
      expect(response.urgency, 'medium');
    });

    test('locate category returns medium urgency', () {
      final response = MockAskResponse.fromInput(
        category: AskCategory.locate,
        query: 'Nearest hospital',
        hasImage: false,
      );
      expect(response.urgency, 'medium');
    });

    test('medical heavy bleeding returns high urgency and escalate', () {
      final response = MockAskResponse.fromInput(
        category: AskCategory.medical,
        query: 'Heavy bleeding from wound',
        hasImage: false,
      );
      expect(response.urgency, 'high');
      expect(response.escalate, true);
    });

    test('medical unconscious returns high urgency and escalate', () {
      final response = MockAskResponse.fromInput(
        category: AskCategory.medical,
        query: 'Person is unconscious',
        hasImage: false,
      );
      expect(response.urgency, 'high');
      expect(response.escalate, true);
    });

    test('medical burn with image returns medium urgency', () {
      final response = MockAskResponse.fromInput(
        category: AskCategory.medical,
        query: 'Burn from hot pan',
        hasImage: true,
      );
      expect(response.urgency, 'medium');
      expect(response.escalate, true);
    });

    test('medical minor injury returns low urgency', () {
      final response = MockAskResponse.fromInput(
        category: AskCategory.medical,
        query: 'Small scratch on arm',
        hasImage: false,
      );
      expect(response.urgency, 'low');
      expect(response.escalate, false);
    });

    test('hasImage flag affects food category urgency', () {
      final withImage = MockAskResponse.fromInput(
        category: AskCategory.food,
        query: 'Is this edible?',
        hasImage: true,
      );
      expect(withImage.urgency, 'high');
    });

    test('all categories produce non-empty steps', () {
      for (final cat in AskCategory.values) {
        final response = MockAskResponse.fromInput(
          category: cat,
          query: 'test query',
          hasImage: false,
        );
        expect(response.steps, isNotEmpty);
        expect(response.disclaimer, isNotEmpty);
      }
    });
  });
}