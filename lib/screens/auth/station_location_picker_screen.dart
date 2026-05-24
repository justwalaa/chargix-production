import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/picked_station_location.dart';
import '../../services/google_places_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/tokens/tokens.dart';

/// Interactive map picker for exact station coordinates during registration.
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
  LatLng? _selected;
  String _address = '';
  String? _placeId;
  bool _loadingAddress = false;
  bool _locating = true;

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
      _locating = false;
    } else {
      unawaited(_goToUserLocation());
    }
  }

  Future<void> _goToUserLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _selected = const LatLng(31.9539, 35.9106);
      } else {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 12),
          ),
        );
        _selected = LatLng(pos.latitude, pos.longitude);
      }
      if (_selected != null) {
        await _reverseGeocode(_selected!);
      }
    } on Object catch (_) {
      _selected ??= const LatLng(31.9539, 35.9106);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
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
      } else if (_address.isEmpty) {
        _address =
            '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
      }
    });
  }

  void _onMapTap(LatLng point) {
    setState(() => _selected = point);
    unawaited(_reverseGeocode(point));
  }

  void _confirm() {
    final point = _selected;
    if (point == null || _address.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tap the map to place your station pin.'),
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
        title: const Text('Pin station location'),
        actions: [
          TextButton(
            onPressed: point == null ? null : _confirm,
            child: const Text('Confirm'),
          ),
        ],
      ),
      body: _locating || point == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.cyan),
            )
          : Stack(
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
                  onTap: _onMapTap,
                  markers: {
                    Marker(
                      markerId: const MarkerId('station_pick'),
                      position: point,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueCyan,
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
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.96),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.touch_app_rounded,
                                  color: scheme.primary, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Tap the map to set your exact charger location',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(fontWeight: FontWeight.w600),
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
                              style: Theme.of(context).textTheme.bodyMedium,
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
    );
  }
}
