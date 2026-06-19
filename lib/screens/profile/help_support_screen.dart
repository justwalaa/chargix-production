import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../widgets/chargix/settings_tile.dart';

const _green  = Color(0xFF22C55E);
const _canvas = Color(0xFFF8F9FA);
const _white  = Color(0xFFFFFFFF);
const _ink    = Color(0xFF101828);
const _slate  = Color(0xFF6B7280);
const _border = Color(0xFFE5E7EB);

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: _canvas,
      body: Column(
        children: [
          Container(
            color: _white,
            padding: EdgeInsets.fromLTRB(8, topPad + 8, 16, 10),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(PhosphorIconsRegular.arrowLeft,
                      color: _ink, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text('Help & Support',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _ink)),
                ),
              ],
            ),
          ),
          Container(height: 0.8, color: _border),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Card(
                  children: [
                    SettingsTile(
                      icon: PhosphorIconsRegular.question,
                      title: 'FAQ',
                      subtitle: 'Charging, bookings, and fleet tips',
                      onTap: () => _showFaq(context),
                    ),
                    Divider(height: 1, color: _border, indent: 62),
                    SettingsTile(
                      icon: PhosphorIconsRegular.envelope,
                      title: 'Email support',
                      subtitle: 'support@chargix.app',
                      onTap: () => _copy(context, 'support@chargix.app'),
                    ),
                    Divider(height: 1, color: _border, indent: 62),
                    SettingsTile(
                      icon: PhosphorIconsRegular.phone,
                      title: 'Jordan hotline',
                      subtitle: '+962 6 000 0000',
                      onTap: () => _copy(context, '+96260000000'),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 40.ms, duration: 320.ms)
                    .slideY(begin: 0.05, end: 0, delay: 40.ms,
                        duration: 320.ms, curve: Curves.easeOut),
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
              Text('FAQ',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _ink)),
              const SizedBox(height: 16),
              _FaqItem('Book a slot from Map or Stations'),
              _FaqItem('Station owners approve bookings in the operator app'),
              _FaqItem('Enable location for nearby charger sorting'),
              _FaqItem('Save favorites for quick access'),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Close',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _ink)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext context, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied $value',
              style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white)),
          backgroundColor: _ink,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}

class _FaqItem extends StatelessWidget {
  const _FaqItem(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(PhosphorIconsFill.checkCircle,
              size: 14, color: _green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: _slate,
                    height: 1.4)),
          ),
        ],
      ),
    );
  }
}

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
