import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/subscription_provider.dart';
import '../pages/subscription_page.dart';

class PaywallWidget extends StatelessWidget {
  final Widget child;
  final String? message;

  const PaywallWidget({
    Key? key,
    required this.child,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = context.watch<SubscriptionProvider>();

    if (subscriptionProvider.isPremium) {
      return child;
    }

    return _buildPaywall(context);
  }

  Widget _buildPaywall(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'Recurso Premium',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                message ??
                    'Este recurso está disponível apenas para usuários premium. Assine agora para desbloquear todas as funcionalidades.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text('Ver Planos'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Voltar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mixin para facilitar verificação de premium em páginas
mixin PremiumCheck {
  Future<bool> checkPremiumAccess(BuildContext context) async {
    final subscriptionProvider = context.read<SubscriptionProvider>();
    
    if (!subscriptionProvider.isPremium) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const SubscriptionPage(),
        ),
      );
      return false;
    }
    
    return true;
  }

  void showPremiumDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recurso Premium'),
        content: Text(
          message ??
              'Este recurso está disponível apenas para usuários premium.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SubscriptionPage(),
                ),
              );
            },
            child: const Text('Ver Planos'),
          ),
        ],
      ),
    );
  }
}