import 'package:flutter/material.dart';

import '../../theme/tokens/tokens.dart';
import '../../widgets/chargix/premium_card.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & security')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenGutter),
        children: [
          PremiumCard(
            child: Text(
              'Chargix uses Firebase Authentication and Firestore with role-based access. '
              'Phone numbers are stored for account recovery. Location is used only while '
              'you use the map to find nearby chargers.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
