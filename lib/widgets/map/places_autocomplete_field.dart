import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/config/maps_config.dart';
import '../../services/google_places_service.dart';
import '../../theme/tokens/tokens.dart';

/// Searchable Google Places field with live autocomplete suggestions.
class PlacesAutocompleteField extends StatefulWidget {
  const PlacesAutocompleteField({
    super.key,
    required this.controller,
    required this.onPlaceSelected,
    this.hintText = 'Search address or place…',
    this.latitude,
    this.longitude,
    this.enabled = true,
  });

  final TextEditingController controller;
  final Future<void> Function(PlaceAutocompletePrediction prediction) onPlaceSelected;
  final String hintText;
  final double? latitude;
  final double? longitude;
  final bool enabled;

  @override
  State<PlacesAutocompleteField> createState() =>
      _PlacesAutocompleteFieldState();
}

class _PlacesAutocompleteFieldState extends State<PlacesAutocompleteField> {
  List<PlaceAutocompletePrediction> _suggestions = const [];
  bool _loading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    _debounce?.cancel();
    _debounce = Timer(MapsConfig.placesAutocompleteDebounce, () {
      unawaited(_fetchSuggestions(widget.controller.text));
    });
  }

  Future<void> _fetchSuggestions(String text) async {
    if (text.trim().length < 2) {
      if (mounted) setState(() => _suggestions = const []);
      return;
    }
    setState(() => _loading = true);
    final results = await GooglePlacesService.instance.fetchAutocomplete(
      input: text,
      latitude: widget.latitude,
      longitude: widget.longitude,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _suggestions = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: widget.controller,
          enabled: widget.enabled,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: Icon(Icons.search_rounded, color: scheme.primary),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : widget.controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          widget.controller.clear();
                          setState(() => _suggestions = const []);
                        },
                      )
                    : null,
            filled: true,
            fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.96),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.xl),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            color: scheme.surface,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _suggestions.length.clamp(0, 6),
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _suggestions[index];
                return ListTile(
                  dense: true,
                  leading: Icon(Icons.place_outlined, color: scheme.primary),
                  title: Text(
                    item.mainText.isNotEmpty ? item.mainText : item.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: item.secondaryText.isNotEmpty
                      ? Text(
                          item.secondaryText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  onTap: () async {
                    widget.controller.text = item.description;
                    setState(() => _suggestions = const []);
                    await widget.onPlaceSelected(item);
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
