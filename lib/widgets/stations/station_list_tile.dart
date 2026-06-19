import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../models/station_model.dart';

const _green        = Color(0xFF22C55E);
const _greenDark    = Color(0xFF16A34A);
const _greenSurface = Color(0xFFDCFCE7);
const _white        = Color(0xFFFFFFFF);
const _ink          = Color(0xFF101828);
const _slate        = Color(0xFF6B7280);
const _border       = Color(0xFFE5E7EB);

class StationListTile extends StatelessWidget {
  const StationListTile({
    super.key,
    required this.station,
    required this.onTap,
  });

  final StationModel station;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final available = station.availablePorts > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _greenSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: _green.withValues(alpha: 0.25), width: 1),
              ),
              child: const Icon(PhosphorIconsFill.lightning,
                  color: _greenDark, size: 22),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + verified badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          station.name,
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _ink),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(PhosphorIconsFill.sealCheck,
                          size: 14, color: _green),
                    ],
                  ),
                  const SizedBox(height: 3),
                  // Address
                  Text(
                    station.address,
                    style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: _slate),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Price + rating row
                  Row(
                    children: [
                      const Icon(PhosphorIconsRegular.lightning,
                          size: 12, color: _slate),
                      const SizedBox(width: 3),
                      Text(
                        '${station.pricePerKwh.toStringAsFixed(3)} JOD/kWh',
                        style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _slate),
                      ),
                      const SizedBox(width: 10),
                      const Icon(PhosphorIconsFill.star,
                          size: 12, color: Color(0xFFD97706)),
                      const SizedBox(width: 3),
                      Text(
                        station.rating.toStringAsFixed(1),
                        style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _slate),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Availability + chevron
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: available
                        ? _greenSurface
                        : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    available
                        ? '${station.availablePorts} open'
                        : 'Full',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: available
                          ? _greenDark
                          : const Color(0xFFDC2626),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Icon(PhosphorIconsRegular.caretRight,
                    size: 16, color: _slate),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
