import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  late Database _database;

  Future<Database> get database async {
    if (_database != null) return _database;
    _database = await initDatabase();
    return _database;
  }

  Future<Database> initDatabase() async {
    final path = join(await getDatabasesPath(), 'your_database.db');
    return await openDatabase(path, version: 1, onCreate: _createDb);
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tukangojek (
        id INTEGER PRIMARY KEY,
        nama TEXT,
        nopol TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE transaksi (
        id INTEGER PRIMARY KEY,
        tukangojek_id INTEGER,
        harga INTEGER,
        timestamp TEXT,
        FOREIGN KEY (tukangojek_id) REFERENCES tukangojek (id)
      )
    ''');
  }

  Future<int> insertTukangOjek(TukangOjek tukangOjek) async {
    final db = await database;
    return await db.insert('tukangojek', tukangOjek.toMap());
  }

  Future<int> insertTransaksi(Transaksi transaksi) async {
    final db = await database;
    return await db.insert('transaksi', transaksi.toMap());
  }

  Future<List<TukangOjek>> getTukangOjeks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('tukangojek');
    return List.generate(maps.length, (i) {
      return TukangOjek(
        id: maps[i]['id'],
        nama: maps[i]['nama'],
        nopol: maps[i]['nopol'],
      );
    });
  }

  Future<List<Transaksi>> getTransaksis() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('transaksi');
    return List.generate(maps.length, (i) {
      return Transaksi(
        id: maps[i]['id'],
        tukangOjekId: maps[i]['tukangojek_id'],
        harga: maps[i]['harga'],
        timestamp: maps[i]['timestamp'],
      );
    });
  }
}

class TukangOjek {
  final int? id;
  final String nama;
  final String nopol;

  TukangOjek({this.id, required this.nama, required this.nopol});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'nopol': nopol,
    };
  }
}

class Transaksi {
  final int? id;
  final int tukangOjekId;
  final int harga;
  final String timestamp;

  Transaksi({
    this.id,
    required this.tukangOjekId,
    required this.harga,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tukangojek_id': tukangOjekId,
      'harga': harga,
      'timestamp': timestamp,
    };
  }
}
