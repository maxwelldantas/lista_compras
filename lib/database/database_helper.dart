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
    
    // Mudamos a versão para 2 para disparar a atualização de tabelas
    return await openDatabase(
      path,
      version: 2, 
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            marketName TEXT,
            date TEXT,
            time TEXT,
            itemsJson TEXT
          )
        ''');
      },
      // --- LOGICA DE MIGRAÇÃO: ADICIONA A COLUNA TIME SE VOCÊ JÁ TINHA O APP INSTALADO ---
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute('ALTER TABLE $tableName ADD COLUMN time TEXT DEFAULT ""');
          } catch (_) {
            // Evita que o app trave se a coluna de alguma forma já existir
          }
        }
      },
    );
  }

  static Future<int> insertList(MarketList list) async {
    final db = await database;
    return await db.insert(tableName, list.toMap());
  }

  static Future<int> updateList(MarketList list) async {
    final db = await database;
    return await db.update(
      tableName,
      list.toMap(),
      where: 'id = ?',
      whereArgs: [list.id],
    );
  }

  static Future<int> deleteList(int id) async {
    final db = await database;
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
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
