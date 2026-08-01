import 'package:flutter/material.dart';

class AppTokens {
  static const surface = Color(0xFFF8FAFC);
  static const text = Color(0xFF0F172A);
  static const accent = Color(0xFF0F766E);
  static const warning = Color(0xFFD97706);
  static const border = Color(0xFFF1F5F9);
  static const radius = 16.0;

  static const heading = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontWeight: FontWeight.w700,
    color: text,
  );
  static const title = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontWeight: FontWeight.w600,
    color: text,
  );
  static const body = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    color: text,
  );
  static const bodyRegular = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    color: text,
  );
}

enum AskCategory {
  medical,
  food,
  water,
  wildlife,
  locate,
}

extension AskCategoryX on AskCategory {
  String get label {
    switch (this) {
      case AskCategory.medical:
        return 'Medical';
      case AskCategory.food:
        return 'Food';
      case AskCategory.water:
        return 'Water';
      case AskCategory.wildlife:
        return 'Wildlife';
      case AskCategory.locate:
        return 'Locate';
    }
  }

  String get shortHint {
    switch (this) {
      case AskCategory.medical:
        return 'Injury / first aid';
      case AskCategory.food:
        return 'Is this edible?';
      case AskCategory.water:
        return 'Find water nearby';
      case AskCategory.wildlife:
        return 'Animals & safety';
      case AskCategory.locate:
        return 'Town / hospital';
    }
  }

  IconData get icon {
    switch (this) {
      case AskCategory.medical:
        return Icons.medical_services_outlined;
      case AskCategory.food:
        return Icons.eco_outlined;
      case AskCategory.water:
        return Icons.water_drop_outlined;
      case AskCategory.wildlife:
        return Icons.pets_outlined;
      case AskCategory.locate:
        return Icons.place_outlined;
    }
  }

  List<String> get samplePrompts {
    switch (this) {
      case AskCategory.medical:
        return [
          'Deep cut on palm, steady bleeding',
          'Minor burn from hot pan',
          'Ankle twist with swelling',
        ];
      case AskCategory.food:
        return [
          'Is this berry edible?',
          'Can I eat these mushrooms?',
          'Is this plant safe to forage?',
        ];
      case AskCategory.water:
        return [
          'How do I find a water source nearby?',
          'Is this stream water safe?',
          'How to purify cloudy water offline?',
        ];
      case AskCategory.wildlife:
        return [
          'Snake nearby — what should I do?',
          'How to avoid attracting bears?',
          'Animal tracks near camp — tips?',
        ];
      case AskCategory.locate:
        return [
          'Nearest hospital from here',
          'Nearest town or city',
          'Safe route toward settlement',
        ];
    }
  }
}
