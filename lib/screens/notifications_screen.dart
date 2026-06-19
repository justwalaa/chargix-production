import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../data/chargix_data.dart';
import '../models/notification_model.dart';

const _green        = Color(0xFF22C55E);
const _greenDark    = Color(0xFF16A34A);
const _greenSurface = Color(0xFFDCFCE7);
const _canvas       = Color(0xFFF8F9FA);
const _white        = Color(0xFFFFFFFF);
const _ink          = Color(0xFF101828);
const _slate        = Color(0xFF6B7280);
const _border       = Color(0xFFE5E7EB);

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

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
                  child: Text('Notifications',
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
            child: uid == null
                ? Center(
                    child: Text('Sign in to view notifications.',
                        style: GoogleFonts.dmSans(
                            fontSize: 14, color: _slate)),
                  )
                : StreamBuilder<List<AppNotification>>(
                    stream:
                        ChargixData.notifications.watchForUser(uid),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(
                                color: _green, strokeWidth: 2));
                      }
                      final notifs = snap.data ?? [];
                      if (notifs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: _greenSurface,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                    PhosphorIconsRegular.bellSimple,
                                    color: _greenDark,
                                    size: 28),
                              ),
                              const SizedBox(height: 16),
                              Text('No notifications yet',
                                  style: GoogleFonts.spaceGrotesk(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: _ink)),
                              const SizedBox(height: 6),
                              Text(
                                  'Booking confirmations and updates\nwill appear here.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      color: _slate,
                                      height: 1.5)),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                            16, 16, 16, 16 + bottomPad),
                        itemCount: notifs.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          return _NotifCard(
                            notif: notifs[i],
                            onTap: () =>
                                ChargixData.notifications.markRead(
                              uid,
                              notifs[i].id,
                            ),
                          )
                              .animate()
                              .fadeIn(
                                  delay: (40 * i).ms, duration: 260.ms)
                              .slideY(
                                  begin: 0.05,
                                  end: 0,
                                  delay: (40 * i).ms,
                                  duration: 260.ms,
                                  curve: Curves.easeOut);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  const _NotifCard({required this.notif, required this.onTap});
  final AppNotification notif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUnread = !notif.isRead;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUnread
              ? _greenSurface.withValues(alpha: 0.5)
              : _white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnread
                ? _green.withValues(alpha: 0.3)
                : _border,
            width: isUnread ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _greenSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(PhosphorIconsFill.lightning,
                  color: _greenDark, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(notif.title,
                            style: GoogleFonts.spaceGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _ink)),
                      ),
                      if (isUnread)
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                              color: _green, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(notif.body,
                      style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: _slate,
                          height: 1.4)),
                  const SizedBox(height: 6),
                  Text(
                    _relativeTime(notif.createdAt),
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: _slate),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
