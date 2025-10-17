import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/database_service.dart';

/// Provedor responsável por armazenar o usuário atual e gerenciar login/
/// cadastro.
class UserProvider extends ChangeNotifier {
  User? _user;
  User? get user => _user;

  final DatabaseService _dbService = DatabaseService();

  /// Realiza o cadastro de um novo usuário. Retorna true em caso de sucesso ou
  /// false se o e‑mail já estiver em uso.
  Future<bool> register({
    required String name,
    required String nickName,
    required String matricula,
    required String cpf,
    required String email,
    required String password,
  }) async {
    // Verifica se já existe um usuário com o e‑mail informado
    final existing = await _dbService.getUserByEmail(email);
    if (existing != null) {
      return false;
    }
    final user = User(
      name: name,
      nickName: nickName,
      matricula: matricula,
      cpf: cpf,
      email: email,
      password: password,
    );
    final id = await _dbService.insertUser(user);
    _user = user.copyWith(id: id);
    notifyListeners();
    return true;
  }

  /// Efetua o login buscando um usuário pelo e‑mail e verificando a senha.
  Future<bool> login(String email, String password) async {
    final user = await _dbService.getUserByEmail(email);
    if (user != null && user.password == password) {
      _user = user;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Desloga o usuário atual.
  void logout() {
    _user = null;
    notifyListeners();
  }
}

extension on User {
  User copyWith({
    int? id,
    String? name,
    String? nickName,
    String? matricula,
    String? cpf,
    String? email,
    String? password,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      nickName: nickName ?? this.nickName,
      matricula: matricula ?? this.matricula,
      cpf: cpf ?? this.cpf,
      email: email ?? this.email,
      password: password ?? this.password,
    );
  }
}