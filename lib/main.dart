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
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pocket Medic'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _headerCard(),
          const SizedBox(height: 14),
          _quickFlowCard(),
          const SizedBox(height: 14),
          _offlineStatusCard(),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TriageInputScreen()),
              );
            },
            icon: const Icon(Icons.medical_services_outlined),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Start Offline Triage'),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
            icon: const Icon(Icons.history),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Symptom History (Mock)'),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HospitalLocatorScreen()),
              );
            },
            icon: const Icon(Icons.place_outlined),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Offline Hospital Locator (Stub)'),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  Widget _headerCard() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'AI First Aid. No Internet Needed.',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 10),
            Text(
              'Capture an injury photo or describe symptoms. '
              'Pocket Medic gives instant first-aid guidance on-device.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickFlowCard() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Demo Flow', style: TextStyle(fontWeight: FontWeight.w700)),
            SizedBox(height: 10),
            Text('1) Add symptom or image'),
            Text('2) AI triages locally'),
            Text('3) See urgency + immediate steps'),
          ],
        ),
      ),
    );
  }

  Widget _offlineStatusCard() {
    return Card(
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
                'Offline Mode Ready: This round-1 demo uses mocked local AI output.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TriageInputScreen extends StatefulWidget {
  const TriageInputScreen({super.key});

  @override
  State<TriageInputScreen> createState() => _TriageInputScreenState();
}

class _TriageInputScreenState extends State<TriageInputScreen> {
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
    return Scaffold(
      appBar: AppBar(title: const Text('Input Symptoms')),
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
                  const Text(
                    'Describe what happened',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _symptomController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Example: Deep cut on hand, mild bleeding for 10 minutes.',
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
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    color: const Color(0xFFF1F5F9),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.mic_none_outlined, color: Color(0xFF334155)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: const Text(
                              'Voice input is mocked in this UI base (no real speech-to-text yet).',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Voice input: mock for round 1 UI')),
                              );
                            },
                            child: const Text('Try'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Image Input',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _hasImage ? Icons.image : Icons.camera_alt_outlined,
                          size: 34,
                          color: const Color(0xFF475569),
                        ),
                        const SizedBox(height: 8),
                        Text(_hasImage ? 'Mock Image Attached' : 'No image selected'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _hasImage = !_hasImage);
                    },
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(_hasImage ? 'Remove Image' : 'Attach Mock Image'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _isAnalyzing
                ? null
                : () async {
              final symptom = _symptomController.text.trim().isEmpty
                  ? 'Minor burn on left hand while cooking'
                  : _symptomController.text.trim();
              final inputType = _hasImage ? 'image' : 'text';

              setState(() => _isAnalyzing = true);
              await Future<void>.delayed(const Duration(milliseconds: 1400));
              if (!mounted) return;

              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TriageResultScreen(
                    response: MockTriageResponse.fromInput(
                      symptom: symptom,
                      hasImage: _hasImage,
                    ),
                    inputType: inputType,
                    summary: _shorten(symptom),
                  ),
                ),
              );
              setState(() => _isAnalyzing = false);
            },
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
                  : const Text('Run Offline Triage (Mock)'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sampleChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () {
        _symptomController.text = text;
      },
    );
  }

  String _shorten(String s) {
    if (s.length <= 60) return s;
    return '${s.substring(0, 60)}...';
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
    final badgeColor = _severityColor(response.severity);

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
                      color: badgeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Severity: ${response.severity.toUpperCase()}',
                      style: TextStyle(
                        color: badgeColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    response.likelyIssue,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  response.seekHelp
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB91C1C).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFB91C1C).withOpacity(0.35)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber_outlined, color: Color(0xFFB91C1C)),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Seek help now (may be urgent)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF991B1B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F766E).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF0F766E).withOpacity(0.35)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle_outline, color: Color(0xFF0F766E)),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Home care may be sufficient (still monitor closely)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F766E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Immediate Steps',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  for (var i = 0; i < response.steps.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${i + 1}. '),
                          Expanded(child: Text(response.steps[i])),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            elevation: 0,
            color: const Color(0xFFFFF7ED),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                response.disclaimer,
                style: const TextStyle(color: Color(0xFF9A3412)),
              ),
            ),
          ),
          const SizedBox(height: 20),
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
                const SnackBar(content: Text('Saved to Symptom History (mock).')),
              );
            },
            icon: const Icon(Icons.save),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Save to History (Mock)'),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const HospitalLocatorScreen(),
                ),
              );
            },
            icon: const Icon(Icons.place_outlined),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Find Nearby Offline Hospital (Stub)'),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.replay),
            label: const Text('Try Another Case'),
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
      case 'emergency':
      default:
        return const Color(0xFFB91C1C);
    }
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
  final String inputType; // 'text' or 'image'
  final String severity; // 'mild' | 'moderate' | 'emergency'
  final String summary;

  const HistoryEntry({
    required this.id,
    required this.timestamp,
    required this.inputType,
    required this.severity,
    required this.summary,
  });
}

/// Round-1 UI base storage: keeps entries in memory only.
/// Later we can swap this for SQLite on-device.
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

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String? _filter; // null = all

  @override
  Widget build(BuildContext context) {
    final all = MockSymptomHistoryStore.entries;
    final filtered = _filter == null
        ? all
        : all.where((e) => e.severity == _filter).toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Symptom History (Mock)')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text('All'),
                  onPressed: () => setState(() => _filter = null),
                  backgroundColor: _filter == null ? const Color(0xFF99F6E4) : null,
                ),
                ActionChip(
                  label: const Text('Mild'),
                  onPressed: () => setState(() => _filter = 'mild'),
                  backgroundColor: _filter == 'mild' ? const Color(0xFFDCFCE7) : null,
                ),
                ActionChip(
                  label: const Text('Moderate'),
                  onPressed: () => setState(() => _filter = 'moderate'),
                  backgroundColor: _filter == 'moderate'
                      ? const Color(0xFFFDE68A)
                      : null,
                ),
                ActionChip(
                  label: const Text('Emergency'),
                  onPressed: () => setState(() => _filter = 'emergency'),
                  backgroundColor: _filter == 'emergency'
                      ? const Color(0xFFFECACA)
                      : null,
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('No saved triage runs yet.'),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final e = filtered[index];
                      final badgeColor = _severityColor(e.severity);
                      return Card(
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: badgeColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Text(
                                      e.severity.toUpperCase(),
                                      style: TextStyle(
                                        color: badgeColor,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _formatTime(e.timestamp),
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                e.summary,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Input: ${e.inputType}',
                                style: const TextStyle(
                                  color: Color(0xFF475569),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (MockSymptomHistoryStore.entries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: OutlinedButton.icon(
                onPressed: () {
                  MockSymptomHistoryStore.clear();
                  setState(() => _filter = null);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('History cleared (mock).')),
                  );
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Clear History (Mock)'),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'mild':
        return const Color(0xFF15803D);
      case 'moderate':
        return const Color(0xFFB45309);
      case 'emergency':
      default:
        return const Color(0xFFB91C1C);
    }
  }
}

class HospitalLocatorScreen extends StatelessWidget {
  const HospitalLocatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline Hospital Locator (Stub)')),
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
                  Text(
                    'Round-1 UI stub',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'This screen is here so judges see the intended UX. '
                    'In the full build, we will use cached offline hospital data and GPS/location (or manual area input) without network calls.',
                    style: TextStyle(fontWeight: FontWeight.w600),
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
                  const Text('Quick offline options',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        label: const Text('Use saved area'),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Saved area: mock (no offline DB yet).'),
                            ),
                          );
                        },
                      ),
                      ActionChip(
                        label: const Text('Enter district'),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('District input: mock for UI.'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'No results to show in this UI-only demo.',
                    style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
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
                  Text(
                    'Offline-first demo mode',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'This round-1 build intentionally makes no network calls. '
                    'Triage results are generated by mocked local logic in the UI base.',
                    style: TextStyle(fontWeight: FontWeight.w700),
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
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: Color(0xFF0F766E)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Safety disclaimer is always shown in triage results.',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Safety disclaimer: visible in Result screen.')),
                      );
                    },
                    icon: const Icon(Icons.info_outline),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HospitalLocatorScreen()),
              );
            },
            child: const Text('Open Hospital Locator (Stub)'),
          ),
        ],
      ),
    );
  }
}
