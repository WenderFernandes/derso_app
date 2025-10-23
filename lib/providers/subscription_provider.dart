import 'package:flutter/material.dart';

import '../models/user_subscription.dart';
import '../services/billing_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  final BillingService _billingService = BillingService();
  
  UserSubscription? _currentSubscription;
  bool _isLoading = false;
  String? _error;

  UserSubscription? get currentSubscription => _currentSubscription;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isPremium => _currentSubscription?.isActive ?? false;
  bool get hasActiveSubscription => isPremium;

  Future<void> init(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _billingService.init();
      await loadSubscription(userId);
    } catch (e) {
      _error = 'Erro ao inicializar billing: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSubscription(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentSubscription = await _billingService.getCurrentSubscription(userId);
      _error = null;
    } catch (e) {
      _error = 'Erro ao carregar assinatura: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> startTrial(int userId) async {
    final hasUsedTrial = await _billingService.hasUsedTrial();
    if (hasUsedTrial) {
      _error = 'Você já utilizou o período de teste';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _billingService.startTrial(userId);
      await loadSubscription(userId);
      _error = null;
      return true;
    } catch (e) {
      _error = 'Erro ao iniciar teste: $e';
      print(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> buyMonthly() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _billingService.buyMonthly();
      return success;
    } catch (e) {
      _error = 'Erro ao comprar plano mensal: $e';
      print(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> buyAnnual() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _billingService.buyAnnual();
      return success;
    } catch (e) {
      _error = 'Erro ao comprar plano anual: $e';
      print(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> restorePurchases(int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _billingService.restorePurchases();
      await Future.delayed(const Duration(seconds: 2)); // Aguarda processamento
      await loadSubscription(userId);
    } catch (e) {
      _error = 'Erro ao restaurar compras: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> checkSubscriptionStatus() async {
    try {
      return await _billingService.checkSubscriptionStatus();
    } catch (e) {
      print('Erro ao verificar status: $e');
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}