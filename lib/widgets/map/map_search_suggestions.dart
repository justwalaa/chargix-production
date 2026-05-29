import 'package:flutter/material.dart';

import '../../models/map_station.dart';
import '../../theme/tokens/tokens.dart';

/// Dropdown suggestions when searching stations on the map.
class MapSearchSuggestions extends StatelessWidget {
  const MapSearchSuggestions({
    super.key,
    required this.stations,
    required this.onSelected,
  });

  final List<MapStation> stations;
  final ValueChanged<MapStation> onSelected;

  @override
  Widget build(BuildContext context) {
    if (stations.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final shown = stations.take(8).toList(growable: false);

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      color: scheme.surface.withValues(alpha: 0.98),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: shown.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
        itemBuilder: (context, index) {
          final station = shown[index];
          return ListTile(
            dense: true,
            leading: Icon(
              station.isPartner ? Icons.ev_station : Icons.charging_station,
              color: station.isPartner ? Colors.green : Colors.blue,
            ),
            title: Text(
              station.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              station.address,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: station.isPartner
                ? Text(
                    'Partner',
                    style: Theme.of(context).textTheme.labelSmall,
                  )
                : Text(
                    'Public',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
            onTap: () => onSelected(station),
          );
        },
      ),
    );
  }
}
