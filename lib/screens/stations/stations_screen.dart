import 'package:flutter/material.dart';

import '../../data/chargix_data.dart';
import '../../models/station_model.dart';
import '../../theme/tokens/tokens.dart';
import '../../widgets/chargix/firebase_stream_view.dart';
import '../../widgets/stations/station_list_tile.dart';
import 'station_details_screen.dart';

/// Chargix partner stations from Firestore only (same source as [MapStationsService]).
class StationsScreen extends StatelessWidget {
  const StationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chargix stations')),
      body: FirebaseStreamView<List<StationModel>>(
        stream: ChargixData.stations.watchMapPartnerStations(),
        emptyIcon: Icons.ev_station_outlined,
        emptyTitle: 'No partner stations yet',
        emptyMessage:
            'Approved Chargix hubs appear here after station owners complete registration.',
        builder: (context, stations) {
          return RefreshIndicator(
            onRefresh: () async {
              await ChargixData.stations.fetchMapPartnerStations();
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.screenGutter),
              itemCount: stations.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.md),
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
    );
  }
}
