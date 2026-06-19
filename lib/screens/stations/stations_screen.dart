import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../data/chargix_data.dart';
import '../../models/station_model.dart';
import '../../widgets/chargix/firebase_stream_view.dart';
import '../../widgets/stations/station_list_tile.dart';
import 'station_details_screen.dart';

const _green  = Color(0xFF22C55E);
const _canvas = Color(0xFFF8F9FA);
const _white  = Color(0xFFFFFFFF);
const _ink    = Color(0xFF101828);
const _border = Color(0xFFE5E7EB);

/// Chargix partner stations from Firestore.
class StationsScreen extends StatelessWidget {
  const StationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: _canvas,
      body: Column(
        children: [
          // ── Header ───────────────────────────────────────────────────
          Container(
            color: _white,
            padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 14),
            child: Row(
              children: [
                const Icon(PhosphorIconsFill.chargingStation,
                    color: _green, size: 22),
                const SizedBox(width: 10),
                Text('Chargix Stations',
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                        letterSpacing: -0.4)),
              ],
            ),
          ),
          Container(height: 0.8, color: _border),

          // ── List ─────────────────────────────────────────────────────
          Expanded(
            child: FirebaseStreamView<List<StationModel>>(
              stream: ChargixData.stations.watchMapPartnerStations(),
              emptyIcon: PhosphorIconsRegular.chargingStation,
              emptyTitle: 'No partner stations yet',
              emptyMessage:
                  'Approved Chargix hubs appear here after station owners complete registration.',
              builder: (context, stations) {
                return RefreshIndicator(
                  color: _green,
                  backgroundColor: _white,
                  onRefresh: () async {
                    await ChargixData.stations.fetchMapPartnerStations();
                  },
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: stations.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final station = stations[index];
                      return StationListTile(
                        station: station,
                        onTap: () {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) => StationDetailsScreen(
                                partnerStation: station,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
