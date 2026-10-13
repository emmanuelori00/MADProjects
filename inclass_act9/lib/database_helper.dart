import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const table = 'my_table';
  static const columnId = '_id';
  static const columnName = 'name';
  static const columnAge = 'age';

  late Database _db;

  Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    _db = await openDatabase(
      join(directory.path, 'MyDatabase.db'),
      version: 2,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (database, version) async {
        await _createPartOneTables(database);
        await _createCatalogueTables(database);
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createCatalogueTables(database);
        }
      },
    );
  }

  Future<void> _createPartOneTables(Database database) async {
    await database.execute(
      'CREATE TABLE $table ('
      '$columnId INTEGER PRIMARY KEY, '
      '$columnName TEXT NOT NULL, '
      '$columnAge INTEGER NOT NULL)',
    );
  }

  Future<void> _createCatalogueTables(Database database) async {
    await database.execute(
      'CREATE TABLE folders ('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'name TEXT NOT NULL UNIQUE, '
      'created_at TEXT NOT NULL)',
    );
    await database.execute(
      'CREATE TABLE cards ('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'title TEXT NOT NULL, '
      'suit TEXT NOT NULL, '
      "notes TEXT NOT NULL DEFAULT '', "
      'image_ref TEXT, '
      'folder_id INTEGER NOT NULL, '
      'FOREIGN KEY (folder_id) REFERENCES folders(id) ON DELETE CASCADE)',
    );
    await database.execute('CREATE INDEX idx_cards_folder_id ON cards(folder_id)');
  }

  Future<int> insert(Map<String, dynamic> row) => _db.insert(table, row);

  Future<List<Map<String, dynamic>>> queryAllRows() =>
      _db.query(table, orderBy: '$columnId ASC');

  Future<int> queryRowCount() async =>
      Sqflite.firstIntValue(await _db.rawQuery('SELECT COUNT(*) FROM $table'))!;

  Future<int> update(Map<String, dynamic> row) => _db.update(
    table,
    row,
    where: '$columnId = ?',
    whereArgs: [row[columnId] as int],
  );

  Future<int> delete(int id) =>
      _db.delete(table, where: '$columnId = ?', whereArgs: [id]);
}
