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
    this.filterChips,
  });

  final List<MapStationItem> items;
  final ValueChanged<MapStationItem> onStationTap;
  final bool loading;
  final Widget? filterChips;

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
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
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
          if (filterChips != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: filterChips!,
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
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final station = item.station;
                      final partner = station.partner?.station;
                      final subtitle = station.isPartner
                          ? '${partner?.availablePorts ?? 0}/${partner?.totalPorts ?? 0} ports · ${GeoUtils.formatDistanceKm(item.distanceKm)}'
                          : '${station.external?.chargerTypeHint ?? 'EV charging'} · ${GeoUtils.formatDistanceKm(item.distanceKm)}';

                      final isNearest = index == 0 && items.isNotEmpty;
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.lg),
                          side: BorderSide(
                            color: isNearest
                                ? scheme.primary.withValues(alpha: 0.4)
                                : scheme.outline.withValues(alpha: 0.25),
                          ),
                        ),
                        tileColor: isNearest
                            ? scheme.primaryContainer.withValues(alpha: 0.18)
                            : scheme.surface,
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
                        trailing: isNearest
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: scheme.primary
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'NEAREST',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: scheme.primary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.chevron_right_rounded),
                                ],
                              )
                            : const Icon(Icons.chevron_right_rounded),
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
