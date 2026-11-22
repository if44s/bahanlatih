import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/digitization_result.dart';
import '../models/survey_point.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'praktek_mobile_gis.db');
    return openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE survey_points (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nama_surveyor TEXT NOT NULL,
            nim TEXT NOT NULL DEFAULT '',
            kategori TEXT NOT NULL,
            kondisi_rusak INTEGER NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            foto_path TEXT,
            waktu TEXT NOT NULL,
            terkirim INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE digitization_results (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            image_path TEXT NOT NULL,
            distance_meters REAL NOT NULL,
            vertex_count INTEGER NOT NULL,
            waktu TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
              "ALTER TABLE survey_points ADD COLUMN nim TEXT NOT NULL DEFAULT ''");
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE digitization_results (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              image_path TEXT NOT NULL,
              distance_meters REAL NOT NULL,
              vertex_count INTEGER NOT NULL,
              waktu TEXT NOT NULL
            )
          ''');
        }
      },
    );
  }

  Future<int> insertSurveyPoint(SurveyPoint point) async {
    final db = await database;
    final map = point.toMap()..remove('id');
    return db.insert('survey_points', map);
  }

  Future<List<SurveyPoint>> getAllSurveyPoints() async {
    final db = await database;
    final rows = await db.query('survey_points', orderBy: 'id DESC');
    return rows.map(SurveyPoint.fromMap).toList();
  }

  Future<int> deleteSurveyPoint(int id) async {
    final db = await database;
    return db.delete('survey_points', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> markAsTerkirim(int id) async {
    final db = await database;
    return db.update(
      'survey_points',
      {'terkirim': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertDigitizationResult(DigitizationResult result) async {
    final db = await database;
    final map = result.toMap()..remove('id');
    return db.insert('digitization_results', map);
  }

  Future<List<DigitizationResult>> getAllDigitizationResults() async {
    final db = await database;
    final rows = await db.query('digitization_results', orderBy: 'id DESC');
    return rows.map(DigitizationResult.fromMap).toList();
  }
}
