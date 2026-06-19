import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../models/station_slot_model.dart';
import '../../utils/currency_format.dart';

const _green  = Color(0xFF22C55E);
const _white  = Color(0xFFFFFFFF);
const _ink          = Color(0xFF101828);
const _slate        = Color(0xFF6B7280);
const _border       = Color(0xFFE5E7EB);

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
      backgroundColor: _white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StationSlotEditorSheet(
        initial: initial,
        isCreate: isCreate,
      ),
    );
  }

  @override
  State<StationSlotEditorSheet> createState() =>
      _StationSlotEditorSheetState();
}

class _StationSlotEditorSheetState
    extends State<StationSlotEditorSheet> {
  static const _connectors = [
    'Type 1', 'Type 2', 'CCS', 'CHAdeMO', 'Tesla/NACS', 'GB/T',
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

  static String _normalize(String? raw, List<String> opts) {
    if (raw == null || raw.trim().isEmpty) return opts.first;
    final n = raw.trim().toLowerCase();
    for (final o in opts) {
      if (o.toLowerCase() == n) return o;
    }
    if (n.contains('ccs')) return 'CCS';
    if (n.contains('chademo')) return 'CHAdeMO';
    if (n.contains('type 2') || n == 'type2') return 'Type 2';
    if (n.contains('type 1') || n == 'type1') return 'Type 1';
    if (n.contains('tesla') || n.contains('nacs')) return 'Tesla/NACS';
    if (n.contains('gb/t') || n.contains('gbt')) return 'GB/T';
    if (n.contains('dc fast') || n == 'dcfast') return 'DC Fast';
    if (n == 'dc') return 'DC';
    if (n == 'ac') return 'AC';
    return opts.first;
  }

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    _labelCtrl = TextEditingController(text: s?.label ?? 'Bay 1');
    _priceCtrl = TextEditingController(
        text: (s?.pricePerKwh ?? 0.35).toStringAsFixed(3));
    _powerCtrl = TextEditingController(
        text: (s?.powerKw ?? 22).toStringAsFixed(0));
    _durationCtrl = TextEditingController(
        text: '${s?.estimatedDurationMinutes ?? 45}');
    _notesCtrl = TextEditingController(text: s?.notes ?? '');
    _connector = _normalize(s?.connectorType, _connectors);
    _chargingType = _normalize(s?.chargingType, _chargingTypes);
    _isOpen = s?.isOpen ?? true;
    _isAvailable = s?.isAvailable ?? true;
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
        SnackBar(
          content: Text('Enter a bay label',
              style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white)),
          backgroundColor: _ink,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    final price = double.tryParse(_priceCtrl.text);
    final power = double.tryParse(_powerCtrl.text) ?? 22;
    final duration = int.tryParse(_durationCtrl.text) ?? 45;
    final base = widget.initial;
    if (base == null) return;

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
        notes: _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: _border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 18),

            Text(
              widget.isCreate
                  ? 'Add charging bay'
                  : 'Edit charging bay',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                  letterSpacing: -0.3),
            ),

            const SizedBox(height: 20),

            _field(_labelCtrl, 'Bay label',
                icon: PhosphorIconsRegular.tag),
            const SizedBox(height: 12),

            _dropdown(
              value: _chargingType,
              label: 'Charging type',
              items: _chargingTypes,
              icon: PhosphorIconsRegular.lightning,
              onChanged: (v) =>
                  setState(() => _chargingType = v ?? 'AC'),
            ),
            const SizedBox(height: 12),

            _dropdown(
              value: _connector,
              label: 'Connector type',
              items: _connectors,
              icon: PhosphorIconsRegular.plug,
              onChanged: (v) =>
                  setState(() => _connector = v ?? 'Type 2'),
            ),
            const SizedBox(height: 12),

            _field(_powerCtrl, 'Power (kW)',
                keyboardType: TextInputType.number,
                icon: PhosphorIconsRegular.lightning),
            const SizedBox(height: 12),

            _field(
              _priceCtrl,
              'Price per kWh (${CurrencyFormat.code})',
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true),
              icon: PhosphorIconsRegular.currencyCircleDollar,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
            ),
            const SizedBox(height: 12),

            _field(_durationCtrl, 'Estimated session (minutes)',
                keyboardType: TextInputType.number,
                icon: PhosphorIconsRegular.clockAfternoon),

            const SizedBox(height: 16),

            _SwitchRow(
              icon: PhosphorIconsRegular.door,
              title: 'Bay open for operations',
              subtitle: 'Closed bays are hidden from drivers',
              value: _isOpen,
              onChanged: (v) => setState(() {
                _isOpen = v;
                if (!v) _isAvailable = false;
              }),
            ),
            _SwitchRow(
              icon: PhosphorIconsRegular.checkCircle,
              title: 'Available for booking',
              subtitle: 'Turn off when occupied or in maintenance',
              value: _isAvailable,
              onChanged: _isOpen
                  ? (v) => setState(() => _isAvailable = v)
                  : null,
            ),

            const SizedBox(height: 12),

            _field(_notesCtrl, 'Operator notes (optional)',
                maxLines: 2,
                icon: PhosphorIconsRegular.notepad),

            const SizedBox(height: 20),

            GestureDetector(
              onTap: _save,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: _green,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _green.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.isCreate ? 'Create bay' : 'Save changes',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    TextInputType? keyboardType,
    int maxLines = 1,
    IconData? icon,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      style: GoogleFonts.dmSans(
          fontSize: 15, fontWeight: FontWeight.w500, color: _ink),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(
            fontSize: 13, fontWeight: FontWeight.w500, color: _slate),
        prefixIcon: icon != null
            ? Icon(icon, size: 17, color: _slate)
            : null,
        filled: true,
        fillColor: _white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border, width: 1)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border, width: 1)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: _green, width: 1.5)),
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required String label,
    required List<String> items,
    required void Function(String?) onChanged,
    IconData? icon,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(
            fontSize: 13, fontWeight: FontWeight.w500, color: _slate),
        prefixIcon: icon != null
            ? Icon(icon, size: 17, color: _slate)
            : null,
        filled: true,
        fillColor: _white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border, width: 1)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border, width: 1)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: _green, width: 1.5)),
      ),
      style: GoogleFonts.dmSans(
          fontSize: 15, fontWeight: FontWeight.w500, color: _ink),
      items: items
          .map((t) => DropdownMenuItem(
              value: t,
              child: Text(t,
                  style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: _ink))))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: _green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _ink)),
                Text(subtitle,
                    style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: _slate)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: _green,
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }
}
