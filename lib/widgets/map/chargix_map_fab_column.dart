import 'package:flutter/material.dart';

/// Vertical stack of primary/secondary map FABs with entrance motion.
class ChargixMapFabColumn extends StatelessWidget {
  const ChargixMapFabColumn({
    super.key,
    required this.ready,
    required this.onRecenterUser,
    required this.onShowAllStations,
  });

  final bool ready;
  final VoidCallback onRecenterUser;
  final VoidCallback onShowAllStations;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      offset: ready ? Offset.zero : const Offset(0, 0.12),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 320),
        opacity: ready ? 1 : 0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton.small(
              heroTag: 'map_fab_fit_bounds',
              tooltip: 'Show all stations',
              onPressed: onShowAllStations,
              backgroundColor: scheme.secondaryContainer,
              foregroundColor: scheme.onSecondaryContainer,
              elevation: 2,
              child: const Icon(Icons.fit_screen_rounded),
            ),
            const SizedBox(height: 12),
            FloatingActionButton(
              heroTag: 'map_fab_my_location',
              tooltip: 'My location',
              onPressed: onRecenterUser,
              backgroundColor: scheme.primaryContainer,
              foregroundColor: scheme.onPrimaryContainer,
              elevation: 3,
              child: const Icon(Icons.my_location_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
