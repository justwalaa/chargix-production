import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/chargix_data.dart';
import '../../models/station_model.dart';
import '../../theme/tokens/tokens.dart';
import '../../widgets/chargix/empty_state.dart';
import '../../widgets/chargix/firebase_stream_view.dart';
import '../../widgets/chargix/premium_card.dart';
import '../stations/station_details_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Saved stations')),
        body: const ChargixEmptyState(
          icon: Icons.bookmark_outline_rounded,
          title: 'Sign in required',
          message: 'Save partner stations from the map preview.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Saved partner stations')),
      body: FirebaseStreamView<List<StationModel>>(
        stream: _watchFavoriteStations(uid),
        emptyIcon: Icons.bookmark_border_rounded,
        emptyTitle: 'No saved stations',
        emptyMessage: 'Bookmark a Chargix partner hub on the map.',
        builder: (context, stations) {
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.screenGutter),
            itemCount: stations.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final station = stations[index];
              return PremiumCard(
                onTap: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => StationDetailsScreen(
                        partnerStation: station,
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Icon(Icons.verified_rounded,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            station.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            station.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              );
            },
          );
        },
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
          if (station != null && station.status.isPublicOnMap) {
            stations.add(station);
          }
        }
        return stations;
      },
    );
  }
}
