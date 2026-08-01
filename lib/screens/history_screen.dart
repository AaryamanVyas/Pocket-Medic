import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';
import '../services/history_store.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String? _filter;

  @override
  Widget build(BuildContext context) {
    final all = HistoryStore.entries;
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
                  onPressed: () async {
                    await HistoryStore.clear();
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
