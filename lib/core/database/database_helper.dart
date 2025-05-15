import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../utils/logger.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    return _database ??= await _initDatabase();
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'sensor_data.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE cached_requests (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            request_body TEXT NOT NULL,
            device_id TEXT NOT NULL,
            type_id TEXT NOT NULL,
            timestamp INTEGER NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE UNIQUE INDEX idx_unique_request
          ON cached_requests (type_id, device_id, timestamp)
        ''');
      },
    );
  }

  Future<int> insertCachedRequest({
    required String requestBody,
    required String deviceId,
    required String typeId,
    required int timestamp,
  }) async {
    final db = await database;

    try {
      return await db.insert('cached_requests', {
        'request_body': requestBody,
        'device_id': deviceId,
        'type_id': typeId,
        'timestamp': timestamp,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      Logger.e('Error inserting cached request', error: e);
      return -1;
    }
  }

  Future<List<Map<String, dynamic>>> getCachedRequests({int limit = 20}) async {
    final db = await database;

    return await db.query(
      'cached_requests',
      orderBy: 'created_at ASC',
      limit: limit,
    );
  }

  Future<int> deleteCachedRequest(int id) async {
    final db = await database;
    return await db.delete('cached_requests', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getCachedRequestsCount() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM cached_requests'),
    );
    return count ?? 0;
  }
}
