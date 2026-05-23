import 'package:flutter/material.dart';

import '../../models/map_station_item.dart';
import '../../theme/tokens/tokens.dart';
import '../../utils/geo_utils.dart';
/// Collapsible nearby stations list on the map.
class MapNearbyPanel extends StatelessWidget {
  const MapNearbyPanel({
    super.key,
    required this.items,
    required this.onStationTap,
    this.loading = false,
  });

  final List<MapStationItem> items;
  final ValueChanged<MapStationItem> onStationTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      elevation: 8,
      shadowColor: scheme.shadow.withValues(alpha: 0.1),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.xxl)),
      color: scheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                Icon(Icons.near_me_rounded, size: 20, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Nearby (${items.length})',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const Spacer(),
                if (loading)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.primary,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'No stations match your filters',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: items.length.clamp(0, 8),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final station = item.station;
                      final partner = station.partner?.station;
                      final subtitle = station.isPartner
                          ? '${partner?.availablePorts ?? 0}/${partner?.totalPorts ?? 0} ports · ${GeoUtils.formatDistanceKm(item.distanceKm)}'
                          : '${station.external?.chargerTypeHint ?? 'EV charging'} · ${GeoUtils.formatDistanceKm(item.distanceKm)}';

                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.lg),
                          side: BorderSide(
                            color: scheme.outline.withValues(alpha: 0.25),
                          ),
                        ),
                        tileColor: scheme.surface,
                        leading: CircleAvatar(
                          backgroundColor: station.isPartner
                              ? scheme.primaryContainer.withValues(alpha: 0.6)
                              : scheme.surfaceContainerHighest,
                          child: Icon(
                            station.isPartner
                                ? Icons.verified_rounded
                                : Icons.ev_station_outlined,
                            color: station.isPartner
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          station.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => onStationTap(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
