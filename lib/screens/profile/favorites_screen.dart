import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../data/chargix_data.dart';
import '../../models/station_model.dart';
import '../../widgets/chargix/empty_state.dart';
import '../../widgets/chargix/firebase_stream_view.dart';
import '../stations/station_details_screen.dart';

const _greenDark    = Color(0xFF16A34A);
const _greenSurface = Color(0xFFDCFCE7);
const _canvas       = Color(0xFFF8F9FA);
const _white        = Color(0xFFFFFFFF);
const _ink          = Color(0xFF101828);
const _slate        = Color(0xFF6B7280);
const _border       = Color(0xFFE5E7EB);

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final topPad = MediaQuery.paddingOf(context).top;

    if (uid == null) {
      return Scaffold(
        backgroundColor: _canvas,
        body: const ChargixEmptyState(
          icon: PhosphorIconsRegular.bookmarkSimple,
          title: 'Sign in required',
          message: 'Save partner stations from the map preview.',
        ),
      );
    }

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
                  child: Text('Saved Stations',
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
            child: FirebaseStreamView<List<StationModel>>(
              stream: _watchFavoriteStations(uid),
              emptyIcon: PhosphorIconsRegular.bookmarkSimple,
              emptyTitle: 'No saved stations',
              emptyMessage: 'Bookmark a Chargix partner hub on the map.',
              builder: (context, stations) {
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: stations.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final station = stations[i];
                    return _FavTile(
                      station: station,
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => StationDetailsScreen(
                              partnerStation: station),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: (50 * i).ms, duration: 260.ms)
                        .slideY(
                            begin: 0.05,
                            end: 0,
                            delay: (50 * i).ms,
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

  static Stream<List<StationModel>> _watchFavoriteStations(String uid) {
    return ChargixData.favorites.watchFavoritesForUser(uid).asyncMap(
      (favorites) async {
        final stations = <StationModel>[];
        for (final fav in favorites) {
          final state = await ChargixData.stations.getStation(fav.stationId);
          final station = state.dataOrNull;
          if (station != null) stations.add(station);
        }
        return stations;
      },
    );
  }
}

class _FavTile extends StatelessWidget {
  const _FavTile({required this.station, required this.onTap});
  final StationModel station;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _greenSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(PhosphorIconsFill.sealCheck,
                  color: _greenDark, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(station.name,
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(station.address,
                      style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: _slate),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(PhosphorIconsRegular.caretRight,
                size: 16, color: _slate),
          ],
        ),
      ),
    );
  }
}
