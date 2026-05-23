import 'package:flutter/material.dart';

import '../../theme/tokens/tokens.dart';
import '../../utils/map_station_utils.dart';

class MapFilterChips extends StatelessWidget {
  const MapFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final MapStationFilter selected;
  final ValueChanged<MapStationFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Chip(
            label: 'All',
            selected: selected == MapStationFilter.all,
            onTap: () => onSelected(MapStationFilter.all),
          ),
          const SizedBox(width: AppSpacing.sm),
          _Chip(
            label: 'Chargix',
            selected: selected == MapStationFilter.partners,
            onTap: () => onSelected(MapStationFilter.partners),
          ),
          const SizedBox(width: AppSpacing.sm),
          _Chip(
            label: 'External',
            selected: selected == MapStationFilter.external,
            onTap: () => onSelected(MapStationFilter.external),
          ),
          const SizedBox(width: AppSpacing.sm),
          _Chip(
            label: 'Available',
            selected: selected == MapStationFilter.available,
            onTap: () => onSelected(MapStationFilter.available),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: scheme.primary.withValues(alpha: 0.14),
      labelStyle: TextStyle(
        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        color: selected ? scheme.primary : scheme.onSurfaceVariant,
      ),
      side: BorderSide(
        color: selected
            ? scheme.primary.withValues(alpha: 0.4)
            : scheme.outline.withValues(alpha: 0.35),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
