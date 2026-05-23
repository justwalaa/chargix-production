import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/tokens/tokens.dart';
import '../../widgets/chargix/premium_card.dart';
import '../../widgets/chargix/settings_tile.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & support')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenGutter),
        children: [
          PremiumCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.help_outline_rounded,
                  title: 'FAQ',
                  subtitle: 'Charging, bookings, and fleet tips',
                  onTap: () => _showFaq(context),
                ),
                const Divider(height: 1),
                SettingsTile(
                  icon: Icons.mail_outline_rounded,
                  title: 'Email support',
                  subtitle: 'support@chargix.app',
                  onTap: () => _copy(context, 'support@chargix.app'),
                ),
                const Divider(height: 1),
                SettingsTile(
                  icon: Icons.phone_in_talk_rounded,
                  title: 'Jordan hotline',
                  subtitle: '+962 6 000 0000',
                  onTap: () => _copy(context, '+96260000000'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFaq(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('FAQ'),
          content: const SingleChildScrollView(
            child: Text(
              '• Book a slot from Map or Stations\n'
              '• Station owners approve bookings in the operator app\n'
              '• Enable location for nearby charger sorting\n'
              '• Save favorites for quick access',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _copy(BuildContext context, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied $value'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
