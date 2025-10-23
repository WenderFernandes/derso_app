import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/subscription_plan.dart';
import '../providers/subscription_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/gradient_header.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({Key? key}) : super(key: key);

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  int _selectedPlanIndex = 1; // Mensal por padrão

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<UserProvider>().user;
      if (user != null) {
        context.read<SubscriptionProvider>().loadSubscription(user.id!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subscriptionProvider = context.watch<SubscriptionProvider>();
    final userProvider = context.watch<UserProvider>();
    final currentSubscription = subscriptionProvider.currentSubscription;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assinaturas'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          const GradientHeader(title: 'Assinatura DERSO'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status da assinatura atual
                  if (currentSubscription != null && currentSubscription.isActive)
                    _buildCurrentSubscriptionCard(
                      theme,
                      currentSubscription,
                    ),

                  if (currentSubscription != null && currentSubscription.isActive)
                    const SizedBox(height: 24),

                  // Título
                  Text(
                    'Escolha seu plano',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Desbloqueie todos os recursos premium',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Cards de planos
                  _buildPlanCard(
                    theme,
                    SubscriptionPlan.trial,
                    0,
                    subscriptionProvider,
                    userProvider,
                  ),
                  const SizedBox(height: 16),
                  _buildPlanCard(
                    theme,
                    SubscriptionPlan.monthly,
                    1,
                    subscriptionProvider,
                    userProvider,
                  ),
                  const SizedBox(height: 16),
                  _buildPlanCard(
                    theme,
                    SubscriptionPlan.annual,
                    2,
                    subscriptionProvider,
                    userProvider,
                  ),
                  const SizedBox(height: 32),

                  // Botão de restaurar compras
                  Center(
                    child: TextButton.icon(
                      onPressed: subscriptionProvider.isLoading
                          ? null
                          : () async {
                              final user = userProvider.user;
                              if (user != null) {
                                await subscriptionProvider.restorePurchases(user.id!);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Compras restauradas'),
                                    ),
                                  );
                                }
                              }
                            },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Restaurar Assinaturas'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Informações legais
                  _buildLegalInfo(theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSubscriptionCard(
    ThemeData theme,
    dynamic subscription,
  ) {
    final plan = SubscriptionPlan.allPlans.firstWhere(
      (p) => p.id == subscription.planId,
      orElse: () => SubscriptionPlan.trial,
    );

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: theme.colorScheme.primary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plano Ativo',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        plan.name,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    theme,
                    'Válido até',
                    DateFormat('dd/MM/yyyy').format(subscription.endDate),
                  ),
                  const Divider(height: 16),
                  _buildInfoRow(
                    theme,
                    'Dias restantes',
                    '${subscription.remainingDays} dias',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(
    ThemeData theme,
    SubscriptionPlan plan,
    int index,
    SubscriptionProvider subscriptionProvider,
    UserProvider userProvider,
  ) {
    final isSelected = _selectedPlanIndex == index;
    final isPopular = index == 2; // Anual é popular

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPlanIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withOpacity(0.3),
                width: isSelected ? 3 : 1,
              ),
              color: isSelected
                  ? theme.colorScheme.primary.withOpacity(0.05)
                  : theme.colorScheme.surface,
            ),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          plan.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.primary,
                        size: 32,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Preço
                if (plan.price > 0)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        plan.priceFormatted,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          plan.id.contains('mensal') ? '/mês' : '/ano',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'GRATUITO',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),

                if (plan.discountText != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      plan.discountText!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Features
                ...plan.features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feature,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    )),

                const SizedBox(height: 16),

                // Botão de ação
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: subscriptionProvider.isLoading
                        ? null
                        : () => _handleSubscribe(
                              plan,
                              subscriptionProvider,
                              userProvider,
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceVariant,
                      foregroundColor: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: subscriptionProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _getButtonText(plan, subscriptionProvider),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          if (isPopular)
            Positioned(
              top: 0,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(8),
                  ),
                ),
                child: const Text(
                  'MAIS POPULAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getButtonText(
    SubscriptionPlan plan,
    SubscriptionProvider subscriptionProvider,
  ) {
    if (subscriptionProvider.currentSubscription?.planId == plan.id &&
        subscriptionProvider.currentSubscription!.isActive) {
      return 'Plano Ativo';
    }

    if (plan.isTrial) {
      return 'Iniciar Teste Gratuito';
    }

    return 'Assinar Agora';
  }

  Future<void> _handleSubscribe(
    SubscriptionPlan plan,
    SubscriptionProvider subscriptionProvider,
    UserProvider userProvider,
  ) async {
    final user = userProvider.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário não encontrado')),
      );
      return;
    }

    // Se já tem esse plano ativo, não faz nada
    if (subscriptionProvider.currentSubscription?.planId == plan.id &&
        subscriptionProvider.currentSubscription!.isActive) {
      return;
    }

    bool success = false;

    if (plan.isTrial) {
      success = await subscriptionProvider.startTrial(user.id!);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teste gratuito iniciado! Aproveite por 7 dias.'),
          ),
        );
      }
    } else if (plan.id == SubscriptionPlan.monthly.id) {
      success = await subscriptionProvider.buyMonthly();
    } else if (plan.id == SubscriptionPlan.annual.id) {
      success = await subscriptionProvider.buyAnnual();
    }

    if (!success && subscriptionProvider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(subscriptionProvider.error!)),
      );
    }
  }

  Widget _buildLegalInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informações sobre assinaturas',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• As assinaturas são renovadas automaticamente\n'
            '• Você pode cancelar a qualquer momento\n'
            '• O cancelamento entra em vigor no final do período\n'
            '• Gerenciado pela Google Play Store',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}