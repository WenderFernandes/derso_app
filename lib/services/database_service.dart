import 'dart:async';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/user.dart';
import '../models/service.dart';

/// Serviço responsável por gerenciar a persistência de dados no SQLite.
///
/// O plugin sqflite fornece uma API para SQLite em Flutter, suportando
/// transações, versionamento automático e execução assíncrona de operações
/// em background【114368758526521†L69-L78】.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'derso.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  FutureOr<void> _onCreate(Database db, int version) async {
    // Tabela de usuários
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        nickName TEXT NOT NULL,
        matricula TEXT NOT NULL,
        cpf TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');

    // Tabela de serviços
    await db.execute('''
      CREATE TABLE services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        period TEXT NOT NULL,
        value REAL NOT NULL,
        realized INTEGER NOT NULL,
        paymentDate TEXT,
        userId INTEGER NOT NULL,
        FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
  }

  // -------------------- Usuários --------------------
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  /// Retorna o usuário com o e‑mail fornecido. Útil para autenticação.
  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  /// Atualiza um usuário existente. Retorna o número de linhas afetadas.
  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // -------------------- Serviços --------------------
  Future<int> insertService(Service service) async {
    final db = await database;
    return await db.insert('services', service.toMap());
  }

  Future<List<Service>> getServicesByUser(int userId) async {
    final db = await database;
    final maps = await db.query(
      'services',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date ASC, startTime ASC',
    );
    return maps.map((map) => Service.fromMap(map)).toList();
  }

  Future<int> updateService(Service service) async {
    final db = await database;
    return await db.update(
      'services',
      service.toMap(),
      where: 'id = ?',
      whereArgs: [service.id],
    );
  }

  Future<int> deleteService(int id) async {
    final db = await database;
    return await db.delete(
      'services',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}