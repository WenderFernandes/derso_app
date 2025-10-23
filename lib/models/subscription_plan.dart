class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final int durationDays;
  final bool isTrial;
  final List<String> features;
  final String? discountText;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationDays,
    this.isTrial = false,
    required this.features,
    this.discountText,
  });

  String get priceFormatted => 'R\$ ${price.toStringAsFixed(2)}';

  static SubscriptionPlan get trial => SubscriptionPlan(
        id: 'trial',
        name: 'Teste Gratuito',
        description: '7 dias de acesso completo',
        price: 0.0,
        durationDays: 7,
        isTrial: true,
        features: [
          'Acesso completo por 7 dias',
          'Todos os recursos disponíveis',
          'Sem compromisso',
        ],
      );

  static SubscriptionPlan get monthly => SubscriptionPlan(
        id: 'derso_premium_mensal',
        name: 'Mensal',
        description: 'Renovação automática',
        price: 5.0,
        durationDays: 30,
        features: [
          'Acesso completo ilimitado',
          'Notificações push',
          'Exportação de relatórios',
          'Sincronização em nuvem',
          'Suporte prioritário',
        ],
      );

  static SubscriptionPlan get annual => SubscriptionPlan(
        id: 'derso_premium_anual',
        name: 'Anual',
        description: '10 meses pagos + 2 grátis',
        price: 50.0,
        durationDays: 365,
        features: [
          'Acesso completo ilimitado',
          'Notificações push',
          'Exportação de relatórios',
          'Sincronização em nuvem',
          'Suporte prioritário',
          '2 meses grátis',
        ],
        discountText: 'Economize 17%',
      );

  static List<SubscriptionPlan> get allPlans => [trial, monthly, annual];
}