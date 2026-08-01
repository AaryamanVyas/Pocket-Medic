import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';
import '../models/ask_response.dart';
import '../models/history_entry.dart';
import '../services/history_store.dart';
import 'places_screen.dart';

class AskResultScreen extends StatelessWidget {
  final MockAskResponse response;
  final AskCategory category;
  final String inputType;
  final String summary;

  const AskResultScreen({
    super.key,
    required this.response,
    required this.category,
    required this.inputType,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final color = _urgencyColor(response.urgency);
    return Scaffold(
      appBar: AppBar(title: Text('${category.label} result')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppTokens.radius),
                      border: Border.all(color: color.withOpacity(0.35)),
                    ),
                    child: Text(
                      'Urgency: ${response.urgency.toUpperCase()}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    response.title,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: AppTokens.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    response.summary,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      color: AppTokens.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  response.escalate
                      ? _alert(
                          icon: Icons.warning_amber_outlined,
                          text: response.escalateText,
                          color: const Color(0xFFB91C1C),
                        )
                      : _alert(
                          icon: Icons.check_circle_outline,
                          text: response.escalateText,
                          color: AppTokens.accent,
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recommended steps',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      color: AppTokens.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < response.steps.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${i + 1}. ${response.steps[i]}',
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
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                response.disclaimer,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  color: AppTokens.text,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppTokens.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radius),
                ),
              ),
              onPressed: () async {
                await HistoryStore.add(
                  HistoryEntry(
                    id: DateTime.now().millisecondsSinceEpoch,
                    timestamp: DateTime.now(),
                    inputType: inputType,
                    category: category.label,
                    urgency: response.urgency,
                    summary: summary,
                  ),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Saved to local history.')),
                  );
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Save to History'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTokens.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radius),
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PlacesLocatorScreen()),
                );
              },
              icon: const Icon(Icons.place_outlined),
              label: const Text('Open Places (town / hospital / water)'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _alert({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _urgencyColor(String urgency) {
    switch (urgency) {
      case 'low':
        return const Color(0xFF15803D);
      case 'medium':
        return const Color(0xFFB45309);
      default:
        return const Color(0xFFB91C1C);
    }
  }
}
