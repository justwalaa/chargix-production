import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../admin/admin_dashboard_screen.dart';
import '../../data/chargix_data.dart';
import '../../models/user_model.dart';
import '../../theme/tokens/tokens.dart';
import '../../widgets/chargix/premium_card.dart';
import '../../widgets/chargix/settings_tile.dart';
import '../settings/settings_screen.dart';
import '../station/station_main_navigation.dart';
import 'charging_history_screen.dart';
import 'charging_preferences_screen.dart';
import 'favorites_screen.dart';
import 'help_support_screen.dart';
import 'payment_methods_screen.dart';
import 'privacy_security_screen.dart';
import 'vehicles_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final authUser = FirebaseAuth.instance.currentUser;
    final uid = authUser?.uid;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Please sign in to view your profile.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: StreamBuilder<UserModel?>(
        stream: ChargixData.users.watchCurrentUser(uid),
        builder: (context, snapshot) {
          final profile = snapshot.data;
          final phone = profile?.phoneE164 ?? authUser?.phoneNumber ?? '—';
          final name = profile?.displayName ?? 'Chargix driver';
          final isOwner = profile?.role.isStation == true;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screenGutter),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: scheme.primaryContainer,
                    foregroundColor: scheme.onPrimaryContainer,
                    child: const Icon(Icons.person_rounded, size: 40),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          phone,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              _sectionTitle(context, 'EV & charging'),
              const SizedBox(height: AppSpacing.sm),
              PremiumCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SettingsTile(
                      icon: Icons.electric_car_rounded,
                      title: 'My vehicles',
                      subtitle: 'Manage EV profiles',
                      onTap: () => _push(context, const VehiclesScreen()),
                    ),
                    const Divider(height: 1),
                    SettingsTile(
                      icon: Icons.tune_rounded,
                      title: 'Charging preferences',
                      onTap: () =>
                          _push(context, const ChargingPreferencesScreen()),
                    ),
                    const Divider(height: 1),
                    SettingsTile(
                      icon: Icons.bookmark_rounded,
                      title: 'Saved stations',
                      onTap: () => _push(context, const FavoritesScreen()),
                    ),
                    const Divider(height: 1),
                    SettingsTile(
                      icon: Icons.bolt_rounded,
                      title: 'Charging history',
                      onTap: () =>
                          _push(context, const ChargingHistoryScreen()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _sectionTitle(context, 'Account'),
              const SizedBox(height: AppSpacing.sm),
              PremiumCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SettingsTile(
                      icon: Icons.credit_card_rounded,
                      title: 'Payment methods',
                      subtitle: 'Cards & wallets (coming soon)',
                      onTap: () =>
                          _push(context, const PaymentMethodsScreen()),
                    ),
                    const Divider(height: 1),
                    SettingsTile(
                      icon: Icons.settings_rounded,
                      title: 'Settings',
                      subtitle: 'Theme, language, notifications',
                      onTap: () => _push(context, const SettingsScreen()),
                    ),
                    const Divider(height: 1),
                    SettingsTile(
                      icon: Icons.help_outline_rounded,
                      title: 'Help & support',
                      onTap: () => _push(context, const HelpSupportScreen()),
                    ),
                    const Divider(height: 1),
                    SettingsTile(
                      icon: Icons.shield_outlined,
                      title: 'Privacy & security',
                      onTap: () =>
                          _push(context, const PrivacySecurityScreen()),
                    ),
                  ],
                ),
              ),
              if (isOwner) ...[
                const SizedBox(height: AppSpacing.xl),
                _sectionTitle(context, 'Station operator'),
                const SizedBox(height: AppSpacing.sm),
                PremiumCard(
                  child: SettingsTile(
                    icon: Icons.storefront_rounded,
                    title: 'Station dashboard',
                    subtitle: 'Manage slots, bookings, pricing',
                    onTap: () {
                      final stationId = profile?.stationId ?? uid;
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              StationMainNavigation(stationId: stationId),
                        ),
                      );
                    },
                  ),
                ),
              ],
              if (authUser?.email == 'walaamarie363@gmail.com') ...[
                const SizedBox(height: AppSpacing.xl),

                _sectionTitle(context, 'Admin'),

                const SizedBox(height: AppSpacing.sm),

                PremiumCard(
                  child: SettingsTile(
                    icon: Icons.admin_panel_settings_rounded,
                    title: 'Admin Dashboard',
                    subtitle: 'Review pending stations',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminDashboardScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          );
        },
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

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }
}
