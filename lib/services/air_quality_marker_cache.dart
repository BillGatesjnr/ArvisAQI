import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/air_quality_data.dart';

class AirQualityMarkerCache {
  static final AirQualityMarkerCache _instance =
      AirQualityMarkerCache._internal();
  factory AirQualityMarkerCache() => _instance;
  AirQualityMarkerCache._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'marker_cache.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE marker_cache (
            city TEXT PRIMARY KEY,
            data TEXT,
            updated_at INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE cache_meta (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
      },
    );
  }

  Future<void> saveMarker(String city, AirQualityData data) async {
    final db = await database;
    await db.insert(
      'marker_cache',
      {
        'city': city,
        'data': jsonEncode(data.toJson()),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, AirQualityData>> loadAllMarkers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('marker_cache');
    final Map<String, AirQualityData> result = {};
    for (final row in maps) {
      final city = row['city'] as String;
      final dataJson = jsonDecode(row['data'] as String);
      result[city] = AirQualityData.fromJson(dataJson);
    }
    return result;
  }

  Future<void> clearCache() async {
    final db = await database;
    await db.delete('marker_cache');
    await db.delete('cache_meta');
  }

  Future<DateTime?> getCacheTimestamp() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cache_meta',
      where: 'key = ?',
      whereArgs: ['timestamp'],
    );
    if (maps.isNotEmpty) {
      final millis = int.tryParse(maps.first['value'] as String);
      if (millis != null) {
        return DateTime.fromMillisecondsSinceEpoch(millis);
      }
    }
    return null;
  }

  Future<void> setCacheTimestamp(DateTime timestamp) async {
    final db = await database;
    await db.insert(
      'cache_meta',
      {
        'key': 'timestamp',
        'value': timestamp.millisecondsSinceEpoch.toString(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
