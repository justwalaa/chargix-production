import 'package:flutter/material.dart';

import '../../core/app_settings_controller.dart';
import '../../core/app_settings_scope.dart';
import '../../services/auth_service.dart';
import '../../theme/tokens/tokens.dart';
import '../../widgets/chargix/premium_card.dart';
import '../../widgets/chargix/settings_tile.dart';
import '../profile/charging_preferences_screen.dart';
import '../profile/privacy_security_screen.dart';
import '../splash/splash_screen.dart';

/// Preferences: appearance, notifications, language, and sign out.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenGutter,
          vertical: AppSpacing.screenVertical,
        ),
        children: [
          _sectionTitle(context, 'Experience'),
          const SizedBox(height: AppSpacing.sm),
          PremiumCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: isDark,
                  onChanged: (v) {
                    settings.setThemeMode(
                      v ? ThemeMode.dark : ThemeMode.light,
                    );
                  },
                  secondary: Icon(
                    isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: scheme.primary,
                  ),
                  title: const Text('Dark mode'),
                  subtitle: const Text('Soft premium theme across Chargix'),
                ),
                const Divider(height: 1),
                SwitchListTile.adaptive(
                  value: settings.notificationsEnabled,
                  onChanged: settings.setNotificationsEnabled,
                  secondary: Icon(
                    Icons.notifications_active_outlined,
                    color: scheme.primary,
                  ),
                  title: const Text('Push notifications'),
                  subtitle: const Text('Session updates and charging alerts'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.language_rounded, color: scheme.primary),
                  title: const Text('Language'),
                  subtitle: Text(settings.languageLabel),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _pickLanguage(context, settings),
                ),
                const Divider(height: 1),
                SettingsTile(
                  icon: Icons.tune_rounded,
                  title: 'Charging preferences',
                  onTap: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const ChargingPreferencesScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle(context, 'Privacy'),
          const SizedBox(height: AppSpacing.sm),
          PremiumCard(
            padding: EdgeInsets.zero,
            child: SettingsTile(
              icon: Icons.shield_outlined,
              title: 'Privacy & security',
              onTap: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const PrivacySecurityScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle(context, 'Account'),
          const SizedBox(height: AppSpacing.sm),
          PremiumCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: Icon(Icons.logout_rounded, color: scheme.error),
              title: Text(
                'Log out',
                style: TextStyle(
                  color: scheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: const Text('Sign out on this device'),
              onTap: () => _confirmLogout(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }

  Future<void> _pickLanguage(
    BuildContext context,
    AppSettingsController settings,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) {
        return AnimatedBuilder(
          animation: settings,
          builder: (ctx, _) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Text(
                        'Language',
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.language_rounded,
                        color: settings.languageCode == 'en'
                            ? Theme.of(ctx).colorScheme.primary
                            : null,
                      ),
                      title: const Text('English'),
                      trailing: settings.languageCode == 'en'
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: Theme.of(ctx).colorScheme.primary,
                            )
                          : null,
                      onTap: () {
                        settings.setLanguageCode('en');
                        Navigator.pop(ctx);
                      },
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.language_rounded,
                        color: settings.languageCode == 'ar'
                            ? Theme.of(ctx).colorScheme.primary
                            : null,
                      ),
                      title: const Text('العربية'),
                      trailing: settings.languageCode == 'ar'
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: Theme.of(ctx).colorScheme.primary,
                            )
                          : null,
                      onTap: () {
                        settings.setLanguageCode('ar');
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Log out?'),
          content: const Text('You will need to sign in again to use Chargix.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Log out'),
            ),
          ],
        );
      },
    );
    if (go != true || !context.mounted) {
      return;
    }
    await AuthService.instance.signOut();
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const SplashScreen(),
      ),
      (_) => false,
    );
  }
}
