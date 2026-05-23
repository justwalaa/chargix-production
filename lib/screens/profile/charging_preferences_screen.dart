import 'package:flutter/material.dart';

import '../../core/app_settings_scope.dart';
import '../../theme/tokens/tokens.dart';
import '../../widgets/chargix/premium_card.dart';

class ChargingPreferencesScreen extends StatelessWidget {
  const ChargingPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Charging preferences')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenGutter),
        children: [
          PremiumCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  value: settings.preferFastCharging,
                  onChanged: settings.setPreferFastCharging,
                  secondary: Icon(Icons.bolt_rounded, color: scheme.primary),
                  title: const Text('Prefer fast charging'),
                  subtitle: const Text('Prioritize DC fast hubs in recommendations'),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: settings.autoBookNearest,
                  onChanged: settings.setAutoBookNearest,
                  secondary: Icon(Icons.near_me_rounded, color: scheme.primary),
                  title: const Text('Suggest nearest hub'),
                  subtitle: const Text('Surface closest available port on home'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
