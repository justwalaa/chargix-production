import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/config/maps_config.dart';
import '../../models/picked_station_location.dart';
import '../../services/google_places_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/tokens/tokens.dart';
import '../../widgets/map/places_autocomplete_field.dart';

/// Location picker: Places search, map preview, draggable pin, auto coordinates.
class StationLocationPickerScreen extends StatefulWidget {
  const StationLocationPickerScreen({
    super.key,
    this.initial,
  });

  final PickedStationLocation? initial;

  @override
  State<StationLocationPickerScreen> createState() =>
      _StationLocationPickerScreenState();
}

class _StationLocationPickerScreenState extends State<StationLocationPickerScreen> {
  GoogleMapController? _mapController;
  final _searchController = TextEditingController();
  LatLng? _selected;
  String _address = '';
  String? _placeId;
  bool _loadingAddress = false;
  bool _ready = false;

  static const _fallback = LatLng(
    MapsConfig.fallbackLatitude,
    MapsConfig.fallbackLongitude,
  );

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _selected = LatLng(
        widget.initial!.latitude,
        widget.initial!.longitude,
      );
      _address = widget.initial!.formattedAddress;
      _placeId = widget.initial!.googlePlaceId;
      _searchController.text = widget.initial!.formattedAddress;
      _ready = true;
    } else {
      unawaited(_initLocation());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    LatLng point = _fallback;
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 12),
          ),
        );
        point = LatLng(pos.latitude, pos.longitude);
      }
    } on Object catch (_) {
      // Use Amman fallback.
    }
    _selected = point;
    await _reverseGeocode(point);
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _reverseGeocode(LatLng point) async {
    setState(() => _loadingAddress = true);
    final geo = await GooglePlacesService.instance.reverseGeocode(
      latitude: point.latitude,
      longitude: point.longitude,
    );
    if (!mounted) return;
    setState(() {
      _loadingAddress = false;
      if (geo != null) {
        _address = geo.formattedAddress;
        _placeId = geo.placeId;
        if (_searchController.text.isEmpty) {
          _searchController.text = geo.formattedAddress;
        }
      } else if (_address.isEmpty) {
        _address =
            '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
      }
    });
  }

  Future<void> _onSuggestionSelected(
    PlaceAutocompletePrediction prediction,
  ) async {
    final details = await GooglePlacesService.instance.fetchPlaceDetails(
      prediction.placeId,
    );
    if (!mounted || details == null) return;
    final point = LatLng(details.latitude, details.longitude);
    setState(() {
      _selected = point;
      _address = details.formattedAddress;
      _placeId = details.placeId;
      _searchController.text = details.formattedAddress;
    });
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: point, zoom: 16.5),
      ),
    );
  }

  void _onMarkerDragEnd(LatLng point) {
    setState(() => _selected = point);
    unawaited(_reverseGeocode(point));
  }

  void _confirm() {
    final point = _selected;
    if (point == null || _address.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Search or drag the pin to set your station location.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.of(context).pop(
      PickedStationLocation(
        latitude: point.latitude,
        longitude: point.longitude,
        formattedAddress: _address.trim(),
        googlePlaceId: _placeId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final point = _selected;

    return Scaffold(
      backgroundColor: AppColors.bg1,
      appBar: AppBar(
        title: const Text('Station location'),
        actions: [
          TextButton(
            onPressed: point == null ? null : _confirm,
            child: const Text('Confirm'),
          ),
        ],
      ),
      body: !_ready || point == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.cyan),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenGutter,
                    AppSpacing.sm,
                    AppSpacing.screenGutter,
                    AppSpacing.sm,
                  ),
                  child: PlacesAutocompleteField(
                    controller: _searchController,
                    latitude: point.latitude,
                    longitude: point.longitude,
                    hintText: 'Search street, area, or place…',
                    onPlaceSelected: _onSuggestionSelected,
                  ),
                ),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: point,
                          zoom: 16,
                        ),
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        onMapCreated: (c) => _mapController = c,
                        markers: {
                          Marker(
                            markerId: const MarkerId('station_pick'),
                            position: point,
                            draggable: true,
                            onDragEnd: (p) => _onMarkerDragEnd(p),
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueGreen,
                            ),
                          ),
                        },
                      ),
                      Positioned(
                        left: AppSpacing.screenGutter,
                        right: AppSpacing.screenGutter,
                        bottom: AppSpacing.screenGutter +
                            MediaQuery.paddingOf(context).bottom,
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(AppRadii.xl),
                          color: scheme.surfaceContainerHighest
                              .withValues(alpha: 0.96),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.drag_indicator_rounded,
                                      color: scheme.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Drag the pin to fine-tune location',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                if (_loadingAddress)
                                  const LinearProgressIndicator(minHeight: 2)
                                else
                                  Text(
                                    _address,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                const SizedBox(height: AppSpacing.md),
                                FilledButton.icon(
                                  onPressed: _confirm,
                                  icon: const Icon(Icons.check_rounded),
                                  label: const Text('Use this location'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
