import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';
import '../services/ai_service.dart';
import 'ask_screen.dart';
import 'places_screen.dart';
import 'emergency_screen.dart';
import 'field_guides.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  AskCategory? _preselect;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        onOpenAsk: (category) {
          setState(() {
            _preselect = category;
            _index = 1;
          });
        },
        onOpenPlaces: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PlacesLocatorScreen()),
          );
        },
        onOpenEmergency: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const EmergencyScreen()),
          );
        },
      ),
      AskScreen(initialCategory: _preselect),
      const FieldGuidesScreen(),
      const HistoryScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() {
            _index = value;
            if (value != 1) _preselect = null;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Ask'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Guides'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  final void Function(AskCategory category) onOpenAsk;
  final VoidCallback onOpenPlaces;
  final VoidCallback onOpenEmergency;

  const DashboardScreen({
    super.key,
    required this.onOpenAsk,
    required this.onOpenPlaces,
    required this.onOpenEmergency,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          const Text(
            'Pocket Medic',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w700,
              fontSize: 28,
              color: AppTokens.text,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Offline field assistant — medical, food, water, wildlife, and places.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: AppTokens.text,
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.wifi_off, color: AppTokens.accent),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Offline Mode Active: guidance runs on-device with no network.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppTokens.text,
                      ),
                    ),
                  ),
                ],
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
              onPressed: () => onOpenAsk(AskCategory.medical),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text(
                'Ask anything offline',
                style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    style: _outlineStyle(),
                    onPressed: onOpenEmergency,
                    icon: const Icon(Icons.call, color: AppTokens.text),
                    label: const Text(
                      'Emergency',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        color: AppTokens.text,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    style: _outlineStyle(),
                    onPressed: onOpenPlaces,
                    icon: const Icon(Icons.place_outlined, color: AppTokens.text),
                    label: const Text(
                      'Places',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        color: AppTokens.text,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'What do you need?',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppTokens.text,
            ),
          ),
          const SizedBox(height: 8),
          for (final c in AskCategory.values) ...[
            _categoryCard(c),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 16),
          const Text(
            'Model status',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppTokens.text,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AiService.isReady
                  ? const Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: AppTokens.accent),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Model ready for on-device field guidance',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              color: AppTokens.text,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Loading AI model...',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            color: AppTokens.text,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const LinearProgressIndicator(
                          minHeight: 6,
                          color: AppTokens.accent,
                          backgroundColor: AppTokens.border,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Place gemma-4-E2B-it.litertlm in Downloads folder',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            color: AppTokens.text.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _categoryCard(AskCategory category) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.radius),
        onTap: () => onOpenAsk(category),
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(category.icon, color: AppTokens.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.label,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        color: AppTokens.text,
                      ),
                    ),
                    Text(
                      category.shortHint,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: AppTokens.text,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTokens.text),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }

  ButtonStyle _outlineStyle() {
    return OutlinedButton.styleFrom(
      side: const BorderSide(color: AppTokens.border, width: 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radius),
      ),
    );
  }
}
