import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/air_quality_data.dart';

class AirQualityLocationCache {
  static final AirQualityLocationCache _instance =
      AirQualityLocationCache._internal();
  factory AirQualityLocationCache() => _instance;
  AirQualityLocationCache._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'location_cache.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE location_cache (
            id TEXT PRIMARY KEY,
            data TEXT,
            updated_at INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE favorites_cache (
            id TEXT PRIMARY KEY,
            data TEXT,
            updated_at INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE favorites_list (
            id TEXT PRIMARY KEY,
            name TEXT,
            lat REAL,
            lon REAL
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

  // --- Current Location AQI ---
  Future<void> saveCurrentLocationAQI(AirQualityData data) async {
    final db = await database;
    await db.insert(
      'location_cache',
      {
        'id': 'current',
        'data': jsonEncode(data.toJson()),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('DEBUG: saveCurrentLocationAQI wrote: ' + jsonEncode(data.toJson()));
  }

  Future<AirQualityData?> loadCurrentLocationAQI() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'location_cache',
      where: 'id = ?',
      whereArgs: ['current'],
    );
    if (maps.isNotEmpty) {
      print('DEBUG: loadCurrentLocationAQI loaded: ' +
          maps.first['data'].toString());
      final dataJson = jsonDecode(maps.first['data'] as String);
      return AirQualityData.fromJson(dataJson);
    }
    print('DEBUG: loadCurrentLocationAQI found nothing');
    return null;
  }

  // --- Favorites AQI ---
  Future<void> saveFavoriteAQI(String id, AirQualityData data) async {
    final db = await database;
    await db.insert(
      'favorites_cache',
      {
        'id': id,
        'data': jsonEncode(data.toJson()),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, AirQualityData>> loadAllFavoriteAQI() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('favorites_cache');
    final Map<String, AirQualityData> result = {};
    for (final row in maps) {
      final id = row['id'] as String;
      final dataJson = jsonDecode(row['data'] as String);
      result[id] = AirQualityData.fromJson(dataJson);
    }
    return result;
  }

  // --- Favorites List ---
  Future<void> saveFavoritesList(List<Map<String, dynamic>> favorites) async {
    final db = await database;
    await db.delete('favorites_list');
    for (final fav in favorites) {
      await db.insert(
        'favorites_list',
        fav,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<List<Map<String, dynamic>>> loadFavoritesList() async {
    final db = await database;
    return await db.query('favorites_list');
  }

  Future<void> removeFavorite(String id) async {
    final db = await database;
    await db.delete('favorites_list', where: 'id = ?', whereArgs: [id]);
    await db.delete('favorites_cache', where: 'id = ?', whereArgs: [id]);
  }

  // --- Meta & Utility ---
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('location_cache');
    await db.delete('favorites_cache');
    await db.delete('favorites_list');
    await db.delete('cache_meta');
  }

  Future<DateTime?> getCacheTimestamp(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cache_meta',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty) {
      final millis = int.tryParse(maps.first['value'] as String);
      if (millis != null) {
        final ts = DateTime.fromMillisecondsSinceEpoch(millis);
        print('DEBUG: getCacheTimestamp for $key: ' + ts.toIso8601String());
        return ts;
      }
    }
    print('DEBUG: getCacheTimestamp for $key: not found');
    return null;
  }

  Future<void> setCacheTimestamp(String key, DateTime timestamp) async {
    final db = await database;
    await db.insert(
      'cache_meta',
      {
        'key': key,
        'value': timestamp.millisecondsSinceEpoch.toString(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('DEBUG: setCacheTimestamp for $key: ' + timestamp.toIso8601String());
  }
}
