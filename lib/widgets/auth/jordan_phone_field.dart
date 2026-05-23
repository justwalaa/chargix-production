import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/tokens/tokens.dart';

/// Jordan mobile: fixed `+962` prefix and 9-digit national number (e.g. 7XXXXXXXX).
class JordanPhoneField extends StatelessWidget {
  const JordanPhoneField({
    super.key,
    required this.controller,
    required this.focusNode,
    this.errorText,
    this.onSubmitted,
  });

  static const String countryCode = '+962';
  static const int nationalDigits = 9;

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? errorText;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mobile number',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: scheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                countryCode,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                maxLines: 1,
                maxLength: nationalDigits,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w600,
                    ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '7XXXXXXXX',
                  errorText: errorText,
                ),
                onSubmitted: onSubmitted,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Enter your 9-digit Jordan mobile number without the leading zero.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
        ),
      ],
    );
  }

  /// Returns E.164 style `+962` + digits, or null if invalid.
  static String? composeE164(String nationalDigitsOnly) {
    final trimmed = nationalDigitsOnly.trim();
    if (!_jordanMobile.hasMatch(trimmed)) {
      return null;
    }
    return '$countryCode$trimmed';
  }

  static final RegExp _jordanMobile = RegExp(r'^7\d{8}$');
}
