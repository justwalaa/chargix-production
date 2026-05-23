import 'package:flutter/material.dart';

import '../../theme/tokens/tokens.dart';

/// Glass-style elevated card for lists and settings groups.
class PremiumCard extends StatelessWidget {
  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final padded = Padding(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.cardGroupPadding,
          ),
      child: child,
    );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.xl),
      side: BorderSide(
        color: scheme.outline.withValues(alpha: 0.18),
      ),
    );

    final surface = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        shape: shape,
        child: onTap == null
            ? padded
            : InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(AppRadii.xl),
                child: padded,
              ),
      ),
    );

    return surface;
  }
}
