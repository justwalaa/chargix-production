import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../data/chargix_data.dart';
import '../../core/result/data_state.dart';
import '../../theme/tokens/tokens.dart';
import '../booking/book_slot_screen.dart';

/// Scans Chargix station QR codes (`chargix://station/{id}`).
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool _handled = false;
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled || _loading) {
      return;
    }
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) {
      return;
    }
    final stationId = _parseStationId(raw);
    if (stationId == null) {
      return;
    }
    setState(() {
      _handled = true;
      _loading = true;
    });
    final state = await ChargixData.stations.getStation(stationId);
    if (!mounted) {
      return;
    }
    setState(() => _loading = false);
    if (state is! DataSuccess || state.dataOrNull == null) {
      setState(() => _handled = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unknown Chargix station QR')),
      );
      return;
    }
    final station = state.dataOrNull!;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => BookSlotScreen(station: station),
      ),
    );
  }

  String? _parseStationId(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null) {
      return null;
    }
    if (uri.scheme == 'chargix' && uri.host == 'station') {
      final seg = uri.pathSegments;
      if (seg.isNotEmpty) {
        return seg.first;
      }
    }
    if (raw.startsWith('chargix:station:')) {
      return raw.split(':').last;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Scan station QR')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: scheme.primary, width: 3),
                borderRadius: BorderRadius.circular(AppRadii.xl),
              ),
            ),
          ),
          if (_loading)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
          Positioned(
            left: AppSpacing.screenGutter,
            right: AppSpacing.screenGutter,
            bottom: AppSpacing.screenGutter,
            child: Text(
              'Point at the Chargix QR on the charger. '
              'External Google stations do not have Chargix QR codes.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
