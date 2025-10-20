import 'dart:async';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/user.dart';
import '../models/service.dart';

/// Serviço responsável por gerenciar a persistência de dados no SQLite.
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
      version: 2, // Incrementada versão para migrations
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  FutureOr<void> _onCreate(Database db, int version) async {
    // Tabela de usuários
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        nickName TEXT NOT NULL,
        matricula TEXT NOT NULL UNIQUE,
        cpf TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');

    // Tabela de serviços com campo received
    await db.execute('''
      CREATE TABLE services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        period TEXT NOT NULL,
        value REAL NOT NULL,
        realized INTEGER NOT NULL DEFAULT 0,
        received INTEGER NOT NULL DEFAULT 0,
        paymentDate TEXT,
        userId INTEGER NOT NULL,
        FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
  }

  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Adiciona coluna received se não existir
      await db.execute('''
        ALTER TABLE services ADD COLUMN received INTEGER NOT NULL DEFAULT 0
      ''');
      
      // Garante que matrícula seja UNIQUE
      await db.execute('''
        CREATE UNIQUE INDEX IF NOT EXISTS idx_users_matricula ON users(matricula)
      ''');
    }
  }

  // -------------------- Usuários --------------------
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  /// Retorna o usuário com o e-mail fornecido.
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

  /// Retorna o usuário com a matrícula fornecida (usado para login).
  Future<User?> getUserByMatricula(String matricula) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'matricula = ?',
      whereArgs: [matricula],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  /// Atualiza um usuário existente.
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