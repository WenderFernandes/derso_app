import 'dart:async';
import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/subscription_plan.dart';
import '../models/user_subscription.dart';

class BillingService {
  static final BillingService _instance = BillingService._internal();
  factory BillingService() => _instance;
  BillingService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  
  bool _isAvailable = false;
  List<ProductDetails> _products = [];
  List<PurchaseDetails> _purchases = [];
  
  final _purchaseUpdatedController = StreamController<PurchaseDetails>.broadcast();
  Stream<PurchaseDetails> get purchaseUpdated => _purchaseUpdatedController.stream;

  bool get isAvailable => _isAvailable;
  List<ProductDetails> get products => _products;

  Future<void> init() async {
    _isAvailable = await _iap.isAvailable();
    
    if (!_isAvailable) {
      print('In-app purchase não está disponível neste dispositivo');
      return;
    }

    // Habilitar compras pendentes para Android
    if (Platform.isAndroid) {
      // O InAppPurchase já gerencia isso internamente
      // Não é mais necessário chamar enablePendingPurchases separadamente
    }

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription.cancel(),
      onError: (error) => print('Erro no stream de compras: $error'),
    );

    await _loadProducts();
    await _restorePurchases();
  }

  Future<void> _loadProducts() async {
    final Set<String> productIds = {
      SubscriptionPlan.monthly.id,
      SubscriptionPlan.annual.id,
    };

    final ProductDetailsResponse response = await _iap.queryProductDetails(productIds);

    if (response.notFoundIDs.isNotEmpty) {
      print('Produtos não encontrados: ${response.notFoundIDs}');
    }

    if (response.error != null) {
      print('Erro ao carregar produtos: ${response.error}');
      return;
    }

    _products = response.productDetails;
    print('${_products.length} produtos carregados');
  }

  Future<bool> buyMonthly() async {
    return await _buyProduct(SubscriptionPlan.monthly.id);
  }

  Future<bool> buyAnnual() async {
    return await _buyProduct(SubscriptionPlan.annual.id);
  }

  Future<bool> _buyProduct(String productId) async {
    if (!_isAvailable) {
      print('Billing não disponível');
      return false;
    }

    final product = _products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception('Produto não encontrado: $productId'),
    );

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    
    try {
      final bool success = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      return success;
    } catch (e) {
      print('Erro ao comprar produto: $e');
      return false;
    }
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      await _handlePurchase(purchaseDetails);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
    print('Status da compra: ${purchaseDetails.status}');

    if (purchaseDetails.status == PurchaseStatus.pending) {
      // Compra pendente - aguardando confirmação
      _purchaseUpdatedController.add(purchaseDetails);
    } else if (purchaseDetails.status == PurchaseStatus.error) {
      // Erro na compra
      print('Erro na compra: ${purchaseDetails.error}');
      _purchaseUpdatedController.add(purchaseDetails);
    } else if (purchaseDetails.status == PurchaseStatus.purchased ||
               purchaseDetails.status == PurchaseStatus.restored) {
      // Compra bem-sucedida ou restaurada
      await _verifyAndDeliverPurchase(purchaseDetails);
      _purchaseUpdatedController.add(purchaseDetails);
    }

    // Completar a compra para que não apareça novamente
    if (purchaseDetails.pendingCompletePurchase) {
      await _iap.completePurchase(purchaseDetails);
    }
  }

  Future<void> _verifyAndDeliverPurchase(PurchaseDetails purchaseDetails) async {
    // Aqui você deve verificar a compra com seu backend
    // Por enquanto, vamos apenas salvar localmente
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium', true);
    await prefs.setString('purchase_token', purchaseDetails.verificationData.serverVerificationData);
    await prefs.setString('product_id', purchaseDetails.productID);
    await prefs.setString('purchase_date', DateTime.now().toIso8601String());

    // Calcular data de expiração baseada no produto
    DateTime endDate;
    if (purchaseDetails.productID == SubscriptionPlan.monthly.id) {
      endDate = DateTime.now().add(const Duration(days: 30));
    } else {
      endDate = DateTime.now().add(const Duration(days: 365));
    }
    await prefs.setString('subscription_end_date', endDate.toIso8601String());

    print('Compra verificada e entregue: ${purchaseDetails.productID}');
  }

  Future<void> _restorePurchases() async {
    try {
      await _iap.restorePurchases();
      print('Compras restauradas com sucesso');
    } catch (e) {
      print('Erro ao restaurar compras: $e');
    }
  }

  Future<void> restorePurchases() async {
    await _restorePurchases();
  }

  Future<bool> checkSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isPremium = prefs.getBool('is_premium') ?? false;
    
    if (!isPremium) return false;

    final endDateStr = prefs.getString('subscription_end_date');
    if (endDateStr == null) return false;

    final endDate = DateTime.parse(endDateStr);
    final isActive = DateTime.now().isBefore(endDate);

    if (!isActive) {
      // Assinatura expirada
      await prefs.setBool('is_premium', false);
      return false;
    }

    return true;
  }

  Future<UserSubscription?> getCurrentSubscription(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final isPremium = prefs.getBool('is_premium') ?? false;
    
    if (!isPremium) return null;

    final productId = prefs.getString('product_id');
    final purchaseToken = prefs.getString('purchase_token');
    final purchaseDateStr = prefs.getString('purchase_date');
    final endDateStr = prefs.getString('subscription_end_date');

    if (productId == null || purchaseDateStr == null || endDateStr == null) {
      return null;
    }

    final purchaseDate = DateTime.parse(purchaseDateStr);
    final endDate = DateTime.parse(endDateStr);
    final isActive = DateTime.now().isBefore(endDate);

    return UserSubscription(
      userId: userId,
      planId: productId,
      startDate: purchaseDate,
      endDate: endDate,
      status: isActive ? SubscriptionStatus.active : SubscriptionStatus.expired,
      purchaseToken: purchaseToken,
    );
  }

  Future<void> startTrial(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final trialStarted = prefs.getBool('trial_started') ?? false;

    if (trialStarted) {
      print('Trial já foi iniciado anteriormente');
      return;
    }

    final startDate = DateTime.now();
    final endDate = startDate.add(const Duration(days: 7));

    await prefs.setBool('trial_started', true);
    await prefs.setBool('is_premium', true);
    await prefs.setString('product_id', SubscriptionPlan.trial.id);
    await prefs.setString('purchase_date', startDate.toIso8601String());
    await prefs.setString('subscription_end_date', endDate.toIso8601String());

    print('Trial iniciado: $startDate até $endDate');
  }

  Future<bool> hasUsedTrial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('trial_started') ?? false;
  }

  ProductDetails? getProduct(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _subscription.cancel();
    _purchaseUpdatedController.close();
  }
}