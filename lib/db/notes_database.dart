import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:work_notes/model/note.dart';

class NotesDatabase {
  static final NotesDatabase instance = NotesDatabase._init();

  static Database? _database;

  NotesDatabase._init();

// Open the database.  If it does note exist one will be created with the file 'note.db'

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('notes.db');
    return _database!;
  }

// Initialize database. The path is ref to the file path on the device.
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
    // to update the db in the future updat the version number and use the onUpgrade: method.
  }

  Future _createDB(Database db, int version) async {
    final idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    final boolType = 'BOOLEAN NOT NULL';
    final integerType = 'INTEGER NOT NULL';
    final textType = 'TEXT NOT NULL';

    await db.execute('''
CREATE TABLE $tableNotes(
  ${NoteFields.id} $idType,
  ${NoteFields.isImportant} $boolType,
  ${NoteFields.number} $integerType,
  ${NoteFields.title} $textType,
  ${NoteFields.description} $textType,
  ${NoteFields.time} $textType,

)
''');
// More datatables can be added under the initial table.
// TODO: create a table for officer notes.
  }

/*--------------
| CRUD OPERATIONS |
------------------*/
  Future<Note> create(Note note) async {
//grab reference to the database
    final db = await instance.database;

// call on the database insert method
    final id = await db.insert(tableNotes, note.toJson());
    return note.copy(id: id);
  }

//this queries the table "table notes".
// this reads only one note at a time.
// TODO: This needs to be adjusted for the call notes table.
  Future<Note> readNote(int id) async {
    final db = await instance.database;

    final maps = await db.query(
      tableNotes,
      columns: NoteFields.values,
      where: '${NoteFields.id} = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Note.fromJson(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  /// this is to read multiple notes
  Future<List<Note>> readAllNotes() async {
    final db = await instance.database;

    final orderBy = '${NoteFields.time} ASC';
    final result = await db.query(tableNotes,
        orderBy:
            orderBy); // this does note request a specific note, rather, all of them.

    return result.map((json) => Note.fromJson(json)).toList();
  }

  ///This is to update the notes
  Future<int> update(Note note) async {
    final db = await instance.database;

    return db.update(
      tableNotes,
      note.toJson(),
      where: '${NoteFields.id} = ?',
      whereArgs: [note.id],
    );
  }

  //Delete notes from database
  Future<int> delete(int id) async {
    final db = await instance.database;

    return await db.delete(
      tableNotes,
      where: '${NoteFields.id} = ?',
      whereArgs: [id],
    );
  }

// To close the database once done.
  Future close() async {
    final db = await instance.database;

    db.close();
  }
}
