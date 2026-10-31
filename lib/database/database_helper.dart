import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/market_list.dart';

class DatabaseHelper {
  static Database? _database;
  static const String tableName = 'shopping_lists';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'shopping.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE $tableName (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          marketName TEXT,
          date TEXT,
          itemsJson TEXT
        )
      ''');
      },
    );
  }

  static Future<int> insertList(MarketList list) async {
    final db = await database;
    return await db.insert(tableName, list.toMap());
  }

  static Future<List<MarketList>> getAllLists() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: 'id DESC',
    );
    return maps.map((map) => MarketList.fromMap(map)).toList();
  }
}
