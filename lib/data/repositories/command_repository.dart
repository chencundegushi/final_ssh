import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/common_command.dart';

abstract class CommandRepository {
  Future<List<CommonCommand>> getAllCommands();
  Future<List<CommonCommand>> getCommandsByCategory(String category);
  Future<void> saveCommand(CommonCommand command);
  Future<void> deleteCommand(String id);
  Future<void> updateUsageCount(String id);
}

class CommandRepositoryImpl implements CommandRepository {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'commands.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE common_commands(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            command TEXT NOT NULL,
            description TEXT,
            category TEXT DEFAULT 'default',
            usage_count INTEGER DEFAULT 0,
            created_at INTEGER NOT NULL,
            last_used_at INTEGER
          )
        ''');
      },
    );
  }

  @override
  Future<List<CommonCommand>> getAllCommands() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('common_commands');
    return List.generate(maps.length, (i) => CommonCommand.fromMap(maps[i]));
  }

  @override
  Future<List<CommonCommand>> getCommandsByCategory(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'common_commands',
      where: 'category = ?',
      whereArgs: [category],
    );
    return List.generate(maps.length, (i) => CommonCommand.fromMap(maps[i]));
  }

  @override
  Future<void> saveCommand(CommonCommand command) async {
    final db = await database;
    await db.insert(
      'common_commands',
      command.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteCommand(String id) async {
    final db = await database;
    await db.delete(
      'common_commands',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> updateUsageCount(String id) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE common_commands SET usage_count = usage_count + 1, last_used_at = ? WHERE id = ?',
      [DateTime.now().millisecondsSinceEpoch, id],
    );
  }
}
