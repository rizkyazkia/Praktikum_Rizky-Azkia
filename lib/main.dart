import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  runApp(MyApp());
}

class DatabaseHelper {
  static DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    final path = join(await getDatabasesPath(), 'ojek.db');
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
}

class TukangOjek {
  final int? id;
  final String nama;
  final String nopol;

  TukangOjek({
    required this.id,
    required this.nama,
    required this.nopol,
  });
}

class Transaksi {
  final int? id;
  final int? tukangOjekId;
  final int? harga;
  final String timestamp;

  Transaksi({
    required this.id,
    required this.tukangOjekId,
    required this.harga,
    required this.timestamp,
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Ojek',
      initialRoute: '/',
      routes: {
        '/': (context) => MainPage(),
        '/addDriver': (context) => AddDriverPage(),
        '/addTransaction': (context) => AddTransactionPage(),
      },
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final dbHelper = DatabaseHelper();

  List<TukangOjek> drivers = [];
  List<Transaksi> transactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = await dbHelper.database;
    final driversResult = await db.query('tukangojek');
    final transactionsResult = await db.query('transaksi');
    drivers = driversResult.map((e) => TukangOjek(
      id: e['id'] as int?,
      nama: e['nama'] as String,
      nopol: e['nopol'] as String,
    )).toList();

    transactions = transactionsResult.map((e) => Transaksi(
      id: e['id'] as int?,
      tukangOjekId: e['tukangojek_id'] as int?,
      harga: e['harga'] as int?,
      timestamp: e['timestamp'] as String,
    )).toList();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(' OPANGATIMIN'),
      ),
      body: Column(
        children: [
      Expanded(
      child: ListView.builder(
      itemCount: drivers.length,
        itemBuilder: (context, index) {
          final driver = drivers[index];
          final totalOrders = transactions.where((t) => t.tukangOjekId == driver.id).length;
          final totalOmzet = transactions.where((t) => t.tukangOjekId == driver.id).map((t) => t.harga).fold(0, (a, b) => a + b!);
          return ListTile(
            title: Text(driver.nama),
            subtitle: Text('Jumlah Order: $totalOrders, Omzet: $totalOmzet'),
          );
        },
      ),
    ),
    Padding(
    padding: const EdgeInsets.all(16.0),
    child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
    ElevatedButton(
    onPressed: () => Navigator.pushNamed(context, '/addDriver').then((_) => _loadData()),
    child: Text('Tambah Tukang Ojek'),
    ),
      ElevatedButton(
        onPressed: () => Navigator.pushNamed(context, '/addTransaction').then((_) => _loadData()),
        child: Text('Tambah Transaksi'),
      ),
    ],
    ),
    ),
        ],
      ),
    );
  }
}

class AddDriverPage extends StatefulWidget {
  @override
  _AddDriverPageState createState() => _AddDriverPageState();
}

class _AddDriverPageState extends State<AddDriverPage> {
  final dbHelper = DatabaseHelper();
  final namaController = TextEditingController();
  final nopolController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tambah Tukang Ojek'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: namaController,
              decoration: InputDecoration(labelText: 'Nama'),
            ),
            TextField(
              controller: nopolController,
              decoration: InputDecoration(labelText: 'Nomor Polisi'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final db = await dbHelper.database;
                await db.insert('tukangojek', {'nama': namaController.text, 'nopol': nopolController.text});
                Navigator.pop(context);
              },
              child: Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

class AddTransactionPage extends StatefulWidget {
  @override
  _AddTransactionPageState createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final dbHelper = DatabaseHelper();
  final hargaController = TextEditingController();
  int? selectedDriverId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tambah Transaksi'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<List<Map<String, Object?>>>(
              future: dbHelper.database.then((db) => db.query('tukangojek')),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final driversResult = snapshot.data as List<Map<String, Object?>>;
                  final drivers = driversResult.map((e) => TukangOjek(
                    id: e['id'] as int?,
                    nama: e['nama'] as String,
                    nopol: e['nopol'] as String,
                  )).toList();

                  return DropdownButtonFormField(
                    items: drivers.map((driver) {
                      return DropdownMenuItem(
                        value: driver.id,
                        child: Text(driver.nama),
                      );
                    }).toList(),
                    onChanged: (int? value) {
                      setState(() {
                        selectedDriverId = value;
                      });
                    },
                    decoration: InputDecoration(labelText: 'Tukang Ojek'),
                  );
                } else {
                  // Handle the case when data is not available
                  return CircularProgressIndicator();
                }
              },
            ),
            SizedBox(height: 20),
            TextField(
              controller: hargaController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Harga'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (selectedDriverId != null) {
                  final db = await dbHelper.database;
                  await db.insert('transaksi', {
                    'tukangojek_id': selectedDriverId,
                    'harga': int.parse(hargaController.text),
                    'timestamp': DateTime.now().toIso8601String(),
                  });
                  Navigator.pop(context);
                }
              },
              child: Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

