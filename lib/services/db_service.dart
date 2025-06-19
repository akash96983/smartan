import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/keypoint_entry.dart';

class DBService {
  static final DBService _instance = DBService._internal();
  factory DBService() => _instance;
  DBService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'keypoints.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE keypoints(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            keypointsJson TEXT,
            imagePath TEXT,
            timestamp TEXT,
            isSynced INTEGER
          )
        ''');
      },
    );
  }

  Future<int> insertEntry(KeypointEntry entry) async {
    final db = await database;
    return await db.insert('keypoints', entry.toMap());
  }

  Future<List<KeypointEntry>> fetchAllEntries() async {
    final db = await database;
    final maps = await db.query('keypoints', orderBy: 'timestamp DESC');
    return maps.map((map) => KeypointEntry.fromMap(map)).toList();
  }

  Future<int> updateSyncStatus(int id, bool isSynced) async {
    final db = await database;
    return await db.update(
      'keypoints',
      {'isSynced': isSynced ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteEntry(int id) async {
    final db = await database;
    return await db.delete('keypoints', where: 'id = ?', whereArgs: [id]);
  }
}
