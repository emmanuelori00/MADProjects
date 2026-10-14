import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'card_record.dart';
import 'folder.dart';

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

  Future<int> insertFolder(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Enter a folder name.');
    }
    final folder = Folder(
      name: trimmedName,
      createdAt: DateTime.now().toIso8601String(),
    );
    return _db.insert('folders', folder.toMap());
  }

  Future<List<Folder>> getFoldersWithCounts() async {
    final rows = await _db.rawQuery(
      'SELECT folders.id, folders.name, folders.created_at, '
      'COUNT(cards.id) AS card_count '
      'FROM folders LEFT JOIN cards ON folders.id = cards.folder_id '
      'GROUP BY folders.id, folders.name, folders.created_at '
      'ORDER BY folders.name COLLATE NOCASE ASC, folders.id ASC',
    );
    return rows.map((row) => Folder.fromMap(row)).toList();
  }

  Future<List<CardRecord>> getCards(int folderId) async {
    final rows = await _db.query(
      'cards',
      where: 'folder_id = ?',
      whereArgs: [folderId],
      orderBy: 'title COLLATE NOCASE ASC, id ASC',
    );
    return rows.map((row) => CardRecord.fromMap(row)).toList();
  }

  Map<String, dynamic> _cardValues(CardRecord card) {
    final title = card.title.trim();
    if (title.isEmpty) {
      throw ArgumentError('Enter a card title.');
    }
    if (!CardRecord.suits.contains(card.suit)) {
      throw ArgumentError('Choose Hearts, Diamonds, Clubs, or Spades.');
    }
    if (card.folderId <= 0) {
      throw ArgumentError('Choose a folder.');
    }
    final row = card.toMap();
    row.remove('id');
    row['title'] = title;
    final imageRef = card.imageRef?.trim();
    row['image_ref'] = imageRef == null || imageRef.isEmpty ? null : imageRef;
    return row;
  }

  Future<int> insertCard(CardRecord card) async =>
      _db.insert('cards', _cardValues(card));

  Future<int> updateCard(CardRecord card) async {
    if (card.id == null || card.id! <= 0) {
      throw ArgumentError('Choose a saved card.');
    }
    return _db.update(
      'cards',
      _cardValues(card),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<int> deleteCard(int id) =>
      _db.delete('cards', where: 'id = ?', whereArgs: [id]);

  Future<int> deleteFolder(int id) =>
      _db.delete('folders', where: 'id = ?', whereArgs: [id]);

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
