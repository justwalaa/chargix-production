import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../admin/admin_dashboard_screen.dart';
import '../../data/chargix_data.dart';
import '../../models/user_model.dart';
import '../../widgets/chargix/settings_tile.dart';
import '../settings/settings_screen.dart';
import 'charging_history_screen.dart';
import 'charging_preferences_screen.dart';
import 'favorites_screen.dart';
import 'help_support_screen.dart';
import 'payment_methods_screen.dart';
import 'privacy_security_screen.dart';
import 'vehicles_screen.dart';

const _green        = Color(0xFF22C55E);
const _greenDark    = Color(0xFF16A34A);
const _greenSurface = Color(0xFFDCFCE7);
const _canvas       = Color(0xFFF8F9FA);
const _white        = Color(0xFFFFFFFF);
const _ink          = Color(0xFF101828);
const _slate        = Color(0xFF6B7280);
const _border       = Color(0xFFE5E7EB);

TextStyle _sg(double size, FontWeight w,
    {Color color = _ink, double ls = 0}) =>
    GoogleFonts.spaceGrotesk(
        fontSize: size, fontWeight: w, color: color, letterSpacing: ls);

TextStyle _dm(double size, FontWeight w, {Color color = _ink, double? h}) =>
    GoogleFonts.dmSans(fontSize: size, fontWeight: w, color: color, height: h);

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authUser = FirebaseAuth.instance.currentUser;
    final uid = authUser?.uid;
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    if (uid == null) {
      return Scaffold(
        backgroundColor: _canvas,
        body: Center(
          child: Text('Please sign in to view your profile.',
              style: _dm(14, FontWeight.w400, color: _slate)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _canvas,
      body: StreamBuilder<UserModel?>(
        stream: ChargixData.users.watchCurrentUser(uid),
        builder: (context, snap) {
          final profile = snap.data;
          final phone =
              profile?.phoneE164 ?? authUser?.phoneNumber ?? '—';
          final name = profile?.displayName ?? 'Chargix Driver';
          final initials = _initials(name);
          final isAdmin =
              authUser?.email == 'walaamarie363@gmail.com';

          return CustomScrollView(
            slivers: [
              // ── Hero header ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  color: _white,
                  padding: EdgeInsets.fromLTRB(20, topPad + 20, 20, 24),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF4ADE80),
                              Color(0xFF16A34A),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _green.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initials,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(name, style: _sg(20, FontWeight.w800, ls: -0.4)),
                      const SizedBox(height: 4),
                      Text(phone,
                          style: _dm(13, FontWeight.w400, color: _slate)),
                      const SizedBox(height: 16),
                      // Verified badge — only shown when earned
                      if (profile?.isVerifiedDriver == true)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: _greenSurface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(PhosphorIconsFill.sealCheck,
                                  size: 13, color: _greenDark),
                              const SizedBox(width: 5),
                              Text('Verified driver',
                                  style: _dm(11, FontWeight.w600,
                                      color: _greenDark)),
                            ],
                          ),
                        ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 380.ms)
                    .slideY(begin: -0.05, end: 0, duration: 380.ms,
                        curve: Curves.easeOut),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(
                    children: [
                      // ── EV & charging ──────────────────────────────
                      _SectionLabel('EV & Charging'),
                      const SizedBox(height: 8),
                      _MenuCard(
                        tiles: [
                          SettingsTile(
                            icon: PhosphorIconsRegular.car,
                            title: 'My vehicles',
                            subtitle: 'Manage EV profiles',
                            onTap: () => _push(context, const VehiclesScreen()),
                          ),
                          SettingsTile(
                            icon: PhosphorIconsRegular.sliders,
                            title: 'Charging preferences',
                            onTap: () => _push(
                                context, const ChargingPreferencesScreen()),
                          ),
                          SettingsTile(
                            icon: PhosphorIconsRegular.bookmarkSimple,
                            title: 'Saved stations',
                            onTap: () =>
                                _push(context, const FavoritesScreen()),
                          ),
                          SettingsTile(
                            icon: PhosphorIconsRegular.lightning,
                            title: 'Charging history',
                            onTap: () =>
                                _push(context, const ChargingHistoryScreen()),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── Account ─────────────────────────────────────
                      _SectionLabel('Account'),
                      const SizedBox(height: 8),
                      _MenuCard(
                        tiles: [
                          SettingsTile(
                            icon: PhosphorIconsRegular.creditCard,
                            title: 'Payment methods',
                            subtitle: 'Cards & wallets (coming soon)',
                            onTap: () =>
                                _push(context, const PaymentMethodsScreen()),
                          ),
                          SettingsTile(
                            icon: PhosphorIconsRegular.gear,
                            title: 'Settings',
                            subtitle: 'Theme, language, notifications',
                            onTap: () =>
                                _push(context, const SettingsScreen()),
                          ),
                          SettingsTile(
                            icon: PhosphorIconsRegular.question,
                            title: 'Help & support',
                            onTap: () =>
                                _push(context, const HelpSupportScreen()),
                          ),
                          SettingsTile(
                            icon: PhosphorIconsRegular.shieldCheck,
                            title: 'Privacy & security',
                            onTap: () =>
                                _push(context, const PrivacySecurityScreen()),
                          ),
                        ],
                      ),

                      // ── Admin (conditional) ─────────────────────────
                      if (isAdmin) ...[
                        const SizedBox(height: 20),
                        _SectionLabel('Admin'),
                        const SizedBox(height: 8),
                        _MenuCard(
                          tiles: [
                            SettingsTile(
                              icon: PhosphorIconsRegular.shieldStar,
                              title: 'Admin Dashboard',
                              subtitle: 'Review pending stations',
                              onTap: () => _push(
                                  context, const AdminDashboardScreen()),
                            ),
                          ],
                        ),
                      ],

                      SizedBox(height: 32 + bottomPad),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 80.ms, duration: 360.ms)
                    .slideY(begin: 0.05, end: 0, delay: 80.ms,
                        duration: 360.ms, curve: Curves.easeOut),
              ),
            ],
          );
        },
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _slate,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

// ── Menu card (groups tiles with dividers) ────────────────────────────────────
class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.tiles});
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            for (int i = 0; i < tiles.length; i++) ...[
              tiles[i],
              if (i < tiles.length - 1)
                Divider(height: 1, color: _border, indent: 62),
            ],
          ],
        ),
      ),
    );
  }
}
