import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class KnowledgeService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pocket_medic.db');

    final db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS history(
            id INTEGER PRIMARY KEY,
            timestamp INTEGER NOT NULL,
            inputType TEXT NOT NULL,
            category TEXT NOT NULL,
            urgency TEXT NOT NULL,
            summary TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE VIRTUAL TABLE IF NOT EXISTS knowledge USING fts5(
            id, category, title, content, content=knowledge_rows
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS knowledge_rows(
            id TEXT PRIMARY KEY,
            category TEXT NOT NULL,
            title TEXT NOT NULL,
            content TEXT NOT NULL
          )
        ''');
        await _seedKnowledge(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('DROP TABLE IF EXISTS knowledge');
          await db.execute('DROP TABLE IF EXISTS knowledge_rows');
          await db.execute('''
            CREATE VIRTUAL TABLE IF NOT EXISTS knowledge USING fts5(
              id, category, title, content, content=knowledge_rows
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS knowledge_rows(
              id TEXT PRIMARY KEY,
              category TEXT NOT NULL,
              title TEXT NOT NULL,
              content TEXT NOT NULL
            )
          ''');
          await _seedKnowledge(db);
        }
      },
    );

    return db;
  }

  static Future<void> _seedKnowledge(Database db) async {
    final count = await db.query('knowledge_rows').then((r) => r.length);
    if (count > 0) return;

    final jsonStr = await rootBundle.loadString('assets/knowledge/knowledge_chunks.json');
    final chunks = jsonDecode(jsonStr) as List;

    for (final chunk in chunks) {
      await db.insert('knowledge_rows', {
        'id': chunk['id'],
        'category': chunk['category'],
        'title': chunk['title'],
        'content': chunk['content'],
      });
    }

    await db.execute("INSERT INTO knowledge(knowledge) VALUES('rebuild')");
  }

  static Future<List<Map<String, dynamic>>> retrieve(String query, {int limit = 3}) async {
    final db = await database;
    final results = await db.rawQuery(
      'SELECT id, category, title, content FROM knowledge WHERE knowledge MATCH ? ORDER BY rank LIMIT ?',
      [query, limit],
    );
    return results;
  }

  static Future<List<Map<String, dynamic>>> retrieveByCategory(String category, {int limit = 5}) async {
    final db = await database;
    final results = await db.query(
      'knowledge_rows',
      where: 'category = ?',
      whereArgs: [category],
      limit: limit,
    );
    return results;
  }
}