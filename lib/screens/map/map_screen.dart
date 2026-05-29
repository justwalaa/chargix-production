import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/config/maps_config.dart';
import '../../models/map_station.dart';
import '../../services/map/map_marker_builder.dart';
import '../../services/map/map_pipeline_logger.dart';
import '../../services/stations_map_service.dart';
import '../../utils/geo_utils.dart';
import '../../utils/map_station_search.dart';
import '../../widgets/map/chargix_map_fab_column.dart';
import '../../widgets/map/map_loading_overlay.dart';
import '../../widgets/map/map_search_bar.dart';
import '../../widgets/map/map_search_suggestions.dart';
import '../../widgets/map/station_preview_sheet.dart';
import '../stations/station_details_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _fallbackCenter = LatLng(
    MapsConfig.fallbackLatitude,
    MapsConfig.fallbackLongitude,
  );

  GoogleMapController? _controller;
  LatLng _mapCenter = _fallbackCenter;
  LatLng? _userLatLng;
  bool _mapCreated = false;
  bool _locationResolved = false;
  bool _myLocationEnabled = false;
  bool _stationsLoaded = false;
  bool _initialCameraApplied = false;
  bool _pendingMarkerRebuild = false;
  Set<Marker> _markers = {};
  List<MapStation> _allStations = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  late final MapStationsService _mapService;
  StreamSubscription<List<MapStation>>? _stationsSub;
  BitmapDescriptor _chargixIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _externalIcon = BitmapDescriptor.defaultMarker;
  bool _iconsReady = false;

  @override
  void initState() {
    super.initState();
    _mapService = MapStationsService.instance;
    _mapService.startPartnerWatch();
    _stationsSub = _mapService.stationsStream.listen(_onStationsUpdated);
    _searchFocus.addListener(() {
      if (mounted) setState(() {});
    });
    if (_mapService.currentStations.isNotEmpty) {
      _onStationsUpdated(_mapService.currentStations);
    }
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    _stationsSub?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _controller?.dispose();
    super.dispose();
  }

  List<MapStation> get _visibleStations =>
      MapStationSearch.filter(_allStations, _searchQuery);

  List<MapStation> get _searchSuggestions {
    final q = _searchQuery.trim();
    if (q.isEmpty) return const [];
    return _visibleStations;
  }

  Future<void> _bootstrap() async {
    MapPipelineLogger.mapRender('bootstrap start');
    unawaited(_resolveUserLocation());

    await _mapService.load(
      latitude: _fallbackCenter.latitude,
      longitude: _fallbackCenter.longitude,
    );

    if (!mounted) return;
    setState(() => _stationsLoaded = true);
    MapPipelineLogger.mapRender('initial stations load dispatched');
  }

  Future<void> _resolveUserLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        MapPipelineLogger.mapRender('location services disabled — fallback');
      } else {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission != LocationPermission.denied &&
            permission != LocationPermission.deniedForever) {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          ).timeout(const Duration(seconds: 15));
      _userLatLng = LatLng(position.latitude, position.longitude);
      _mapCenter = _userLatLng!;
      _myLocationEnabled = true;
      MapPipelineLogger.mapRender(
        'GPS ok (${position.latitude}, ${position.longitude}) — blue dot enabled',
      );
          await _mapService.load(
            latitude: position.latitude,
            longitude: position.longitude,
          );
        } else {
          MapPipelineLogger.mapRender('location permission denied — fallback');
        }
      }
    } on Object catch (e) {
      MapPipelineLogger.mapRender('GPS failed, using fallback: $e');
      _userLatLng = null;
      _mapCenter = _fallbackCenter;
    } finally {
      if (mounted) {
        setState(() => _locationResolved = true);
      }
    }
    if (!mounted) return;
    await _tryApplyInitialCamera();
    _flushPendingMarkerRebuild();
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _controller = controller;
    _chargixIcon = BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueGreen,
    );
    _externalIcon = BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueAzure,
    );
    _iconsReady = true;
    if (mounted) setState(() => _mapCreated = true);
    await _tryApplyInitialCamera();
    _flushPendingMarkerRebuild();
    MapPipelineLogger.mapRender(
      'map ready — ${_visibleStations.length} visible stations',
    );
  }

  void _flushPendingMarkerRebuild() {
    if (_pendingMarkerRebuild) {
      _pendingMarkerRebuild = false;
      _rebuildMarkers();
    }
  }

  Future<void> _tryApplyInitialCamera() async {
    if (!_mapCreated || !_locationResolved || _initialCameraApplied) return;
    _initialCameraApplied = true;
    final controller = _controller;
    if (controller == null || !mounted) return;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _mapCenter, zoom: 14.2),
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
            'Location unavailable — showing stations near Amman.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          const CameraPosition(target: _fallbackCenter, zoom: 14.0),
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
    if (controller == null || _visibleStations.isEmpty) return;
    await HapticFeedback.lightImpact();
    var minLat = 90.0, maxLat = -90.0;
    var minLng = 180.0, maxLng = -180.0;
    for (final s in _visibleStations) {
      if (s.latitude < minLat) minLat = s.latitude;
      if (s.latitude > maxLat) maxLat = s.latitude;
      if (s.longitude < minLng) minLng = s.longitude;
      if (s.longitude > maxLng) maxLng = s.longitude;
    }
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 80),
      );
    } on Object {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2),
          13,
        ),
      );
    }
  }

  Future<void> _onCameraIdle() async {
    final controller = _controller;
    if (controller == null || !mounted) return;
    try {
      final screen = MediaQuery.sizeOf(context);
      final center = await controller.getLatLng(
        ScreenCoordinate(
          x: (screen.width / 2).round(),
          y: (screen.height / 2).round(),
        ),
      );
      _mapCenter = center;
      await _mapService.refreshExternalIfMoved(
        latitude: center.latitude,
        longitude: center.longitude,
      );
    } on Object catch (e) {
      MapPipelineLogger.mapRender('camera idle refresh failed: $e');
    }
  }

  void _onStationsUpdated(List<MapStation> stations) {
    if (!mounted) return;
    _allStations = _attachDistances(stations);
    MapPipelineLogger.mapRender(
      'stations updated total=${_allStations.length} '
      'partner=${_allStations.where((s) => s.isPartner).length} '
      'external=${_allStations.where((s) => s.isExternal).length}',
    );
    if (!_stationsLoaded && _allStations.isNotEmpty) {
      _stationsLoaded = true;
    }
    _rebuildMarkers();
  }

  List<MapStation> _attachDistances(List<MapStation> stations) {
    final user = _userLatLng ?? _mapCenter;
    final withDist = stations
        .map(
          (s) => s.copyWith(
            distanceKm: GeoUtils.distanceKm(
              user.latitude,
              user.longitude,
              s.latitude,
              s.longitude,
            ),
          ),
        )
        .toList(growable: false);
    withDist.sort(
      (a, b) => (a.distanceKm ?? double.infinity)
          .compareTo(b.distanceKm ?? double.infinity),
    );
    return withDist;
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    _rebuildMarkers();
  }

  Future<void> _onSearchResultTap(MapStation station) async {
    _searchFocus.unfocus();
    _searchController.text = station.name;
    setState(() => _searchQuery = station.name);
    _rebuildMarkers();
    final controller = _controller;
    if (controller != null) {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(station.latitude, station.longitude),
            zoom: 16,
          ),
        ),
      );
    }
    await _openPreview(station);
  }

  void _rebuildMarkers() {
    if (!_iconsReady) {
      _pendingMarkerRebuild = true;
      MapPipelineLogger.mapRender('markers deferred — icons not ready');
      return;
    }

    final built = MapMarkerBuilder.build(
      stations: _visibleStations,
      partnerIcon: _chargixIcon,
      externalIcon: _externalIcon,
      onMarkerTap: (station) => unawaited(_openPreview(station)),
    );

    MapPipelineLogger.mapRender('render markerCount=${built.length}');
    if (mounted) setState(() => _markers = built);
  }

  Future<void> _openPreview(MapStation station) async {
    if (!mounted) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final partner = station.partner?.station;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      barrierColor: Colors.black.withValues(alpha: 0.38),
      builder: (sheetCtx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.42,
          minChildSize: 0.28,
          maxChildSize: 0.92,
          builder: (ctx, scrollController) {
            return StationPreviewSheet(
              station: station,
              scrollController: scrollController,
              userId: uid,
              distanceKm: station.distanceKm,
              onViewPartnerDetails: partner == null
                  ? null
                  : () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => StationDetailsScreen(
                            partnerStation: partner,
                          ),
                        ),
                      );
                    },
            );
          },
        );
      },
    );
  }

  bool get _bootstrapComplete =>
      _mapCreated && _locationResolved && _stationsLoaded;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final showSuggestions =
        _searchFocus.hasFocus && _searchQuery.trim().isNotEmpty;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GoogleMap(
            key: ValueKey('map_${_myLocationEnabled}_$_mapCreated'),
            initialCameraPosition: CameraPosition(
              target: _mapCenter,
              zoom: 14.0,
            ),
            markers: _markers,
            myLocationEnabled: _myLocationEnabled,
            myLocationButtonEnabled: false,
            compassEnabled: true,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            padding: EdgeInsets.only(top: topPad + 8, bottom: bottomPad + 88),
            onMapCreated: _onMapCreated,
            onCameraIdle: () => unawaited(_onCameraIdle()),
          ),
          MapLoadingOverlay(
            visible: !_bootstrapComplete,
            message: _stationsLoaded
                ? 'Locating you…'
                : 'Loading charging stations…',
          ),
          Positioned(
            top: topPad + 12,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MapSearchBar(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  onChanged: _onSearchChanged,
                  hintText: _allStations.isEmpty
                      ? 'Loading stations…'
                      : 'Search name, street, city, charger…',
                ),
                if (showSuggestions) ...[
                  const SizedBox(height: 6),
                  MapSearchSuggestions(
                    stations: _searchSuggestions,
                    onSelected: (s) => unawaited(_onSearchResultTap(s)),
                  ),
                ],
              ],
            ),
          ),
          if (_bootstrapComplete && _allStations.isNotEmpty)
            Positioned(
              top: topPad + (showSuggestions ? 280 : 72),
              left: 16,
              child: _StationCountBadge(
                partner: _allStations.where((s) => s.isPartner).length,
                external: _allStations.where((s) => s.isExternal).length,
                visible: _markers.length,
              ),
            ),
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

class _StationCountBadge extends StatelessWidget {
  const _StationCountBadge({
    required this.partner,
    required this.external,
    required this.visible,
  });

  final int partner;
  final int external;
  final int visible;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.92,
          ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          'Green $partner · Blue $external · Showing $visible',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
