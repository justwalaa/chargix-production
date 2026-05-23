import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/map_stations_services.dart';
import '../../models/map_station.dart';
import '../../widgets/map/chargix_map_fab_column.dart';
import '../../widgets/map/map_loading_overlay.dart';
import '../../widgets/map/station_preview_sheet.dart';

/// Full-screen EV map.
///
/// Data sources:
///   • Firestore partner stations  → green Chargix markers (booking enabled)
///   • Google Places external stations → blue markers  (info-only)
///
/// No demo/mock/seed data is used anywhere in this file.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // ── State ──────────────────────────────────────────────────────────────────

  GoogleMapController? _controller;
  LatLng? _userLatLng;

  bool _mapCreated = false;
  bool _locationResolved = false;
  bool _initialCameraApplied = false;

  Set<Marker> _markers = {};
  List<MapStation> _stations = [];

  late final MapStationsService _mapService;
  StreamSubscription<List<MapStation>>? _stationsSub;

  // Marker icons — built after map is created.
  BitmapDescriptor _chargixIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _externalIcon = BitmapDescriptor.defaultMarker;
  bool _iconsReady = false;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _mapService = MapStationsService.instance;
    _stationsSub = _mapService.stationsStream.listen(_onStationsUpdated);
    unawaited(_resolveUserLocation());
  }

  @override
  void dispose() {
    _stationsSub?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  // ── Location ───────────────────────────────────────────────────────────────

  Future<void> _resolveUserLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('MapScreen: location services disabled');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('MapScreen: location permission denied');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      _userLatLng = LatLng(position.latitude, position.longitude);
    } on Object catch (e) {
      debugPrint('MapScreen._resolveUserLocation: $e');
      _userLatLng = null;
    } finally {
      if (mounted) {
        setState(() => _locationResolved = true);
        await _tryApplyInitialCamera();
        // Load real stations once we know the user's location.
        if (_userLatLng != null) {
          await _mapService.load(
            latitude: _userLatLng!.latitude,
            longitude: _userLatLng!.longitude,
          );
        }
      }
    }
  }

  // ── Map creation ───────────────────────────────────────────────────────────

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _controller = controller;
    await _buildMarkerIcons();
    if (mounted) setState(() => _mapCreated = true);
    await _tryApplyInitialCamera();
  }

  Future<void> _buildMarkerIcons() async {
    _chargixIcon = BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueGreen,
    );
    _externalIcon = BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueAzure,
    );
    _iconsReady = true;
  }

  // ── Camera ─────────────────────────────────────────────────────────────────

  Future<void> _tryApplyInitialCamera() async {
    if (!_mapCreated || !_locationResolved || _initialCameraApplied) return;
    _initialCameraApplied = true;

    final controller = _controller;
    if (controller == null || !mounted) return;

    // If no user location → stay at default zoom but don't fly to SF.
    // If user location is known → center there.
    if (_userLatLng == null) return;

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _userLatLng!,
          zoom: 14.2,
          tilt: 0,
          bearing: 0,
        ),
      ),
    );
  }

  Future<void> _recenterOnUser() async {
    final controller = _controller;
    if (controller == null) return;

    if (_userLatLng == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location unavailable — enable GPS and grant permission.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await HapticFeedback.lightImpact();
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _userLatLng!, zoom: 15.0),
      ),
    );
  }

  Future<void> _fitAllStations() async {
    final controller = _controller;
    if (controller == null) return;
    if (_stations.isEmpty) return;

    await HapticFeedback.lightImpact();

    var minLat = 90.0, maxLat = -90.0;
    var minLng = 180.0, maxLng = -180.0;

    for (final s in _stations) {
      if (s.latitude < minLat) minLat = s.latitude;
      if (s.latitude > maxLat) maxLat = s.latitude;
      if (s.longitude < minLng) minLng = s.longitude;
      if (s.longitude > maxLng) maxLng = s.longitude;
    }

    if (_userLatLng != null) {
      final u = _userLatLng!;
      if (u.latitude < minLat) minLat = u.latitude;
      if (u.latitude > maxLat) maxLat = u.latitude;
      if (u.longitude < minLng) minLng = u.longitude;
      if (u.longitude > maxLng) maxLng = u.longitude;
    }

    if (minLat == maxLat && minLng == maxLng) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(minLat, minLng), 14),
      );
      return;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 80),
      );
    } on Object catch (_) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(
            (bounds.southwest.latitude + bounds.northeast.latitude) / 2,
            (bounds.southwest.longitude + bounds.northeast.longitude) / 2,
          ),
          13,
        ),
      );
    }
  }

  // ── Stations stream ────────────────────────────────────────────────────────

  void _onStationsUpdated(List<MapStation> stations) {
    if (!mounted) return;
    _stations = stations;
    _rebuildMarkers();
  }

  void _rebuildMarkers() {
    if (!_iconsReady) return;
    final markers = <Marker>{};
    for (final station in _stations) {
      markers.add(
        Marker(
          markerId: MarkerId(station.markerId),
          position: LatLng(station.latitude, station.longitude),
          icon: station.isPartner ? _chargixIcon : _externalIcon,
          infoWindow: InfoWindow.noText,
          onTap: () => unawaited(_openPreview(station)),
        ),
      );
    }
    if (mounted) setState(() => _markers = markers);
  }

  // ── Preview sheet ──────────────────────────────────────────────────────────

  Future<void> _openPreview(MapStation station) async {
    await HapticFeedback.selectionClick();
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      barrierColor: Colors.black.withValues(alpha: 0.38),
      builder: (sheetCtx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: _previewExtent(sheetCtx),
          minChildSize: 0.28,
          maxChildSize: 0.92,
          builder: (ctx, scrollController) {
            return StationPreviewSheet(
              station: station,
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }

  double _previewExtent(BuildContext ctx) {
    final h = MediaQuery.sizeOf(ctx).height;
    if (h < 640) return 0.50;
    if (h < 900) return 0.42;
    return 0.38;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  bool get _bootstrapComplete => _mapCreated && _locationResolved;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Google Map ──────────────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: CameraPosition(
              // Start at a neutral zoom that will be replaced by real GPS.
              target: _userLatLng ?? const LatLng(0, 0),
              zoom: _userLatLng != null ? 14.0 : 2.0,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            compassEnabled: true,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            padding: EdgeInsets.only(
              top: topPad + 8,
              bottom: bottomPad + 88,
              left: 8,
              right: 8,
            ),
            onMapCreated: _onMapCreated,
          ),

          // ── Loading overlay ─────────────────────────────────────────────
          MapLoadingOverlay(
            visible: !_bootstrapComplete,
            message: 'Locating you…',
          ),

          // ── Header chip ─────────────────────────────────────────────────
          Positioned(
            top: topPad + 12,
            left: 16,
            right: 72,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              opacity: _bootstrapComplete ? 1 : 0,
              child: _MapHeaderChip(
                ready: _bootstrapComplete,
                stationCount: _stations.length,
                chargixCount: _stations.where((s) => s.isPartner).length,
              ),
            ),
          ),

          // ── Legend ──────────────────────────────────────────────────────
          if (_bootstrapComplete && _stations.isNotEmpty)
            Positioned(
              top: topPad + 68,
              left: 16,
              child: _MapLegend(scheme: scheme),
            ),

          // ── No-location warning ─────────────────────────────────────────
          if (_locationResolved && _userLatLng == null)
            Positioned(
              top: topPad + 12,
              left: 16,
              right: 16,
              child: _NoLocationBanner(),
            ),

          // ── FABs ────────────────────────────────────────────────────────
          Positioned(
            right: 16,
            bottom: bottomPad + 16,
            child: ChargixMapFabColumn(
              ready: _bootstrapComplete,
              onRecenterUser: _recenterOnUser,
              onShowAllStations: _fitAllStations,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header Chip ──────────────────────────────────────────────────────────────

class _MapHeaderChip extends StatelessWidget {
  const _MapHeaderChip({
    required this.ready,
    required this.stationCount,
    required this.chargixCount,
  });

  final bool ready;
  final int stationCount;
  final int chargixCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = stationCount == 0
        ? 'Finding stations…'
        : '$stationCount station${stationCount == 1 ? '' : 's'} nearby';

    return IgnorePointer(
      ignoring: !ready,
      child: Material(
        elevation: 2,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(20),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.95),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.ev_station_rounded, size: 20, color: scheme.primary),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Legend ───────────────────────────────────────────────────────────────────

class _MapLegend extends StatelessWidget {
  const _MapLegend({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(12),
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.92),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _LegendRow(
              color: const Color(0xFF2E7D32),
              label: 'Chargix partner',
            ),
            const SizedBox(height: 4),
            _LegendRow(
              color: const Color(0xFF1565C0),
              label: 'External station',
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// ─── No-location banner ───────────────────────────────────────────────────────

class _NoLocationBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.location_off_rounded,
                color: scheme.onErrorContainer, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Location unavailable — enable GPS and grant permission',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onErrorContainer,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}