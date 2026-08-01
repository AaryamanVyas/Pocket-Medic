import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

class FieldGuidesScreen extends StatelessWidget {
  const FieldGuidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Field Guides',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w700,
              fontSize: 24,
              color: AppTokens.text,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Offline checklists for survival and first aid.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              color: AppTokens.text,
            ),
          ),
          const SizedBox(height: 16),
          _guide('Food safety', [
            'Never eat unknown mushrooms or berries with milky sap.',
            'If unsure, do not taste — ask the app with a photo.',
            'Avoid plants with white berries or almond-like scent in crushed leaves.',
          ]),
          _guide('Finding water', [
            'Follow downhill terrain and animal trails toward moisture.',
            'Prefer flowing water over stagnant pools when possible.',
            'Boil or filter before drinking whenever you can.',
          ]),
          _guide('Wildlife avoidance', [
            'Make noise while walking in dense cover.',
            'Store food away from sleeping area; never cook in tent.',
            'Back away slowly from snakes; do not try to handle them.',
          ]),
          _guide('Getting to help', [
            'Note landmarks and keep moving toward lower elevation / roads.',
            'Use cached places list for nearest town or clinic.',
            'Conserve daylight; mark your path when possible.',
          ]),
          _guide('Cuts and bleeding', [
            'Apply clean direct pressure for 10 minutes.',
            'Raise injured area above heart if possible.',
            'If bleeding is heavy or not stopping, seek emergency help.',
          ]),
          _guide('Burns', [
            'Cool under running water for 20 minutes.',
            'Do not apply ice, oils, or toothpaste.',
            'Cover with sterile non-stick dressing.',
          ]),
        ],
      ),
    );
  }

  Widget _guide(String title, List<String> points) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppTokens.text,
                ),
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < points.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${i + 1}. ${points[i]}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      color: AppTokens.text,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
