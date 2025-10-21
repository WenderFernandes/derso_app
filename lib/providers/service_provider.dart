import 'package:flutter/material.dart';

import '../models/service.dart';
import '../services/database_service.dart';

class ServiceProvider extends ChangeNotifier {
  List<Service> _services = [];
  List<Service> get services => _services;

  final DatabaseService _dbService = DatabaseService();

  Future<void> loadServices(int userId) async {
    _services = await _dbService.getServicesByUser(userId);
    notifyListeners();
  }

  Future<int> addService(Service service) async {
    final id = await _dbService.insertService(service);
    final newService = service.copyWith(id: id);
    _services.add(newService);
    notifyListeners();
    return id;
  }

  Future<void> updateService(Service service) async {
    await _dbService.updateService(service);
    final index = _services.indexWhere((s) => s.id == service.id);
    if (index != -1) {
      _services[index] = service;
      notifyListeners();
    }
  }

  Future<bool> deleteService(int id) async {
    final service = _services.firstWhere((s) => s.id == id);
    if (service.received) {
      return false;
    }
    await _dbService.deleteService(id);
    _services.removeWhere((s) => s.id == id);
    notifyListeners();
    return true;
  }

  Future<void> toggleRealized(Service service) async {
    final updated = service.copyWith(realized: !service.realized);
    await updateService(updated);
  }

  Future<bool> markAsReceived(Service service, DateTime paymentDate) async {
    if (!service.realized) {
      return false;
    }
    final updated = service.copyWith(
      received: true,
      paymentDate: paymentDate,
    );
    await updateService(updated);
    return true;
  }

  Future<void> unmarkAsReceived(Service service) async {
    final updated = service.copyWith(
      received: false,
      paymentDate: null,
    );
    await updateService(updated);
  }
}