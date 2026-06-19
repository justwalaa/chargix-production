import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/app_settings_controller.dart';
import '../../core/app_settings_scope.dart';
import '../../widgets/chargix/settings_tile.dart';
import '../profile/charging_preferences_screen.dart';
import '../profile/privacy_security_screen.dart';

const _green  = Color(0xFF22C55E);
const _canvas = Color(0xFFF8F9FA);
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

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _signingOut = false;

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final isDark = settings.themeMode == ThemeMode.dark ||
        (settings.themeMode == ThemeMode.system &&
            Theme.of(context).brightness == Brightness.dark);

    return Scaffold(
      backgroundColor: _canvas,
      body: Column(
        children: [
          // Header
          Container(
            color: _white,
            padding: EdgeInsets.fromLTRB(8, topPad + 8, 16, 10),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(PhosphorIconsRegular.arrowLeft,
                      color: _ink, size: 20),
                  onPressed: Navigator.canPop(context)
                      ? () => Navigator.of(context).pop()
                      : null,
                ),
                Expanded(
                    child: Text('Settings', style: _sg(17, FontWeight.w700))),
              ],
            ),
          ),
          Container(height: 0.8, color: _border),

          Expanded(
            child: ListView(
              padding:
                  EdgeInsets.fromLTRB(16, 20, 16, 20 + bottomPad),
              children: [
                // ── Experience ───────────────────────────────────────
                _SectionLabel('Experience'),
                const SizedBox(height: 8),
                _Card(children: [
                  _SwitchRow(
                    icon: isDark
                        ? PhosphorIconsRegular.moon
                        : PhosphorIconsRegular.sun,
                    title: 'Dark mode',
                    subtitle: 'Soft premium theme across Chargix',
                    value: isDark,
                    onChanged: _signingOut
                        ? null
                        : (v) => settings.setDarkMode(v),
                  ),
                  Divider(height: 1, color: _border, indent: 62),
                  _SwitchRow(
                    icon: PhosphorIconsRegular.bell,
                    title: 'Push notifications',
                    subtitle: 'Session updates and charging alerts',
                    value: settings.notificationsEnabled,
                    onChanged: settings.setNotificationsEnabled,
                  ),
                  Divider(height: 1, color: _border, indent: 62),
                  SettingsTile(
                    icon: PhosphorIconsRegular.globe,
                    title: 'Language',
                    subtitle: settings.languageLabel,
                    onTap: () => _pickLanguage(context, settings),
                  ),
                  Divider(height: 1, color: _border, indent: 62),
                  SettingsTile(
                    icon: PhosphorIconsRegular.sliders,
                    title: 'Charging preferences',
                    onTap: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const ChargingPreferencesScreen(),
                        ),
                      );
                    },
                  ),
                ])
                    .animate()
                    .fadeIn(delay: 40.ms, duration: 320.ms)
                    .slideY(begin: 0.05, end: 0, delay: 40.ms,
                        duration: 320.ms, curve: Curves.easeOut),

                const SizedBox(height: 20),

                // ── Privacy ──────────────────────────────────────────
                _SectionLabel('Privacy'),
                const SizedBox(height: 8),
                _Card(children: [
                  SettingsTile(
                    icon: PhosphorIconsRegular.shieldCheck,
                    title: 'Privacy & security',
                    onTap: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const PrivacySecurityScreen(),
                        ),
                      );
                    },
                  ),
                ])
                    .animate()
                    .fadeIn(delay: 80.ms, duration: 320.ms)
                    .slideY(begin: 0.05, end: 0, delay: 80.ms,
                        duration: 320.ms, curve: Curves.easeOut),

                const SizedBox(height: 20),

                // ── Account ──────────────────────────────────────────
                _SectionLabel('Account'),
                const SizedBox(height: 8),
                _Card(children: [
                  SettingsTile(
                    icon: PhosphorIconsRegular.signOut,
                    title: 'Log out',
                    subtitle: 'Sign out on this device',
                    iconColor: const Color(0xFFDC2626),
                    titleColor: const Color(0xFFDC2626),
                    onTap: _signingOut
                        ? null
                        : () => _confirmLogout(context),
                    trailing: _signingOut
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFDC2626),
                            ),
                          )
                        : null,
                  ),
                ])
                    .animate()
                    .fadeIn(delay: 120.ms, duration: 320.ms)
                    .slideY(begin: 0.05, end: 0, delay: 120.ms,
                        duration: 320.ms, curve: Curves.easeOut),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickLanguage(
      BuildContext context, AppSettingsController settings) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return AnimatedBuilder(
          animation: settings,
          builder: (ctx, _) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Language',
                            style: _sg(17, FontWeight.w800)),
                      ),
                    ),
                    _LangTile(
                      label: 'English',
                      code: 'en',
                      current: settings.languageCode,
                      onTap: () {
                        settings.setLanguageCode('en');
                        Navigator.pop(ctx);
                      },
                    ),
                    _LangTile(
                      label: 'العربية',
                      code: 'ar',
                      current: settings.languageCode,
                      onTap: () {
                        settings.setLanguageCode('ar');
                        Navigator.pop(ctx);
                      },
                    ),
                    const SizedBox(height: 8),
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
      builder: (ctx) => Dialog(
        backgroundColor: _white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Log out?', style: _sg(18, FontWeight.w800)),
              const SizedBox(height: 10),
              Text(
                'You will need to sign in again to use Chargix.',
                style: _dm(14, FontWeight.w400,
                    color: _slate, h: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, false),
                      child: Container(
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('Cancel',
                            style: _sg(14, FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, true),
                      child: Container(
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('Log out',
                            style: _sg(14, FontWeight.w600,
                                color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (go != true || !context.mounted) return;

    setState(() => _signingOut = true);
    try {
      await FirebaseAuth.instance.signOut();
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}

// ── Card wrapper ──────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

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
        child: Column(children: children),
      ),
    );
  }
}

// ── Switch row ────────────────────────────────────────────────────────────────
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: _green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: _ink)),
                if (subtitle != null)
                  Text(subtitle!,
                      style: GoogleFonts.dmSans(
                          fontSize: 12, fontWeight: FontWeight.w400,
                          color: _slate)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: _green,
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

// ── Language tile ─────────────────────────────────────────────────────────────
class _LangTile extends StatelessWidget {
  const _LangTile({
    required this.label,
    required this.code,
    required this.current,
    required this.onTap,
  });

  final String label;
  final String code;
  final String current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = current == code;
    return ListTile(
      leading: Icon(
        PhosphorIconsRegular.globe,
        color: selected ? _green : _slate,
        size: 20,
      ),
      title: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          color: selected ? _ink : _slate,
        ),
      ),
      trailing: selected
          ? const Icon(PhosphorIconsFill.checkCircle,
              color: _green, size: 20)
          : null,
      onTap: onTap,
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
