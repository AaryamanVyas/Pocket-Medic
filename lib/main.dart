import 'package:flutter/material.dart';

void main() {
  runApp(const PocketMedicApp());
}

/// Shared design tokens (strict 8px grid + limited palette).
class AppTokens {
  static const surface = Color(0xFFF8FAFC);
  static const text = Color(0xFF0F172A);
  static const accent = Color(0xFF0F766E);
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

class PocketMedicApp extends StatelessWidget {
  const PocketMedicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pocket Medic',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTokens.accent,
          surface: AppTokens.surface,
        ),
        scaffoldBackgroundColor: AppTokens.surface,
        textTheme: const TextTheme(
          headlineLarge: AppTokens.heading,
          titleLarge: AppTokens.title,
          bodyLarge: AppTokens.body,
          bodyMedium: AppTokens.bodyRegular,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radius),
            side: const BorderSide(color: AppTokens.border, width: 1),
          ),
        ),
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
      FieldGuidesScreen(),
      HistoryScreen(),
      SettingsScreen(),
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

class DashboardScreen extends StatefulWidget {
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
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _modelLoading = true;

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
              onPressed: () => widget.onOpenAsk(AskCategory.medical),
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
                    onPressed: widget.onOpenEmergency,
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
                    onPressed: widget.onOpenPlaces,
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
              child: _modelLoading
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Preparing offline model...',
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
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => setState(() => _modelLoading = false),
                            child: const Text(
                              'Mark ready',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                color: AppTokens.accent,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Row(
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
                    ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Recent asks',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppTokens.text,
            ),
          ),
          const SizedBox(height: 8),
          if (MockAskHistoryStore.entries.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.inbox_outlined, color: AppTokens.text),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No saved asks yet. Use Ask to run a case, then save it.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          color: AppTokens.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...MockAskHistoryStore.entries.take(3).map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      child: ListTile(
                        title: Text(
                          e.summary,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            color: AppTokens.text,
                          ),
                        ),
                        subtitle: Text(e.category),
                      ),
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
        onTap: () => widget.onOpenAsk(category),
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

class AskScreen extends StatelessWidget {
  final AskCategory? initialCategory;
  const AskScreen({super.key, this.initialCategory});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AskFormBody(initialCategory: initialCategory ?? AskCategory.medical),
    );
  }
}

class AskFormBody extends StatefulWidget {
  final AskCategory initialCategory;
  const AskFormBody({super.key, required this.initialCategory});

  @override
  State<AskFormBody> createState() => _AskFormBodyState();
}

class _AskFormBodyState extends State<AskFormBody> {
  late AskCategory _category;
  final TextEditingController _queryController = TextEditingController();
  bool _hasImage = false;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
  }

  @override
  void didUpdateWidget(covariant AskFormBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCategory != widget.initialCategory) {
      _category = widget.initialCategory;
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Ask offline',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w700,
            fontSize: 24,
            color: AppTokens.text,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Pick a topic, describe what you see, optionally attach a photo.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: AppTokens.text,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Topic',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    color: AppTokens.text,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in AskCategory.values)
                      ChoiceChip(
                        label: Text(c.label),
                        selected: _category == c,
                        onSelected: (_) => setState(() => _category = c),
                        selectedColor: const Color(0xFFCCFBF1),
                        labelStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          color: AppTokens.text,
                        ),
                      ),
                  ],
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
                Text(
                  _category == AskCategory.medical
                      ? 'Describe the situation'
                      : 'Your question',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    color: AppTokens.text,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _queryController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: _category.samplePrompts.first,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final p in _category.samplePrompts)
                      ActionChip(
                        label: Text(p),
                        onPressed: () => _queryController.text = p,
                      ),
                  ],
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
                  'Photo (optional)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    color: AppTokens.text,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 152,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTokens.border,
                    borderRadius: BorderRadius.circular(AppTokens.radius),
                    border: Border.all(color: AppTokens.border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _hasImage ? Icons.image : Icons.camera_alt_outlined,
                        size: 32,
                        color: AppTokens.text,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _hasImage
                            ? 'Mock image attached'
                            : 'Useful for plants, wounds, animal signs',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          color: AppTokens.text,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTokens.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radius),
                      ),
                    ),
                    onPressed: () => setState(() => _hasImage = !_hasImage),
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(_hasImage ? 'Remove image' : 'Attach mock image'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.mic_none_outlined),
            title: const Text(
              'Voice input',
              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Local speech-to-text stub'),
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
        SizedBox(
          height: 48,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTokens.accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.radius),
              ),
            ),
            onPressed: _isAnalyzing ? null : _runAsk,
            child: _isAnalyzing
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      SizedBox(width: 8),
                      Text('Analyzing offline...'),
                    ],
                  )
                : const Text(
                    'Get offline guidance',
                    style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _runAsk() async {
    final query = _queryController.text.trim().isEmpty
        ? _category.samplePrompts.first
        : _queryController.text.trim();
    setState(() => _isAnalyzing = true);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    final response = MockAskResponse.fromInput(
      category: _category,
      query: query,
      hasImage: _hasImage,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AskResultScreen(
          response: response,
          category: _category,
          inputType: _hasImage ? 'image' : 'text',
          summary: query.length <= 65 ? query : '${query.substring(0, 65)}...',
        ),
      ),
    );
    setState(() => _isAnalyzing = false);
  }
}

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
              onPressed: () {
                MockAskHistoryStore.add(
                  HistoryEntry(
                    id: DateTime.now().millisecondsSinceEpoch,
                    timestamp: DateTime.now(),
                    inputType: inputType,
                    category: category.label,
                    urgency: response.urgency,
                    summary: summary,
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Saved to local history.')),
                );
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

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String? _filter;

  @override
  Widget build(BuildContext context) {
    final all = MockAskHistoryStore.entries;
    final items = _filter == null
        ? all
        : all.where((e) => e.category == _filter).toList(growable: false);

    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Ask History',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  color: AppTokens.text,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('All', null),
                for (final c in AskCategory.values) _chip(c.label, c.label),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text(
                      'No entries yet. Save from an Ask result.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        color: AppTokens.text,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (_, index) {
                      final e = items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Card(
                          child: ListTile(
                            title: Text(
                              e.summary,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                color: AppTokens.text,
                              ),
                            ),
                            subtitle: Text(
                              '${e.category} • ${e.inputType} • ${_hhmm(e.timestamp)}',
                            ),
                            trailing: Text(
                              e.urgency.toUpperCase(),
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                                color: AppTokens.accent,
                              ),
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
              child: SizedBox(
                height: 48,
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTokens.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radius),
                    ),
                  ),
                  onPressed: () {
                    MockAskHistoryStore.clear();
                    setState(() => _filter = null);
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear History'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(String label, String? value) {
    return ActionChip(
      label: Text(label),
      backgroundColor: _filter == value ? const Color(0xFFCCFBF1) : null,
      onPressed: () => setState(() => _filter = value),
    );
  }

  String _hhmm(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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
          _tile(context, Icons.call, 'Call emergency helpline', 'Simulated call action'),
          _tile(context, Icons.local_hospital_outlined, 'Nearest hospital', 'Cached offline list'),
          _tile(context, Icons.location_city_outlined, 'Nearest town / city', 'Cached settlement stub'),
          _tile(context, Icons.water_drop_outlined, 'Known water points', 'Offline water markers'),
          _tile(context, Icons.sms_outlined, 'Alert emergency contact', 'Share summary (planned)'),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          leading: Icon(icon, color: AppTokens.accent),
          title: Text(
            title,
            style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
          ),
          subtitle: Text(subtitle),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$title tapped (UI stub).')),
            );
          },
        ),
      ),
    );
  }
}

class PlacesLocatorScreen extends StatelessWidget {
  const PlacesLocatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Places (offline stub)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Cached offline places for hospitals, towns, and water. No network required in the final build.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  color: AppTokens.text,
                ),
              ),
            ),
          ),
          SizedBox(height: 8),
          _PlaceCard(
            icon: Icons.local_hospital,
            name: 'City Civil Hospital',
            meta: 'Hospital • 2.1 km • 8 min',
          ),
          SizedBox(height: 8),
          _PlaceCard(
            icon: Icons.location_city_outlined,
            name: 'Ridgeview Town Center',
            meta: 'Town • 5.4 km • 18 min',
          ),
          SizedBox(height: 8),
          _PlaceCard(
            icon: Icons.water_drop_outlined,
            name: 'Spring Creek (seasonal)',
            meta: 'Water • 1.2 km • purify before use',
          ),
          SizedBox(height: 8),
          _PlaceCard(
            icon: Icons.apartment_outlined,
            name: 'North Valley City',
            meta: 'City • 12.0 km • 35 min',
          ),
        ],
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final String meta;

  const _PlaceCard({
    required this.icon,
    required this.name,
    required this.meta,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppTokens.accent),
        title: Text(
          name,
          style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
        ),
        subtitle: Text(meta),
        trailing: TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Route is mocked in this demo.')),
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
          const Text(
            'Settings',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w700,
              fontSize: 24,
              color: AppTokens.text,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              value: true,
              onChanged: (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Offline lock stays ON in demo mode.')),
                );
              },
              title: const Text('Offline-only mode'),
              subtitle: const Text('No cloud calls in final architecture'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.language_outlined),
              title: const Text('Language'),
              subtitle: const Text('English (more planned)'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Language selector planned.')),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Safety disclaimer'),
              subtitle: const Text('Shown on every result'),
              onTap: () {
                showDialog<void>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Safety Notice'),
                    content: const Text(
                      'Pocket Medic gives offline field and first-aid guidance only. '
                      'It is not a substitute for professional medical care, '
                      'certified foraging, or official rescue services.',
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
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppTokens.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radius),
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EmergencyScreen()),
                );
              },
              icon: const Icon(Icons.sos),
              label: const Text('Open Emergency Actions'),
            ),
          ),
        ],
      ),
    );
  }
}

class MockAskResponse {
  final String urgency; // low | medium | high
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

class HistoryEntry {
  final int id;
  final DateTime timestamp;
  final String inputType;
  final String category;
  final String urgency;
  final String summary;

  const HistoryEntry({
    required this.id,
    required this.timestamp,
    required this.inputType,
    required this.category,
    required this.urgency,
    required this.summary,
  });
}

class MockAskHistoryStore {
  static final List<HistoryEntry> _entries = [];

  static List<HistoryEntry> get entries => List.unmodifiable(_entries);

  static void add(HistoryEntry entry) {
    _entries.insert(0, entry);
  }

  static void clear() {
    _entries.clear();
  }
}
