import 'package:flutter/material.dart';

void main() {
  runApp(const PocketMedicApp());
}

class PocketMedicApp extends StatelessWidget {
  const PocketMedicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pocket Medic',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D9488)),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final List<Widget> _pages = const [
    DashboardScreen(),
    TriageInputScreen(),
    FirstAidGuidesScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.medical_services_outlined), label: 'Triage'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Guides'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Pocket Medic',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Offline first-aid triage assistant',
            style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: const Color(0xFFECFDF5),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.wifi_off, color: Color(0xFF047857)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Offline Mode Active: No internet required in this demo flow.',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TriageInputStandalone()),
                    );
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Start Triage'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EmergencyScreen()),
                    );
                  },
                  icon: const Icon(Icons.call),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Emergency Actions'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HospitalLocatorScreen()),
                    );
                  },
                  icon: const Icon(Icons.place_outlined),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Hospitals'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Today quick actions',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 10),
          _tile(
            icon: Icons.bloodtype_outlined,
            title: 'Bleeding control',
            subtitle: 'Pressure, elevation, seek help signals',
          ),
          _tile(
            icon: Icons.local_fire_department_outlined,
            title: 'Burn first aid',
            subtitle: 'Cool water, cover, when to escalate',
          ),
          _tile(
            icon: Icons.sports_handball_outlined,
            title: 'Sprain care',
            subtitle: 'Rest, ice, compression, elevation',
          ),
        ],
      ),
    );
  }

  Widget _tile({required IconData icon, required String title, required String subtitle}) {
    return Card(
      elevation: 0,
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF0F766E)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class TriageInputScreen extends StatelessWidget {
  const TriageInputScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(child: TriageFormBody(embedInShell: true));
  }
}

class TriageInputStandalone extends StatelessWidget {
  const TriageInputStandalone({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Run Triage')),
      body: const SafeArea(child: TriageFormBody(embedInShell: false)),
    );
  }
}

class TriageFormBody extends StatefulWidget {
  final bool embedInShell;
  const TriageFormBody({super.key, required this.embedInShell});

  @override
  State<TriageFormBody> createState() => _TriageFormBodyState();
}

class _TriageFormBodyState extends State<TriageFormBody> {
  final TextEditingController _symptomController = TextEditingController();
  bool _hasImage = false;
  bool _isAnalyzing = false;

  @override
  void dispose() {
    _symptomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.embedInShell) ...[
          const Text(
            'AI Triage',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
        ],
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Describe symptom', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                TextField(
                  controller: _symptomController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Example: deep cut on palm with steady bleeding.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _sampleChip('Minor burn from hot pan'),
                    _sampleChip('Heavy bleeding after deep cut'),
                    _sampleChip('Ankle twist with swelling'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Image input', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_hasImage ? Icons.image : Icons.camera_alt_outlined,
                            size: 34, color: const Color(0xFF475569)),
                        const SizedBox(height: 8),
                        Text(_hasImage ? 'Mock image attached' : 'No image selected'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _hasImage = !_hasImage),
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: Text(_hasImage ? 'Remove image' : 'Attach mock image'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: const Color(0xFFF1F5F9),
          child: ListTile(
            leading: const Icon(Icons.mic_none_outlined),
            title: const Text('Voice input (UI stub)'),
            subtitle: const Text('Local speech-to-text will be connected later'),
            trailing: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Voice capture is mocked for now.')),
                );
              },
              child: const Text('Try'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _isAnalyzing ? null : _runMockTriage,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: _isAnalyzing
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Text('Analyzing offline...'),
                    ],
                  )
                : const Text('Run Offline Triage'),
          ),
        ),
      ],
    );
  }

  Future<void> _runMockTriage() async {
    final symptom = _symptomController.text.trim().isEmpty
        ? 'Minor burn on left hand while cooking'
        : _symptomController.text.trim();
    setState(() => _isAnalyzing = true);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    final response = MockTriageResponse.fromInput(symptom: symptom, hasImage: _hasImage);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TriageResultScreen(
          response: response,
          inputType: _hasImage ? 'image' : 'text',
          summary: symptom.length <= 65 ? symptom : '${symptom.substring(0, 65)}...',
        ),
      ),
    );
    setState(() => _isAnalyzing = false);
  }

  Widget _sampleChip(String text) {
    return ActionChip(label: Text(text), onPressed: () => _symptomController.text = text);
  }
}

class TriageResultScreen extends StatelessWidget {
  final MockTriageResponse response;
  final String inputType;
  final String summary;

  const TriageResultScreen({
    super.key,
    required this.response,
    required this.inputType,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(response.severity);
    return Scaffold(
      appBar: AppBar(title: const Text('Triage Result')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Severity: ${response.severity.toUpperCase()}',
                      style: TextStyle(color: color, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(response.likelyIssue,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  response.seekHelp
                      ? _alertBox(
                          bg: const Color(0xFFB91C1C).withOpacity(0.12),
                          border: const Color(0xFFB91C1C).withOpacity(0.35),
                          icon: Icons.warning_amber_outlined,
                          text: 'Seek professional help now (urgent signs detected).',
                          textColor: const Color(0xFF991B1B),
                        )
                      : _alertBox(
                          bg: const Color(0xFF0F766E).withOpacity(0.12),
                          border: const Color(0xFF0F766E).withOpacity(0.35),
                          icon: Icons.check_circle_outline,
                          text: 'Home care may be sufficient. Keep monitoring.',
                          textColor: const Color(0xFF0F766E),
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Immediate steps', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  for (var i = 0; i < response.steps.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('${i + 1}. ${response.steps[i]}'),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            color: const Color(0xFFFFF7ED),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                response.disclaimer,
                style: const TextStyle(color: Color(0xFF9A3412), fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              MockSymptomHistoryStore.add(
                HistoryEntry(
                  id: DateTime.now().millisecondsSinceEpoch,
                  timestamp: DateTime.now(),
                  inputType: inputType,
                  severity: response.severity,
                  summary: summary,
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Saved to local symptom history.')),
              );
            },
            icon: const Icon(Icons.save),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Save to History'),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HospitalLocatorScreen()),
              );
            },
            icon: const Icon(Icons.place_outlined),
            label: const Text('Find Hospital (Stub)'),
          ),
        ],
      ),
    );
  }

  Widget _alertBox({
    required Color bg,
    required Color border,
    required IconData icon,
    required String text,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'mild':
        return const Color(0xFF15803D);
      case 'moderate':
        return const Color(0xFFB45309);
      default:
        return const Color(0xFFB91C1C);
    }
  }
}

class FirstAidGuidesScreen extends StatelessWidget {
  const FirstAidGuidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('First-Aid Guides',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text(
            'Offline static guides for common situations.',
            style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _guideCard('Cuts and bleeding', [
            'Apply clean direct pressure for 10 minutes.',
            'Raise injured area above heart if possible.',
            'If bleeding is heavy or not stopping, seek emergency help.',
          ]),
          _guideCard('Burns', [
            'Cool burn under running water for 20 minutes.',
            'Do not apply ice or toothpaste.',
            'Cover with sterile, non-stick dressing.',
          ]),
          _guideCard('Sprain', [
            'Rest the injured area.',
            'Apply ice packs in short intervals.',
            'Use compression and elevation.',
          ]),
          _guideCard('Fever', [
            'Hydrate and rest.',
            'Monitor temperature every few hours.',
            'Escalate if persistent high fever or confusion.',
          ]),
        ],
      ),
    );
  }

  Widget _guideCard(String title, List<String> points) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            for (var i = 0; i < points.length; i++) Text('${i + 1}. ${points[i]}'),
          ],
        ),
      ),
    );
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String? _filter;

  @override
  Widget build(BuildContext context) {
    final all = MockSymptomHistoryStore.entries;
    final items =
        _filter == null ? all : all.where((e) => e.severity == _filter).toList(growable: false);

    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Symptom History',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Wrap(
              spacing: 8,
              children: [
                _chip('All', null),
                _chip('Mild', 'mild'),
                _chip('Moderate', 'moderate'),
                _chip('Emergency', 'emergency'),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('No entries yet. Save from Triage result page.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (_, index) {
                      final e = items[index];
                      final color = _severityColor(e.severity);
                      return Card(
                        elevation: 0,
                        child: ListTile(
                          title: Text(e.summary, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(
                              '${e.inputType} input • ${e.timestamp.hour.toString().padLeft(2, '0')}:${e.timestamp.minute.toString().padLeft(2, '0')}'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              e.severity.toUpperCase(),
                              style: TextStyle(color: color, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (all.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: OutlinedButton.icon(
                onPressed: () {
                  MockSymptomHistoryStore.clear();
                  setState(() => _filter = null);
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Clear History'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(String label, String? value) {
    return ActionChip(
      label: Text(label),
      backgroundColor: _filter == value ? const Color(0xFF99F6E4) : null,
      onPressed: () => setState(() => _filter = value),
    );
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'mild':
        return const Color(0xFF15803D);
      case 'moderate':
        return const Color(0xFFB45309);
      default:
        return const Color(0xFFB91C1C);
    }
  }
}

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Actions')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _emergencyTile(
            context,
            icon: Icons.call,
            title: 'Call Emergency Helpline',
            subtitle: 'Tap to simulate emergency call action',
          ),
          _emergencyTile(
            context,
            icon: Icons.local_hospital_outlined,
            title: 'Nearest Hospital (Stub)',
            subtitle: 'Uses offline cached map in final version',
          ),
          _emergencyTile(
            context,
            icon: Icons.sms_outlined,
            title: 'Alert Emergency Contact',
            subtitle: 'Share location and symptom summary (planned)',
          ),
        ],
      ),
    );
  }

  Widget _emergencyTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      elevation: 0,
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFB91C1C)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title tapped (UI stub).')),
          );
        },
      ),
    );
  }
}

class HospitalLocatorScreen extends StatelessWidget {
  const HospitalLocatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline Hospital Locator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('UI Stub for Round 1',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  SizedBox(height: 8),
                  Text(
                    'This screen will use cached hospital data and location on-device in the full build.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          ...const [
            _HospitalCard(name: 'City Civil Hospital', distance: '2.1 km', eta: '8 min'),
            _HospitalCard(name: 'General Trauma Center', distance: '4.5 km', eta: '14 min'),
            _HospitalCard(name: 'Community Health Clinic', distance: '6.2 km', eta: '20 min'),
          ],
        ],
      ),
    );
  }
}

class _HospitalCard extends StatelessWidget {
  final String name;
  final String distance;
  final String eta;

  const _HospitalCard({
    required this.name,
    required this.distance,
    required this.eta,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: ListTile(
        leading: const Icon(Icons.local_hospital, color: Color(0xFF0F766E)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text('Distance: $distance • ETA: $eta'),
        trailing: TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Directions are mocked in this demo.')),
            );
          },
          child: const Text('Route'),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Card(
            elevation: 0,
            child: SwitchListTile(
              value: true,
              onChanged: (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Offline lock is always ON in demo mode.')),
                );
              },
              title: const Text('Offline-only mode'),
              subtitle: const Text('Blocks network use in final app architecture'),
            ),
          ),
          Card(
            elevation: 0,
            child: ListTile(
              leading: const Icon(Icons.language_outlined),
              title: const Text('Language'),
              subtitle: const Text('English (multi-language planned)'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Language selector planned.')),
                );
              },
            ),
          ),
          Card(
            elevation: 0,
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Safety disclaimer'),
              subtitle: const Text('Always shown in triage results'),
              onTap: () {
                showDialog<void>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Safety Notice'),
                    content: const Text(
                      'Pocket Medic provides first-aid guidance only. It is not a substitute for professional medical care.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EmergencyScreen()),
              );
            },
            icon: const Icon(Icons.sos),
            label: const Text('Open Emergency Actions'),
          ),
        ],
      ),
    );
  }
}

class MockTriageResponse {
  final String severity;
  final String likelyIssue;
  final List<String> steps;
  final bool seekHelp;
  final String disclaimer;

  const MockTriageResponse({
    required this.severity,
    required this.likelyIssue,
    required this.steps,
    required this.seekHelp,
    required this.disclaimer,
  });

  factory MockTriageResponse.fromInput({
    required String symptom,
    required bool hasImage,
  }) {
    final normalized = symptom.toLowerCase();
    if (normalized.contains('heavy bleeding') ||
        normalized.contains('unconscious') ||
        normalized.contains('severe chest pain')) {
      return const MockTriageResponse(
        severity: 'emergency',
        likelyIssue: 'Potential critical condition',
        steps: [
          'Call emergency services immediately.',
          'Keep the person still and monitor breathing.',
          'Apply direct pressure to bleeding with clean cloth.',
          'Do not give food or drink.',
        ],
        seekHelp: true,
        disclaimer: 'This is not medical advice. Seek professional care if unsure.',
      );
    }

    if (normalized.contains('burn') || hasImage) {
      return const MockTriageResponse(
        severity: 'moderate',
        likelyIssue: 'Possible superficial burn or skin injury',
        steps: [
          'Cool the area with running water for 20 minutes.',
          'Remove rings or tight items near affected area.',
          'Cover with sterile non-stick gauze.',
          'Avoid ice, oils, or toothpaste on the burn.',
        ],
        seekHelp: true,
        disclaimer: 'This is not medical advice. Seek professional care if unsure.',
      );
    }

    return const MockTriageResponse(
      severity: 'mild',
      likelyIssue: 'Minor soft tissue injury',
      steps: [
        'Clean the area gently with water.',
        'Use antiseptic if available.',
        'Apply bandage and monitor for swelling or pain.',
        'Rest and re-check in a few hours.',
      ],
      seekHelp: false,
      disclaimer: 'This is not medical advice. Seek professional care if unsure.',
    );
  }
}

class HistoryEntry {
  final int id;
  final DateTime timestamp;
  final String inputType;
  final String severity;
  final String summary;

  const HistoryEntry({
    required this.id,
    required this.timestamp,
    required this.inputType,
    required this.severity,
    required this.summary,
  });
}

class MockSymptomHistoryStore {
  static final List<HistoryEntry> _entries = [];

  static List<HistoryEntry> get entries => List.unmodifiable(_entries);

  static void add(HistoryEntry entry) {
    _entries.insert(0, entry);
  }

  static void clear() {
    _entries.clear();
  }
}
