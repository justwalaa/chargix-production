// lib/widgets/glass_card.dart
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Premium glassmorphic card widget — the core visual building block.
///
/// Three presets cover most use cases:
///   GlassCard(child: ...)           → standard glass card
///   GlassCard.glow(...)             → card with cyan glow shadow
///   GlassCard.flat(...)             → solid card, no blur (better in lists)
///
/// The [blur] flag enables true BackdropFilter blur. Disable it in lists
/// with many items for better performance.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? borderColor;
  final double borderWidth;
  final Color? glowColor;
  final double glowOpacity;
  final double glowBlur;
  final Gradient? gradient;
  final Color? backgroundColor;
  final bool blur;
  final double blurSigma;
  final VoidCallback? onTap;
  final bool animate; // Subtle press scale

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
    this.borderColor,
    this.borderWidth = 0.8,
    this.glowColor,
    this.glowOpacity = 0,
    this.glowBlur = 28,
    this.gradient,
    this.backgroundColor,
    this.blur = false,
    this.blurSigma = 10,
    this.onTap,
    this.animate = true,
  });

  // ── Presets ────────────────────────────────────────────────────────────────

  const GlassCard.glow({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    double borderRadius = 20,
    Color glowColor = AppColors.cyan,
    double glowOpacity = 0.15,
    VoidCallback? onTap,
  }) : this(
    key: key,
    child: child,
    padding: padding,
    borderRadius: borderRadius,
    glowColor: glowColor,
    glowOpacity: glowOpacity,
    onTap: onTap,
  );

  const GlassCard.flat({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    double borderRadius = 20,
    VoidCallback? onTap,
  }) : this(
    key: key,
    child: child,
    padding: padding,
    borderRadius: borderRadius,
    blur: false,
    onTap: onTap,
  );

  @override
  Widget build(BuildContext context) {
    final effectiveBorder =
        borderColor ?? AppColors.cyan.withAlpha((0.12 * 255).round());

    // The inner container
    Widget inner = Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.cardGradient,
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: effectiveBorder,
          width: borderWidth,
        ),
      ),
      child: child,
    );

    // Optional blur
    if (blur) {
      inner = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: inner,
        ),
      );
    } else {
      inner = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: inner,
      );
    }

    // Glow shadow wrapper
    Widget result = glowOpacity > 0
        ? Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: (glowColor ?? AppColors.cyan)
                .withAlpha((glowOpacity * 255).round()),
            blurRadius: glowBlur,
            spreadRadius: -6,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: inner,
    )
        : inner;

    // Tap handler with optional press animation
    if (onTap != null) {
      if (animate) {
        result = _AnimatedTap(onTap: onTap!, child: result);
      } else {
        result = GestureDetector(onTap: onTap, child: result);
      }
    }

    return result;
  }
}

// ── Press scale animation ──────────────────────────────────────────────────

class _AnimatedTap extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _AnimatedTap({required this.onTap, required this.child});

  @override
  State<_AnimatedTap> createState() => _AnimatedTapState();
}

class _AnimatedTapState extends State<_AnimatedTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

// ── GlowDot — small status indicator ──────────────────────────────────────

class GlowDot extends StatelessWidget {
  final Color color;
  final double size;
  final bool pulse;

  const GlowDot({
    super.key,
    required this.color,
    this.size = 8,
    this.pulse = false,
  });

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(100),
            blurRadius: size * 1.5,
            spreadRadius: 0,
          ),
        ],
      ),
    );

    if (!pulse) return dot;
    return _PulsingDot(color: color, size: size, child: dot);
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  final double size;
  final Widget child;

  const _PulsingDot({required this.color, required this.size, required this.child});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _pulse = Tween<double>(begin: 1.0, end: 2.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, _) => Container(
            width: widget.size * _pulse.value,
            height: widget.size * _pulse.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withAlpha(
                (70 * (1 - _controller.value)).round(),
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

// ── StatusBadge ────────────────────────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool showDot;
  final bool pulseDot;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.showDot = true,
    this.pulseDot = false,
  });

  factory StatusBadge.fromStatus(String status) {
    return StatusBadge(
      label: status,
      color: AppColors.statusColor(status),
      pulseDot: status.toLowerCase() == 'available' ||
          status.toLowerCase() == 'charging',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(50), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            GlowDot(color: color, size: 6, pulse: pulseDot),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}