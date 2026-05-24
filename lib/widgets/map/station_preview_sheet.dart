import 'package:flutter/material.dart';

import '../../core/result/data_state.dart';
import '../../data/chargix_data.dart';
import '../../models/map_station.dart';
import '../../screens/booking/book_slot_screen.dart';
import '../../theme/tokens/tokens.dart';
import '../../utils/geo_utils.dart';
import '../../utils/map_directions.dart';
import 'station_type_badge.dart';

/// Bottom sheet for partner or external map stations.
class StationPreviewSheet extends StatefulWidget {
  const StationPreviewSheet({
    super.key,
    required this.station,
    required this.scrollController,
    this.userId,
    this.distanceKm,
    this.onViewPartnerDetails,
  });

  final MapStation station;
  final ScrollController scrollController;
  final String? userId;
  final double? distanceKm;
  final VoidCallback? onViewPartnerDetails;

  @override
  State<StationPreviewSheet> createState() => _StationPreviewSheetState();
}

class _StationPreviewSheetState extends State<StationPreviewSheet> {
  bool _favoriteBusy = false;
  bool? _isFavorite;

  MapStation get station => widget.station;
  bool get isPartner => station.isPartner;
  bool get canBook => station.isBookable;

  @override
  void initState() {
    super.initState();
    if (isPartner) {
      _loadFavorite();
    }
  }

  Future<void> _loadFavorite() async {
    final uid = widget.userId;
    if (uid == null) {
      return;
    }
    try {
      final fav =
          await ChargixData.favorites.watchFavoriteStationIds(uid).first;
      if (mounted) {
        setState(() => _isFavorite = fav.contains(station.id));
      }
    } on Object catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    final uid = widget.userId;
    if (uid == null || _favoriteBusy || !isPartner) {
      return;
    }
    setState(() => _favoriteBusy = true);
    final add = _isFavorite != true;
    final result = await ChargixData.favorites.toggleFavorite(
      userId: uid,
      stationId: station.id,
      add: add,
    );
    if (mounted) {
      setState(() {
        _favoriteBusy = false;
        if (result is DataSuccess<void>) {
          _isFavorite = add;
        }
      });
      if (result is DataError<void>) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not update favorites: ${result.errorOrNull}'),
          ),
        );
      }
    }
  }

  void _openBooking() {
    final partner = station.partner?.station;
    if (partner == null) {
      return;
    }
    Navigator.of(context).pop();
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => BookSlotScreen(station: partner),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final partner = station.partner?.station;
    final external = station.external;

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                station.name,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            if (isPartner && widget.userId != null)
              IconButton(
                onPressed: _favoriteBusy ? null : _toggleFavorite,
                icon: Icon(
                  _isFavorite == true
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_outline_rounded,
                  color: scheme.primary,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        StationTypeBadge(station: station),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.place_outlined, size: 20, color: scheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                station.address,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
        if (widget.distanceKm != null) ...[
          const SizedBox(height: 8),
          Text(
            '${GeoUtils.formatDistanceKm(widget.distanceKm)} · '
            '~${_estimateDriveMinutes(widget.distanceKm!)} min drive',
            style: textTheme.labelLarge?.copyWith(color: scheme.primary),
          ),
        ],
        const SizedBox(height: 20),
        if (isPartner && partner != null) ...[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(
                icon: Icons.ev_station_outlined,
                label:
                    '${partner.availablePorts}/${partner.totalPorts} available',
                tone: partner.availablePorts > 0
                    ? scheme.primaryContainer
                    : scheme.errorContainer,
                onTone: partner.availablePorts > 0
                    ? scheme.onPrimaryContainer
                    : scheme.onErrorContainer,
              ),
              _InfoChip(
                icon: Icons.bolt_outlined,
                label: '\$${partner.pricePerKwh.toStringAsFixed(2)}/kWh',
                tone: scheme.secondaryContainer,
                onTone: scheme.onSecondaryContainer,
              ),
              _InfoChip(
                icon: Icons.star_rounded,
                label: partner.rating.toStringAsFixed(1),
                tone: scheme.surfaceContainerHighest,
                onTone: scheme.onSurface,
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (canBook)
            FilledButton.icon(
              onPressed: _openBooking,
              icon: const Icon(Icons.calendar_month_rounded),
              label: const Text('Book via Chargix'),
            )
          else
            Text(
              'No open ports right now. Check back soon or pick another hub.',
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: widget.onViewPartnerDetails,
            icon: const Icon(Icons.info_outline_rounded),
            label: const Text('Partner station details'),
          ),
        ] else ...[
          _ExternalNetworkBanner(scheme: scheme, textTheme: textTheme),
          const SizedBox(height: 16),
          if (external?.rating != null)
            Text(
              'Google rating ${external!.rating!.toStringAsFixed(1)}'
              '${external.userRatingsTotal != null ? ' (${external.userRatingsTotal})' : ''}',
              style: textTheme.bodyMedium,
            ),
          if (external?.chargerTypeHint != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.power_rounded,
                  label: external!.chargerTypeHint!,
                  tone: scheme.surfaceContainerHighest,
                  onTone: scheme.onSurface,
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Coordinates: ${station.latitude.toStringAsFixed(5)}, '
            '${station.longitude.toStringAsFixed(5)}',
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Live availability, booking, and queue features are only available '
            'at Chargix partner stations (green markers on the map).',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        FilledButton.tonalIcon(
          onPressed: () => MapDirections.open(station),
          icon: const Icon(Icons.navigation_rounded),
          label: const Text('Directions'),
        ),
      ],
    );
  }
}

int _estimateDriveMinutes(double distanceKm) {
  const avgUrbanKmh = 38.0;
  return (distanceKm / avgUrbanKmh * 60).ceil().clamp(1, 999);
}

class _ExternalNetworkBanner extends StatelessWidget {
  const _ExternalNetworkBanner({
    required this.scheme,
    required this.textTheme,
  });

  final ColorScheme scheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: scheme.tertiary.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Not on the Chargix network',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.tertiary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'This location is from public map data. Navigate here for discovery — '
            'book and track sessions only at verified Chargix partners.',
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.tone,
    required this.onTone,
  });

  final IconData icon;
  final String label;
  final Color tone;
  final Color onTone;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: onTone),
      label: Text(label),
      backgroundColor: tone,
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: onTone,
            fontWeight: FontWeight.w600,
          ),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }
}
