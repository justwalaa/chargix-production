import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/navigation/main_tab_scope.dart';
import '../../core/result/data_state.dart';
import '../../data/chargix_data.dart';
import '../../models/booking_model.dart';
import '../../models/slot_time_window.dart';
import '../../models/station_model.dart';
import '../../models/station_slot_model.dart';
import '../../widgets/chargix/firebase_stream_view.dart';

// ── Design tokens ────────────────────────────────────────────────────────────
const _green        = Color(0xFF22C55E);
const _greenDark    = Color(0xFF16A34A);
const _greenSurface = Color(0xFFDCFCE7);
const _canvas       = Color(0xFFF8F9FA);
const _white        = Color(0xFFFFFFFF);
const _ink          = Color(0xFF101828);
const _slate        = Color(0xFF6B7280);
const _border       = Color(0xFFE5E7EB);

TextStyle _sg(double size, FontWeight w,
    {Color color = _ink, double ls = 0}) =>
    GoogleFonts.spaceGrotesk(
        fontSize: size, fontWeight: w, color: color, letterSpacing: ls);

TextStyle _dm(double size, FontWeight w,
    {Color color = _ink, double? h}) =>
    GoogleFonts.dmSans(fontSize: size, fontWeight: w, color: color, height: h);

/// Driver flow: pick a bay's time window for today or tomorrow → atomic booking.
class BookSlotScreen extends StatefulWidget {
  const BookSlotScreen({super.key, required this.station});
  final StationModel station;

  @override
  State<BookSlotScreen> createState() => _BookSlotScreenState();
}

class _BookSlotScreenState extends State<BookSlotScreen> {
  // Current selection
  StationSlotModel? _selectedSlot;
  String? _selectedWindowId;
  String? _selectedDateKey;

  bool _submitting = false;

  String get _todayKey => SlotTimeWindow.dateKeyFor(DateTime.now());
  String get _tomorrowKey =>
      SlotTimeWindow.dateKeyFor(DateTime.now().add(const Duration(days: 1)));

  bool get _hasSelection =>
      _selectedSlot != null &&
      _selectedWindowId != null &&
      _selectedDateKey != null;

  void _selectWindow(StationSlotModel slot, SlotTimeWindow tw, String dateKey) {
    setState(() {
      _selectedSlot = slot;
      _selectedWindowId = tw.id;
      _selectedDateKey = dateKey;
    });
  }

  Future<void> _submit() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || !_hasSelection) {
      _snack('Select a time window first');
      return;
    }
    setState(() => _submitting = true);

    final result = await ChargixData.bookings.reserveSlot(
      userId: uid,
      station: widget.station,
      slot: _selectedSlot!,
      windowId: _selectedWindowId!,
      dateKey: _selectedDateKey!,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result is DataSuccess<BookingModel>) {
      _snack('Booking submitted — awaiting station approval', ok: true);
      Navigator.of(context).pop();
      MainTabScope.goTo(context, MainTabIndex.bookings);
    } else if (result is DataError<BookingModel>) {
      _snack('${result.errorOrNull}');
    }
  }

  void _snack(String msg, {bool ok = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: _dm(13, FontWeight.w500, color: Colors.white)),
        backgroundColor: ok ? _greenDark : _ink,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final station = widget.station;
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _canvas,
      body: Column(
        children: [
          // ── AppBar ────────────────────────────────────────────────────
          Container(
            color: _white,
            padding: EdgeInsets.fromLTRB(8, topPad + 8, 16, 10),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(PhosphorIconsRegular.arrowLeft,
                      color: _ink, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text('Book charging session',
                      style: _sg(17, FontWeight.w700)),
                ),
              ],
            ),
          ),
          Container(height: 0.8, color: _border),

          // ── Body scroll ───────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              children: [
                // Station card
                _StationCard(station: station)
                    .animate()
                    .fadeIn(duration: 320.ms)
                    .slideY(begin: 0.06, end: 0, duration: 320.ms,
                        curve: Curves.easeOut),

                const SizedBox(height: 16),

                // Date legend
                _DateLegend(todayKey: _todayKey, tomorrowKey: _tomorrowKey)
                    .animate()
                    .fadeIn(delay: 60.ms, duration: 280.ms),

                const SizedBox(height: 16),

                // Bays with time windows
                FirebaseStreamView<List<StationSlotModel>>(
                  stream: ChargixData.stationOwner.watchSlots(station.id),
                  emptyTitle: 'No bays configured',
                  emptyMessage:
                      'This station has no charging bays set up yet.',
                  emptyIcon: PhosphorIconsRegular.plug,
                  builder: (context, slots) {
                    final open = slots.where((s) => s.isOpen).toList();
                    if (open.isEmpty) {
                      return _InfoBox(
                        icon: PhosphorIconsRegular.warningCircle,
                        message: 'All bays are currently closed.',
                      );
                    }
                    return Column(
                      children: [
                        for (int i = 0; i < open.length; i++) ...[
                          _BayCard(
                            slot: open[i],
                            todayKey: _todayKey,
                            tomorrowKey: _tomorrowKey,
                            selectedWindowId: _selectedSlot?.id == open[i].id
                                ? _selectedWindowId
                                : null,
                            selectedDateKey: _selectedSlot?.id == open[i].id
                                ? _selectedDateKey
                                : null,
                            onSelect: (tw, dateKey) =>
                                _selectWindow(open[i], tw, dateKey),
                          )
                              .animate()
                              .fadeIn(delay: (60 * i).ms, duration: 260.ms)
                              .slideY(
                                  begin: 0.05,
                                  end: 0,
                                  delay: (60 * i).ms,
                                  duration: 260.ms,
                                  curve: Curves.easeOut),
                          if (i < open.length - 1)
                            const SizedBox(height: 12),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // ── Submit button ─────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPad),
            decoration: BoxDecoration(
              color: _white,
              border: Border(top: BorderSide(color: _border, width: 0.8)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: GestureDetector(
              onTap: (_submitting || !_hasSelection) ? null : _submit,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 54,
                decoration: BoxDecoration(
                  color: _submitting
                      ? const Color(0xFFE5E7EB)
                      : _hasSelection
                          ? _green
                          : const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: (!_submitting && _hasSelection)
                      ? [
                          BoxShadow(
                            color: _green.withValues(alpha: 0.32),
                            blurRadius: 18,
                            spreadRadius: -4,
                            offset: const Offset(0, 7),
                          ),
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: _submitting
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              _green.withValues(alpha: 0.7)),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(PhosphorIconsRegular.calendarCheck,
                              color: _hasSelection
                                  ? Colors.white
                                  : _greenDark,
                              size: 18),
                          const SizedBox(width: 8),
                          Text(
                            _hasSelection
                                ? 'Request booking'
                                : 'Select a time window',
                            style: _sg(15, FontWeight.w700,
                                color: _hasSelection
                                    ? Colors.white
                                    : _greenDark),
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

// ── Station summary card ──────────────────────────────────────────────────────
class _StationCard extends StatelessWidget {
  const _StationCard({required this.station});
  final StationModel station;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _greenSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(PhosphorIconsFill.lightning,
                color: _greenDark, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(station.name,
                    style: _sg(14, FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(station.address,
                    style: _dm(12, FontWeight.w400, color: _slate),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Date legend ───────────────────────────────────────────────────────────────
class _DateLegend extends StatelessWidget {
  const _DateLegend({required this.todayKey, required this.tomorrowKey});
  final String todayKey;
  final String tomorrowKey;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final todayLabel =
        '${now.day}/${now.month}/${now.year}';
    final tomorrowLabel =
        '${tomorrow.day}/${tomorrow.month}/${tomorrow.year}';

    return Row(
      children: [
        _chip(color: _green, label: 'Today ($todayLabel)'),
        const SizedBox(width: 10),
        _chip(color: _green, label: 'Tomorrow ($tomorrowLabel)'),
        const Spacer(),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
              color: const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 4),
        Text('Booked', style: _dm(11, FontWeight.w400, color: _slate)),
      ],
    );
  }

  Widget _chip({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 4),
        Text(label, style: _dm(11, FontWeight.w400, color: _slate)),
      ],
    );
  }
}

// ── Bay card (slot + its time windows) ───────────────────────────────────────
class _BayCard extends StatelessWidget {
  const _BayCard({
    required this.slot,
    required this.todayKey,
    required this.tomorrowKey,
    required this.selectedWindowId,
    required this.selectedDateKey,
    required this.onSelect,
  });

  final StationSlotModel slot;
  final String todayKey;
  final String tomorrowKey;
  final String? selectedWindowId;
  final String? selectedDateKey;
  final void Function(SlotTimeWindow tw, String dateKey) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bay header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _greenSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(PhosphorIconsFill.plug,
                      size: 14, color: _greenDark),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(slot.label,
                          style: _sg(14, FontWeight.w700)),
                      Text(
                        '${slot.chargingType} · ${slot.connectorType} · '
                        '${slot.powerKw.toStringAsFixed(0)} kW',
                        style: _dm(11, FontWeight.w400, color: _slate),
                      ),
                    ],
                  ),
                ),
                if (slot.pricePerKwh != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _greenSurface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${slot.pricePerKwh!.toStringAsFixed(3)}/kWh',
                      style: _dm(10, FontWeight.w700, color: _greenDark),
                    ),
                  ),
              ],
            ),
          ),
          Container(height: 0.8, color: _border),

          // Time windows
          if (slot.timeWindows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                'No time windows configured yet.',
                style: _dm(12, FontWeight.w400, color: _slate),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  for (final tw in slot.timeWindows)
                    _WindowRow(
                      tw: tw,
                      todayKey: todayKey,
                      tomorrowKey: tomorrowKey,
                      selectedDateKey:
                          selectedWindowId == tw.id ? selectedDateKey : null,
                      onSelect: (dateKey) => onSelect(tw, dateKey),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Window row with Today / Tomorrow buttons ──────────────────────────────────
class _WindowRow extends StatelessWidget {
  const _WindowRow({
    required this.tw,
    required this.todayKey,
    required this.tomorrowKey,
    required this.selectedDateKey,
    required this.onSelect,
  });

  final SlotTimeWindow tw;
  final String todayKey;
  final String tomorrowKey;
  final String? selectedDateKey;
  final void Function(String dateKey) onSelect;

  @override
  Widget build(BuildContext context) {
    final todayBooked = tw.isDateBooked(todayKey);
    final tomorrowBooked = tw.isDateBooked(tomorrowKey);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          // Time range label
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _canvas,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _border),
            ),
            child: Text(tw.timeRangeLabel,
                style: _dm(12, FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          // Today button
          _DateBtn(
            label: 'Today',
            booked: todayBooked,
            selected: selectedDateKey == todayKey,
            onTap: todayBooked ? null : () => onSelect(todayKey),
          ),
          const SizedBox(width: 6),
          // Tomorrow button
          _DateBtn(
            label: 'Tomorrow',
            booked: tomorrowBooked,
            selected: selectedDateKey == tomorrowKey,
            onTap: tomorrowBooked ? null : () => onSelect(tomorrowKey),
          ),
        ],
      ),
    );
  }
}

// ── Date availability button ──────────────────────────────────────────────────
class _DateBtn extends StatelessWidget {
  const _DateBtn({
    required this.label,
    required this.booked,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool booked;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final Color border;

    if (booked) {
      bg = const Color(0xFFF3F4F6);
      fg = const Color(0xFFD1D5DB);
      border = _border;
    } else if (selected) {
      bg = _green;
      fg = Colors.white;
      border = _green;
    } else {
      bg = _greenSurface;
      fg = _greenDark;
      border = _green.withValues(alpha: 0.4);
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border, width: selected ? 1.5 : 1.0),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _green.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          booked ? '$label ✕' : label,
          style: _dm(11, FontWeight.w600, color: fg),
        ),
      ),
    );
  }
}

// ── Info box ──────────────────────────────────────────────────────────────────
class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _slate),
          const SizedBox(width: 12),
          Expanded(
            child:
                Text(message, style: _dm(13, FontWeight.w400, color: _slate)),
          ),
        ],
      ),
    );
  }
}
