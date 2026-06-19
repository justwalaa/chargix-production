import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/chargix_data.dart';
import '../../models/slot_time_window.dart';
import '../../models/station_slot_model.dart';
import '../../utils/currency_format.dart';
import '../../utils/slot_availability.dart';
import '../../widgets/chargix/firebase_stream_view.dart';
import '../../widgets/station/station_slot_editor_sheet.dart';

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

TextStyle _dm(double size, FontWeight w, {Color color = _ink, double? h}) =>
    GoogleFonts.dmSans(fontSize: size, fontWeight: w, color: color, height: h);

class StationSlotsScreen extends StatelessWidget {
  const StationSlotsScreen({super.key, required this.stationId});
  final String stationId;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: _canvas,
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────
          Container(
            color: _white,
            padding: EdgeInsets.fromLTRB(8, topPad + 8, 12, 10),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(PhosphorIconsRegular.arrowLeft,
                      color: _ink, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text('Slots & pricing',
                      style: _sg(17, FontWeight.w700)),
                ),
                GestureDetector(
                  onTap: () => _addSlot(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _green,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: _green.withValues(alpha: 0.28),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(PhosphorIconsRegular.plus,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 5),
                        Text('Add bay',
                            style: _sg(13, FontWeight.w700,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 0.8, color: _border),

          // ── List ──────────────────────────────────────────────────────
          Expanded(
            child: FirebaseStreamView<List<StationSlotModel>>(
              stream: ChargixData.stationOwner.watchSlots(stationId),
              emptyTitle: 'No slots yet',
              emptyMessage: 'Add charging bays to accept reservations.',
              emptyIcon: PhosphorIconsRegular.plugsConnected,
              emptyActionLabel: 'Add slot',
              onEmptyAction: () => _addSlot(context),
              builder: (context, slots) {
                SlotAvailability.compute(slots, logTag: 'SlotSync');
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: slots.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    return _SlotCard(
                      slot: slots[i],
                      stationId: stationId,
                      onEdit: () => _editSlot(context, slots[i]),
                      onToggleOpen: () => _toggleOpen(context, slots[i]),
                      onAddWindow: () =>
                          _addTimeWindow(context, slots[i]),
                      onDeleteWindow: (windowId) =>
                          _deleteTimeWindow(context, slots[i], windowId),
                      onDelete: () => _deleteSlot(context, slots[i]),
                      onShowQr: () => _showQr(context, slots[i]),
                    )
                        .animate()
                        .fadeIn(delay: (50 * i).ms, duration: 260.ms)
                        .slideY(
                            begin: 0.05,
                            end: 0,
                            delay: (50 * i).ms,
                            duration: 260.ms,
                            curve: Curves.easeOut);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editStationPricing(context),
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(PhosphorIconsRegular.currencyCircleDollar, size: 20),
        label: Text('Station pricing',
            style: _sg(13, FontWeight.w700, color: Colors.white)),
      ),
    );
  }

  // ── Bay CRUD ──────────────────────────────────────────────────────────────

  Future<void> _addSlot(BuildContext context) async {
    final id =
        '${stationId}_slot_${DateTime.now().millisecondsSinceEpoch}';
    final draft = StationSlotModel(
      id: id,
      stationId: stationId,
      label: 'Bay ${DateTime.now().millisecondsSinceEpoch % 100}',
      pricePerKwh: 0.35,
    );
    final saved = await StationSlotEditorSheet.show(context,
        initial: draft, isCreate: true);
    if (saved == null || !context.mounted) return;
    await ChargixData.stationOwner.saveSlot(saved);
    if (context.mounted) _snack(context, 'Charging bay added', ok: true);
  }

  Future<void> _editSlot(
      BuildContext context, StationSlotModel slot) async {
    final saved = await StationSlotEditorSheet.show(context,
        initial: slot, isCreate: false);
    if (saved == null || !context.mounted) return;
    await ChargixData.stationOwner.saveSlot(saved);
    if (context.mounted) _snack(context, 'Bay updated', ok: true);
  }

  Future<void> _toggleOpen(
      BuildContext context, StationSlotModel slot) async {
    final nextOpen = !slot.isOpen;
    await ChargixData.stationOwner.saveSlot(slot.copyWith(
      isOpen: nextOpen,
      isAvailable: nextOpen ? slot.isAvailable : false,
    ));
  }

  Future<void> _deleteSlot(
      BuildContext context, StationSlotModel slot) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Delete bay?',
                  style: _sg(17, FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                'Permanently remove ${slot.label}? '
                'Active bookings will not be automatically cancelled.',
                style: _dm(13, FontWeight.w400, color: _slate, h: 1.5),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx, false),
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('Cancel', style: _sg(14, FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx, true),
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('Delete',
                          style: _sg(14, FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
    if (confirm != true || !context.mounted) return;
    await ChargixData.stationOwner.deleteSlot(stationId, slot.id);
    if (context.mounted) _snack(context, 'Bay deleted');
  }

  void _showQr(BuildContext context, StationSlotModel slot) {
    final qrData = 'chargix://station/$stationId/bay/${slot.id}';
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(slot.label,
                  style: _sg(16, FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Permanent bay QR — never changes',
                  style: _dm(12, FontWeight.w400, color: _slate)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(qrData,
                  textAlign: TextAlign.center,
                  style: _dm(10, FontWeight.w400, color: _slate)),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Share.share(qrData,
                    subject: 'Chargix QR — ${slot.label}'),
                child: Container(
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _green,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _green.withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(PhosphorIconsRegular.shareNetwork,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text('Share / Print',
                          style: _sg(14, FontWeight.w700,
                              color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Time-window CRUD ──────────────────────────────────────────────────────

  Future<void> _addTimeWindow(
      BuildContext context, StationSlotModel slot) async {
    final tw = await _showTimeWindowDialog(context);
    if (tw == null || !context.mounted) return;
    final updated = slot.copyWith(
      timeWindows: [...slot.timeWindows, tw],
    );
    await ChargixData.stationOwner.saveSlot(updated);
    if (context.mounted) _snack(context, 'Window ${tw.timeRangeLabel} added', ok: true);
  }

  Future<void> _deleteTimeWindow(
      BuildContext context, StationSlotModel slot, String windowId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Delete window?', style: _sg(17, FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                'Existing bookings for this window are not affected, '
                'but no new bookings can be placed.',
                style: _dm(13, FontWeight.w400, color: _slate, h: 1.5),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx, false),
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('Cancel', style: _sg(14, FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx, true),
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('Delete',
                          style: _sg(14, FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
    if (confirm != true || !context.mounted) return;
    final updated = slot.copyWith(
      timeWindows: slot.timeWindows.where((w) => w.id != windowId).toList(),
    );
    await ChargixData.stationOwner.saveSlot(updated);
    if (context.mounted) _snack(context, 'Window removed', ok: true);
  }

  /// Shows a 24h time-range picker dialog and returns a new [SlotTimeWindow].
  Future<SlotTimeWindow?> _showTimeWindowDialog(BuildContext context) async {
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 9, minute: 40);
    String? errorMsg;

    return showDialog<SlotTimeWindow>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setS) {
            Future<void> pickTime({required bool isStart}) async {
              final picked = await showTimePicker(
                context: ctx,
                initialTime: isStart ? startTime : endTime,
                builder: (c, child) => Theme(
                  data: Theme.of(c).copyWith(
                    colorScheme: Theme.of(c).colorScheme.copyWith(
                          primary: _green,
                          onPrimary: Colors.white,
                        ),
                  ),
                  child: child!,
                ),
              );
              if (picked == null) return;
              setS(() {
                if (isStart) {
                  startTime = picked;
                } else {
                  endTime = picked;
                }
                errorMsg = null;
              });
            }

            String fmt(TimeOfDay t) =>
                '${t.hour.toString().padLeft(2, '0')}:'
                '${t.minute.toString().padLeft(2, '0')}';

            return Dialog(
              backgroundColor: _white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add time window',
                        style: _sg(17, FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('Window repeats every day automatically.',
                        style: _dm(12, FontWeight.w400, color: _slate)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _TimePickerTile(
                            label: 'Start',
                            value: fmt(startTime),
                            onTap: () => pickTime(isStart: true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TimePickerTile(
                            label: 'End',
                            value: fmt(endTime),
                            onTap: () => pickTime(isStart: false),
                          ),
                        ),
                      ],
                    ),
                    if (errorMsg != null) ...[
                      const SizedBox(height: 8),
                      Text(errorMsg!,
                          style:
                              _dm(12, FontWeight.w500,
                                  color: const Color(0xFFDC2626))),
                    ],
                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            height: 46,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(12)),
                            child: Text('Cancel',
                                style: _sg(14, FontWeight.w600)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            final startMins =
                                startTime.hour * 60 + startTime.minute;
                            final endMins =
                                endTime.hour * 60 + endTime.minute;
                            if (endMins <= startMins) {
                              setS(() => errorMsg =
                                  'End time must be after start time.');
                              return;
                            }
                            final tw = SlotTimeWindow(
                              id: 'tw_${DateTime.now().millisecondsSinceEpoch}',
                              startHour: startTime.hour,
                              startMinute: startTime.minute,
                              endHour: endTime.hour,
                              endMinute: endTime.minute,
                            );
                            Navigator.pop(ctx, tw);
                          },
                          child: Container(
                            height: 46,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _green,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: _green.withValues(alpha: 0.28),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text('Add',
                                style: _sg(14, FontWeight.w700,
                                    color: Colors.white)),
                          ),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Station pricing ───────────────────────────────────────────────────────

  Future<void> _editStationPricing(BuildContext context) async {
    final priceCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Station default price',
                  style: _sg(17, FontWeight.w800)),
              const SizedBox(height: 16),
              TextField(
                controller: priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                style: _dm(15, FontWeight.w500),
                decoration: InputDecoration(
                  labelText:
                      'Price per kWh (${CurrencyFormat.code})',
                  prefixText: '${CurrencyFormat.symbol} ',
                  hintText: '0.350',
                  filled: true,
                  fillColor: _white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: _border, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: _border, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: _green, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, false),
                      child: Container(
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12)),
                        child: Text('Cancel',
                            style: _sg(14, FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, true),
                      child: Container(
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _green,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _green.withValues(alpha: 0.28),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text('Update',
                            style: _sg(14, FontWeight.w700,
                                color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (result != true || !context.mounted) return;
    final price = double.tryParse(priceCtrl.text);
    if (price == null || price <= 0) {
      _snack(context, 'Enter a valid price');
      return;
    }
    await ChargixData.stationOwner.updateStationPricing(
      stationId: stationId,
      pricePerKwh: price,
    );
    if (context.mounted) {
      _snack(context,
          'Station price: ${CurrencyFormat.perKwh(price)}',
          ok: true);
    }
  }

  void _snack(BuildContext context, String msg, {bool ok = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: _dm(13, FontWeight.w500, color: Colors.white)),
        backgroundColor: ok ? _greenDark : _ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ── Slot card ─────────────────────────────────────────────────────────────────
class _SlotCard extends StatelessWidget {
  const _SlotCard({
    required this.slot,
    required this.stationId,
    required this.onEdit,
    required this.onToggleOpen,
    required this.onAddWindow,
    required this.onDeleteWindow,
    required this.onDelete,
    required this.onShowQr,
  });

  final StationSlotModel slot;
  final String stationId;
  final VoidCallback onEdit;
  final VoidCallback onToggleOpen;
  final VoidCallback onAddWindow;
  final void Function(String windowId) onDeleteWindow;
  final VoidCallback onDelete;
  final VoidCallback onShowQr;

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    final Color statusBg;
    final IconData statusIcon;
    final String statusLabel;

    if (!slot.isOpen) {
      statusColor = const Color(0xFFDC2626);
      statusBg = const Color(0xFFFEE2E2);
      statusIcon = PhosphorIconsRegular.lockSimple;
      statusLabel = 'Closed';
    } else if (!slot.isAvailable) {
      statusColor = const Color(0xFFD97706);
      statusBg = const Color(0xFFFEF3C7);
      statusIcon = PhosphorIconsRegular.pause;
      statusLabel = 'Busy';
    } else {
      statusColor = _green;
      statusBg = _greenSurface;
      statusIcon = PhosphorIconsFill.checkCircle;
      statusLabel = 'Open';
    }

    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: slot.isAvailable && slot.isOpen ? _green : _border,
            width: slot.isAvailable && slot.isOpen ? 1.5 : 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bay header row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(statusIcon, size: 16, color: statusColor),
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
                        style: _dm(12, FontWeight.w400, color: _slate),
                      ),
                      if (slot.pricePerKwh != null)
                        Text(
                          CurrencyFormat.perKwh(slot.pricePerKwh!),
                          style: _dm(11, FontWeight.w600, color: _green),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(statusLabel,
                      style:
                          _dm(10, FontWeight.w700, color: statusColor)),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(PhosphorIconsRegular.pencilSimple,
                        size: 14, color: _slate),
                  ),
                ),
              ],
            ),
          ),

          // Action buttons row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(
              children: [
                Expanded(
                  child: _ToggleBtn(
                    label: slot.isOpen ? 'Close bay' : 'Open bay',
                    onTap: onToggleOpen,
                    active: slot.isOpen,
                  ),
                ),
                const SizedBox(width: 8),
                // QR button
                GestureDetector(
                  onTap: onShowQr,
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _greenSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: _green.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(PhosphorIconsRegular.qrCode,
                        size: 16, color: _greenDark),
                  ),
                ),
                const SizedBox(width: 8),
                // Delete bay button
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFFDC2626).withValues(alpha: 0.3)),
                    ),
                    child: const Icon(PhosphorIconsRegular.trash,
                        size: 16, color: Color(0xFFDC2626)),
                  ),
                ),
              ],
            ),
          ),

          // Time windows section
          Container(height: 0.8, color: _border),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            child: Row(
              children: [
                Text('Time windows',
                    style: _dm(12, FontWeight.w600, color: _slate)),
                const Spacer(),
                GestureDetector(
                  onTap: onAddWindow,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _greenSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: _green.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(PhosphorIconsRegular.plus,
                            size: 12, color: _greenDark),
                        const SizedBox(width: 4),
                        Text('Add window',
                            style: _dm(11, FontWeight.w600,
                                color: _greenDark)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (slot.timeWindows.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Text(
                'No windows yet — drivers cannot book this bay.',
                style: _dm(11, FontWeight.w400, color: _slate),
              ),
            )
          else ...[
            for (final tw in slot.timeWindows)
              _WindowRow(
                tw: tw,
                onDelete: () => onDeleteWindow(tw.id),
              ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

// ── Time window row ───────────────────────────────────────────────────────────
class _WindowRow extends StatelessWidget {
  const _WindowRow({required this.tw, required this.onDelete});
  final SlotTimeWindow tw;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    // Count how many upcoming dates are still booked (today + tomorrow only)
    final today = SlotTimeWindow.dateKeyFor(DateTime.now());
    final tomorrow = SlotTimeWindow.dateKeyFor(
        DateTime.now().add(const Duration(days: 1)));
    final bookedCount = [today, tomorrow]
        .where((d) => tw.isDateBooked(d))
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 10, 8),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _greenSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _green.withValues(alpha: 0.35)),
            ),
            child: Text(tw.timeRangeLabel,
                style: _dm(12, FontWeight.w600, color: _greenDark)),
          ),
          const SizedBox(width: 8),
          Text(
            '${tw.durationMinutes} min',
            style: _dm(11, FontWeight.w400, color: _slate),
          ),
          if (bookedCount > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$bookedCount booked',
                style: _dm(10, FontWeight.w600,
                    color: const Color(0xFFD97706)),
              ),
            ),
          ],
          const Spacer(),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(PhosphorIconsRegular.trash,
                  size: 13, color: Color(0xFFDC2626)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Toggle button ─────────────────────────────────────────────────────────────
class _ToggleBtn extends StatelessWidget {
  const _ToggleBtn({
    required this.label,
    required this.onTap,
    required this.active,
  });

  final String label;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled
              ? (active ? _greenSurface : const Color(0xFFF3F4F6))
              : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? (active ? _green : _border) : _border,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: enabled
                ? (active ? _greenDark : _slate)
                : const Color(0xFFD1D5DB),
          ),
        ),
      ),
    );
  }
}

// ── Time picker tile ──────────────────────────────────────────────────────────
class _TimePickerTile extends StatelessWidget {
  const _TimePickerTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            const Icon(PhosphorIconsRegular.clockAfternoon,
                size: 16, color: _slate),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: _dm(10, FontWeight.w500, color: _slate)),
                  Text(value, style: _sg(15, FontWeight.w700)),
                ],
              ),
            ),
            const Icon(PhosphorIconsRegular.caretDown,
                size: 12, color: _slate),
          ],
        ),
      ),
    );
  }
}
