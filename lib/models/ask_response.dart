import '../theme/app_tokens.dart';

class MockAskResponse {
  final String urgency;
  final String title;
  final String summary;
  final List<String> steps;
  final bool escalate;
  final String escalateText;
  final String disclaimer;

  const MockAskResponse({
    required this.urgency,
    required this.title,
    required this.summary,
    required this.steps,
    required this.escalate,
    required this.escalateText,
    required this.disclaimer,
  });

  factory MockAskResponse.fromInput({
    required AskCategory category,
    required String query,
    required bool hasImage,
  }) {
    final q = query.toLowerCase();
    const disclaimer =
        'Offline guidance only. Not a substitute for professionals. If unsure, escalate and stay safe.';

    switch (category) {
      case AskCategory.food:
        return MockAskResponse(
          urgency: (q.contains('mushroom') || q.contains('berry') || hasImage)
              ? 'high'
              : 'medium',
          title: 'Edibility check (conservative)',
          summary:
              'Without expert confirmation, treat unknown plants as unsafe. When uncertain, do not eat.',
          steps: const [
            'Do not taste unknown plants, berries, or mushrooms.',
            'Capture clear photos of leaf, stem, fruit, and nearby habitat.',
            'Prefer known packaged food over foraging when available.',
            'If already ingested and symptoms appear, stop eating and seek help.',
          ],
          escalate: true,
          escalateText: 'If identification is uncertain, treat as not edible.',
          disclaimer: disclaimer,
        );
      case AskCategory.water:
        return const MockAskResponse(
          urgency: 'medium',
          title: 'Water source guidance',
          summary:
              'Prioritize flowing sources downhill, then purify. Stagnant water is higher risk.',
          steps: [
            'Move downhill and follow animal trails / green vegetation.',
            'Prefer clear flowing streams over stagnant ponds.',
            'Boil for at least 1 minute (longer at high altitude) if possible.',
            'If you cannot boil, use a filter/purifier tablet and still avoid cloudy water.',
          ],
          escalate: false,
          escalateText: 'Purify before drinking whenever possible.',
          disclaimer: disclaimer,
        );
      case AskCategory.wildlife:
        return MockAskResponse(
          urgency: (q.contains('snake') || q.contains('bear') || q.contains('attack'))
              ? 'high'
              : 'medium',
          title: 'Wildlife safety tips',
          summary:
              'Avoid surprise encounters, give animals space, and never handle wildlife.',
          steps: const [
            'Stop, stay calm, and give the animal an escape route.',
            'Back away slowly; do not run or turn your back abruptly.',
            'Make noise while traveling in dense cover.',
            'Keep food sealed and away from sleeping areas.',
          ],
          escalate: q.contains('bite') || q.contains('attack'),
          escalateText: q.contains('bite') || q.contains('attack')
              ? 'Possible dangerous encounter — seek medical help urgently.'
              : 'Avoid contact and leave the area calmly.',
          disclaimer: disclaimer,
        );
      case AskCategory.locate:
        return const MockAskResponse(
          urgency: 'medium',
          title: 'Nearest help & settlement (stub)',
          summary:
              'Use cached offline places for hospitals, towns, and known water points.',
          steps: [
            'Open Places for nearest hospital / town / water stubs.',
            'Move toward roads, lower elevation, or visible settlement lights.',
            'Conserve energy and daylight; mark your path.',
            'If injured, prioritize shelter and signaling over long travel.',
          ],
          escalate: false,
          escalateText: 'Use cached Places list for offline navigation stubs.',
          disclaimer: disclaimer,
        );
      case AskCategory.medical:
        if (q.contains('heavy bleeding') ||
            q.contains('unconscious') ||
            q.contains('severe chest pain')) {
          return const MockAskResponse(
            urgency: 'high',
            title: 'Potential critical condition',
            summary: 'Urgent medical signs detected in the description.',
            steps: [
              'Call emergency services immediately if available.',
              'Keep the person still and monitor breathing.',
              'Apply direct pressure to bleeding with a clean cloth.',
              'Do not give food or drink.',
            ],
            escalate: true,
            escalateText: 'Seek professional help now.',
            disclaimer: disclaimer,
          );
        }
        if (q.contains('burn') || hasImage) {
          return const MockAskResponse(
            urgency: 'medium',
            title: 'Possible burn / skin injury',
            summary: 'Conservative first-aid steps while you get to safer care.',
            steps: [
              'Cool with running water for 20 minutes.',
              'Remove rings/tight items near the area if safe.',
              'Cover with sterile non-stick gauze.',
              'Avoid ice, oils, or toothpaste on the burn.',
            ],
            escalate: true,
            escalateText: 'Seek care if blistering, large area, or face/hands involved.',
            disclaimer: disclaimer,
          );
        }
        return const MockAskResponse(
          urgency: 'low',
          title: 'Minor soft tissue injury',
          summary: 'Basic first-aid and monitoring guidance.',
          steps: [
            'Clean gently with clean water.',
            'Use antiseptic if available.',
            'Apply bandage and watch for swelling/infection.',
            'Rest and re-check in a few hours.',
          ],
          escalate: false,
          escalateText: 'Home care may be enough — keep monitoring.',
          disclaimer: disclaimer,
        );
    }
  }
}
