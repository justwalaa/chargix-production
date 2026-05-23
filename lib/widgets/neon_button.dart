// lib/widgets/neon_button.dart
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Premium button system for Chargix.
///
/// Variants:
///   NeonButton.primary(...)   — cyan gradient fill + glow shadow
///   NeonButton.violet(...)    — violet gradient fill + glow
///   NeonButton.ghost(...)     — transparent + glowing border
///   NeonButton.danger(...)    — red gradient
///   NeonButton.icon(...)      — icon only, circular
class NeonButton extends StatefulWidget {
  final String? label;
  final IconData? icon;
  final IconData? trailingIcon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final double? width;
  final double borderRadius;
  final _NeonButtonVariant variant;
  final Color? customColor;

  const NeonButton._({
    super.key,
    this.label,
    this.icon,
    this.trailingIcon,
    this.onPressed,
    this.isLoading = false,
    this.height = 54,
    this.width,
    this.borderRadius = 16,
    required this.variant,
    this.customColor,
  });

  // ── Presets ────────────────────────────────────────────────────────────────

  const NeonButton.primary({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    bool isLoading = false,
    double height = 54,
    double? width,
    IconData? trailingIcon,
  }) : this._(
    key: key,
    label: label,
    onPressed: onPressed,
    isLoading: isLoading,
    height: height,
    width: width,
    trailingIcon: trailingIcon,
    variant: _NeonButtonVariant.primary,
  );

  const NeonButton.violet({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    bool isLoading = false,
    double height = 54,
    double? width,
  }) : this._(
    key: key,
    label: label,
    onPressed: onPressed,
    isLoading: isLoading,
    height: height,
    width: width,
    variant: _NeonButtonVariant.violet,
  );

  const NeonButton.ghost({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    bool isLoading = false,
    double height = 54,
    double? width,
    Color? color,
  }) : this._(
    key: key,
    label: label,
    onPressed: onPressed,
    isLoading: isLoading,
    height: height,
    width: width,
    variant: _NeonButtonVariant.ghost,
    customColor: color,
  );

  const NeonButton.danger({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    bool isLoading = false,
    double height = 54,
    double? width,
  }) : this._(
    key: key,
    label: label,
    onPressed: onPressed,
    isLoading: isLoading,
    height: height,
    width: width,
    variant: _NeonButtonVariant.danger,
  );

  factory NeonButton.icon({
    Key? key,
    required IconData icon,
    required VoidCallback? onPressed,
    double size = 48,
    Color? color,
    bool glow = false,
  }) =>
      NeonButton._(
        key: key,
        icon: icon,
        onPressed: onPressed,
        height: size,
        width: size,
        borderRadius: size / 2,
        variant: _NeonButtonVariant.icon,
        customColor: color,
      );

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

enum _NeonButtonVariant { primary, violet, ghost, danger, icon }

class _NeonButtonState extends State<NeonButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  void _onTapDown(TapDownDetails _) {
    if (_enabled) _pressController.forward();
  }

  void _onTapUp(TapUpDetails _) {
    if (_enabled) {
      _pressController.reverse();
      widget.onPressed?.call();
    }
  }

  void _onTapCancel() => _pressController.reverse();

  // ── Style helpers ─────────────────────────────────────────────────────────

  Gradient? get _gradient {
    if (!_enabled) return null;
    switch (widget.variant) {
      case _NeonButtonVariant.primary:
        return AppColors.primaryGradient;
      case _NeonButtonVariant.violet:
        return AppColors.violetGradient;
      case _NeonButtonVariant.danger:
        return LinearGradient(
            colors: [AppColors.red, AppColors.redMid]);
      case _NeonButtonVariant.icon:
        return LinearGradient(colors: [
          (widget.customColor ?? AppColors.cyan).withAlpha(40),
          (widget.customColor ?? AppColors.cyan).withAlpha(20),
        ]);
      case _NeonButtonVariant.ghost:
        return null;
    }
  }

  Color get _backgroundColor {
    if (!_enabled) return AppColors.bg4;
    if (widget.variant == _NeonButtonVariant.ghost) return Colors.transparent;
    return Colors.transparent;
  }

  Color get _labelColor {
    if (!_enabled) return AppColors.textMuted;
    switch (widget.variant) {
      case _NeonButtonVariant.ghost:
        return widget.customColor ?? AppColors.cyan;
      case _NeonButtonVariant.icon:
        return widget.customColor ?? AppColors.cyan;
      default:
        return AppColors.bg1;
    }
  }

  Border? get _border {
    switch (widget.variant) {
      case _NeonButtonVariant.ghost:
        final c = widget.customColor ?? AppColors.cyan;
        return Border.all(
          color: _enabled ? c.withAlpha(100) : AppColors.border1,
          width: 1,
        );
      case _NeonButtonVariant.icon:
        final c = widget.customColor ?? AppColors.cyan;
        return Border.all(color: c.withAlpha(50), width: 0.8);
      default:
        return null;
    }
  }

  List<BoxShadow> get _shadows {
    if (!_enabled) return [];
    switch (widget.variant) {
      case _NeonButtonVariant.primary:
        return [
          BoxShadow(
            color: AppColors.cyanGlow(0.3),
            blurRadius: 20,
            spreadRadius: -6,
            offset: const Offset(0, 8),
          ),
        ];
      case _NeonButtonVariant.violet:
        return [
          BoxShadow(
            color: AppColors.violetGlow(0.3),
            blurRadius: 20,
            spreadRadius: -6,
            offset: const Offset(0, 8),
          ),
        ];
      case _NeonButtonVariant.danger:
        return [
          BoxShadow(
            color: AppColors.redGlow(0.3),
            blurRadius: 20,
            spreadRadius: -6,
            offset: const Offset(0, 8),
          ),
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            gradient: _gradient,
            color: _gradient == null ? _backgroundColor : null,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: _border,
            boxShadow: _shadows,
          ),
          child: Center(child: _buildContent()),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (widget.isLoading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.variant == _NeonButtonVariant.ghost ||
                widget.variant == _NeonButtonVariant.icon
                ? (widget.customColor ?? AppColors.cyan)
                : AppColors.bg1,
          ),
        ),
      );
    }

    if (widget.variant == _NeonButtonVariant.icon && widget.icon != null) {
      return Icon(
        widget.icon,
        color: _labelColor,
        size: widget.height * 0.42,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, color: _labelColor, size: 18),
            const SizedBox(width: 8),
          ],
          if (widget.label != null)
            Text(
              widget.label!,
              style: AppTextStyles.button.copyWith(color: _labelColor),
            ),
          if (widget.trailingIcon != null) ...[
            const SizedBox(width: 8),
            Icon(widget.icon, color: _labelColor, size: 18),
          ],
        ],
      ),
    );
  }
}