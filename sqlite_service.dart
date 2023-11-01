import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models/saham.dart';  // Make sure the Saham model is defined in this path

class DatabaseHandler {
  Future<Database> initializeDB() async {
    String path = await getDatabasesPath();
    return openDatabase(
      join(path, 'example.db'),
      onCreate: (database, version) async {
        await database.execute(
          "CREATE TABLE saham("
              "tickerid INTEGER PRIMARY KEY AUTOINCREMENT, "
              "ticker TEXT NOT NULL,"
              "open INTEGER,"
              "high INTEGER,"
              "last INTEGER,"
              "change TEXT)",
        );
      },
      version: 1,
    );
  }

  Future<int> insertSaham(dynamic sahams) async {
    int result = 0;
    final Database db = await initializeDB();

    if (sahams is Saham) {
      return await db.insert('saham', sahams.toMap());
    } else if (sahams is List<Saham>) {
      for (var saham in sahams) {
        result = await db.insert('saham', saham.toMap());
      }
      return result;
    } else {
      throw ArgumentError('Expected either a Saham or List<Saham> argument');
    }
  }

  Future<List<Saham>> retrieveSahams() async {
    final Database db = await initializeDB();
    final List<Map<String, Object?>> queryResult = await db.query('saham');
    return queryResult.map((e) => Saham.fromMap(e)).toList();
  }
}