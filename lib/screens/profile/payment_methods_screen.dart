import 'package:flutter/material.dart';

import '../../theme/tokens/tokens.dart';
import '../../widgets/chargix/premium_card.dart';

/// Payment methods placeholder — ready for Stripe / local wallets.
class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Payment methods')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenGutter),
        children: [
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.credit_card_rounded, color: scheme.primary, size: 32),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Payments coming soon',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Chargix will support cards and mobile wallets for session billing. Your charging history is tracked in Firestore today.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment provider integration is planned.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.add_card_rounded),
            label: const Text('Add payment method'),
          ),
        ],
      ),
    );
  }
}
