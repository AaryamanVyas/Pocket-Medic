import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/history_entry.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'pocket_medic.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE history(
            id INTEGER PRIMARY KEY,
            timestamp INTEGER NOT NULL,
            inputType TEXT NOT NULL,
            category TEXT NOT NULL,
            urgency TEXT NOT NULL,
            summary TEXT NOT NULL
          )
        ''');
      },
    );
  }

  static Future<List<HistoryEntry>> getHistory() async {
    final db = await database;
    final maps = await db.query('history', orderBy: 'timestamp DESC');
    return maps.map((m) => HistoryEntry.fromMap(m)).toList();
  }

  static Future<void> insertEntry(HistoryEntry entry) async {
    final db = await database;
    await db.insert('history', entry.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> clearHistory() async {
    final db = await database;
    await db.delete('history');
  }
}
