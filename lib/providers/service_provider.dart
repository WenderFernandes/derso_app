import 'package:flutter/material.dart';

import '../models/service.dart';
import '../services/database_service.dart';

/// Provedor que gerencia a lista de serviços do usuário atual.
class ServiceProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  List<Service> _services = [];
  List<Service> get services => List.unmodifiable(_services);

  int? _userId;

  /// Inicializa o provedor carregando serviços para o usuário indicado.
  Future<void> loadServices(int userId) async {
    _userId = userId;
    _services = await _dbService.getServicesByUser(userId);
    notifyListeners();
  }

  /// Adiciona um novo serviço ao banco de dados e atualiza a lista local.
  Future<int> addService(Service service) async {
    final id = await _dbService.insertService(service);
    _services.add(service.copyWith(id: id));
    notifyListeners();
    return id;
  }

  /// Atualiza um serviço existente.
  Future<void> updateService(Service service) async {
    await _dbService.updateService(service);
    final index = _services.indexWhere((s) => s.id == service.id);
    if (index != -1) {
      _services[index] = service;
      notifyListeners();
    }
  }

  /// Remove um serviço (apenas se não foi recebido).
  Future<bool> deleteService(int id) async {
    final service = _services.firstWhere((s) => s.id == id);
    if (service.received) {
      return false; // Não pode excluir serviço já recebido
    }
    
    await _dbService.deleteService(id);
    _services.removeWhere((s) => s.id == id);
    notifyListeners();
    return true;
  }

  /// Marca/desmarca serviço como realizado.
  Future<void> toggleRealized(Service service) async {
    final updated = service.copyWith(
      realized: !service.realized,
      received: service.realized ? false : service.received, // Se desmarcar realizado, desmarca recebido
    );
    await updateService(updated);
  }

  /// Marca serviço como recebido (só se já estiver realizado).
  Future<bool> markAsReceived(Service service, DateTime paymentDate) async {
    if (!service.realized) {
      return false; // Não pode receber sem realizar
    }
    
    final updated = service.copyWith(
      received: true,
      paymentDate: paymentDate,
    );
    await updateService(updated);
    return true;
  }

  /// Desmarca serviço como recebido.
  Future<void> unmarkAsReceived(Service service) async {
    final updated = service.copyWith(
      received: false,
      paymentDate: null,
    );
    await updateService(updated);
  }
}