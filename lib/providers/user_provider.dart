import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import '../models/user.dart';
import '../services/database_service.dart';

/// Provedor responsável por armazenar o usuário atual e gerenciar login/cadastro.
class UserProvider extends ChangeNotifier {
  User? _user;
  User? get user => _user;

  final DatabaseService _dbService = DatabaseService();

  /// Hash da senha usando SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Realiza o cadastro de um novo usuário.
  Future<bool> register({
    required String name,
    required String nickName,
    required String matricula,
    required String cpf,
    required String email,
    required String password,
  }) async {
    // Verifica se já existe um usuário com o e-mail ou matrícula
    final existingEmail = await _dbService.getUserByEmail(email);
    if (existingEmail != null) {
      return false;
    }
    
    final existingMatricula = await _dbService.getUserByMatricula(matricula);
    if (existingMatricula != null) {
      return false;
    }

    final user = User(
      name: name,
      nickName: nickName,
      matricula: matricula,
      cpf: cpf,
      email: email,
      password: _hashPassword(password),
    );
    final id = await _dbService.insertUser(user);
    _user = user.copyWith(id: id);
    notifyListeners();
    return true;
  }

  /// Efetua o login usando matrícula e senha.
  Future<bool> login(String matricula, String password) async {
    final user = await _dbService.getUserByMatricula(matricula);
    if (user != null && user.password == _hashPassword(password)) {
      _user = user;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Atualiza os dados do perfil do usuário.
  Future<bool> updateProfile({
    required String name,
    required String nickName,
    required String cpf,
    required String email,
  }) async {
    if (_user == null) return false;

    // Verifica se o e-mail já está em uso por outro usuário
    final existingEmail = await _dbService.getUserByEmail(email);
    if (existingEmail != null && existingEmail.id != _user!.id) {
      return false;
    }

    final updatedUser = _user!.copyWith(
      name: name,
      nickName: nickName,
      cpf: cpf,
      email: email,
    );

    await _dbService.updateUser(updatedUser);
    _user = updatedUser;
    notifyListeners();
    return true;
  }

  /// Altera a senha do usuário.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_user == null) return false;
    
    if (_user!.password != _hashPassword(currentPassword)) {
      return false;
    }

    final updatedUser = _user!.copyWith(
      password: _hashPassword(newPassword),
    );

    await _dbService.updateUser(updatedUser);
    _user = updatedUser;
    notifyListeners();
    return true;
  }

  /// Desloga o usuário atual.
  void logout() {
    _user = null;
    notifyListeners();
  }
}