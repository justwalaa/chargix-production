import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/station_slot_model.dart';
import '../../theme/tokens/tokens.dart';
import '../../utils/currency_format.dart';

/// Add / edit charging bay with operational fields.
class StationSlotEditorSheet extends StatefulWidget {
  const StationSlotEditorSheet({
    super.key,
    this.initial,
    required this.isCreate,
  });

  final StationSlotModel? initial;
  final bool isCreate;

  static Future<StationSlotModel?> show(
    BuildContext context, {
    StationSlotModel? initial,
    required bool isCreate,
  }) {
    return showModalBottomSheet<StationSlotModel>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => StationSlotEditorSheet(
        initial: initial,
        isCreate: isCreate,
      ),
    );
  }

  @override
  State<StationSlotEditorSheet> createState() => _StationSlotEditorSheetState();
}

class _StationSlotEditorSheetState extends State<StationSlotEditorSheet> {
  static const _connectors = [
    'Type 1',
    'Type 2',
    'CCS',
    'CHAdeMO',
    'Tesla/NACS',
    'GB/T',
  ];
  static const _chargingTypes = ['AC', 'DC', 'DC Fast'];

  late final TextEditingController _labelCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _powerCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _notesCtrl;
  late String _connector;
  late String _chargingType;
  late bool _isOpen;
  late bool _isAvailable;

  static String _normalizeOption(String? raw, List<String> options) {
    if (raw == null || raw.trim().isEmpty) {
      return options.first;
    }
    final normalized = raw.trim().toLowerCase();
    for (final option in options) {
      if (option.toLowerCase() == normalized) {
        return option;
      }
    }
    if (normalized.contains('ccs')) return 'CCS';
    if (normalized.contains('chademo')) return 'CHAdeMO';
    if (normalized.contains('type 2') || normalized == 'type2') {
      return 'Type 2';
    }
    if (normalized.contains('type 1') || normalized == 'type1') {
      return 'Type 1';
    }
    if (normalized.contains('tesla') || normalized.contains('nacs')) {
      return 'Tesla/NACS';
    }
    if (normalized.contains('gb/t') || normalized.contains('gbt')) {
      return 'GB/T';
    }
    if (normalized.contains('dc fast') || normalized == 'dcfast') {
      return 'DC Fast';
    }
    if (normalized == 'dc') return 'DC';
    if (normalized == 'ac') return 'AC';
    debugPrint('[SlotForm] unknown value "$raw" — using ${options.first}');
    return options.first;
  }

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    debugPrint(
      '[SlotEdit] open isCreate=${widget.isCreate} slot=${s?.id} '
      'connector=${s?.connectorType} charging=${s?.chargingType}',
    );

    _labelCtrl = TextEditingController(text: s?.label ?? 'Bay 1');
    _priceCtrl = TextEditingController(
      text: (s?.pricePerKwh ?? 0.35).toStringAsFixed(3),
    );
    _powerCtrl = TextEditingController(
      text: (s?.powerKw ?? 22).toStringAsFixed(0),
    );
    _durationCtrl = TextEditingController(
      text: '${s?.estimatedDurationMinutes ?? 45}',
    );
    _notesCtrl = TextEditingController(text: s?.notes ?? '');
    _connector = _normalizeOption(s?.connectorType, _connectors);
    _chargingType = _normalizeOption(s?.chargingType, _chargingTypes);
    _isOpen = s?.isOpen ?? true;
    _isAvailable = s?.isAvailable ?? true;

    debugPrint(
      '[SlotForm] loaded connector=$_connector charging=$_chargingType '
      'open=$_isOpen available=$_isAvailable',
    );
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _priceCtrl.dispose();
    _powerCtrl.dispose();
    _durationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final label = _labelCtrl.text.trim();
    if (label.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a bay label')),
      );
      return;
    }
    final price = double.tryParse(_priceCtrl.text);
    final power = double.tryParse(_powerCtrl.text) ?? 22;
    final duration = int.tryParse(_durationCtrl.text) ?? 45;

    final base = widget.initial;
    if (base == null) {
      debugPrint('[SlotEdit] save aborted — missing initial slot');
      return;
    }

    debugPrint('[SlotUpdate] saving ${base.id} open=$_isOpen available=$_isAvailable');

    Navigator.pop(
      context,
      base.copyWith(
        label: label,
        connectorType: _connector,
        chargingType: _chargingType,
        powerKw: power,
        pricePerKwh: price,
        estimatedDurationMinutes: duration.clamp(5, 480),
        isOpen: _isOpen,
        isAvailable: _isAvailable,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenGutter,
        0,
        AppSpacing.screenGutter,
        bottom + AppSpacing.screenGutter,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.isCreate ? 'Add charging bay' : 'Edit charging bay',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _labelCtrl,
              decoration: const InputDecoration(labelText: 'Bay label'),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _chargingType,
              decoration: const InputDecoration(labelText: 'Charging type'),
              items: _chargingTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _chargingType = v ?? 'AC'),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _connector,
              decoration: const InputDecoration(labelText: 'Connector type'),
              items: _connectors
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _connector = v ?? 'Type 2'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _powerCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Power (kW)'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                labelText: 'Price per kWh (${CurrencyFormat.code})',
                prefixText: '${CurrencyFormat.symbol} ',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _durationCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Estimated session (minutes)',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Bay open for operations'),
              subtitle: const Text('Closed bays are hidden from drivers'),
              value: _isOpen,
              onChanged: (v) => setState(() {
                _isOpen = v;
                if (!v) _isAvailable = false;
              }),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Available for booking'),
              subtitle: const Text('Turn off when occupied or maintenance'),
              value: _isAvailable,
              onChanged: _isOpen
                  ? (v) => setState(() => _isAvailable = v)
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Operator notes (optional)',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _save,
              child: Text(widget.isCreate ? 'Create bay' : 'Save changes'),
            ),
          ],
        ),
      ),
    );
  }
}
