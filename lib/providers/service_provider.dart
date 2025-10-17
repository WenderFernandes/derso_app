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
  Future<void> addService(Service service) async {
    final id = await _dbService.insertService(service);
    _services.add(service.copyWith(id: id));
    notifyListeners();
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

  /// Remove um serviço.
  Future<void> deleteService(int id) async {
    await _dbService.deleteService(id);
    _services.removeWhere((s) => s.id == id);
    notifyListeners();
  }
}

extension on Service {
  Service copyWith({
    int? id,
    DateTime? date,
    String? startTime,
    String? endTime,
    String? period,
    double? value,
    bool? realized,
    DateTime? paymentDate,
    int? userId,
  }) {
    return Service(
      id: id ?? this.id,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      period: period ?? this.period,
      value: value ?? this.value,
      realized: realized ?? this.realized,
      paymentDate: paymentDate ?? this.paymentDate,
      userId: userId ?? this.userId,
    );
  }
}