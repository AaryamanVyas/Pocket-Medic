import '../models/history_entry.dart';
import 'database_service.dart';

class HistoryStore {
  static List<HistoryEntry> _entries = [];

  static List<HistoryEntry> get entries => List.unmodifiable(_entries);

  static Future<void> load() async {
    _entries = await DatabaseService.getHistory();
  }

  static Future<void> add(HistoryEntry entry) async {
    await DatabaseService.insertEntry(entry);
    _entries.insert(0, entry);
  }

  static Future<void> clear() async {
    await DatabaseService.clearHistory();
    _entries.clear();
  }
}
