import 'package:flutter/material.dart';
import '../../theme/app_animations.dart';
import '../../theme/app_theme.dart';

class HoverSurface extends StatefulWidget {
  final Widget child;
  final Color? hoverColor;
  final Duration duration;
  final Curve curve;
  final double borderRadius;

  const HoverSurface({
    super.key,
    required this.child,
    this.hoverColor,
    this.duration = AppAnimations.normal,
    this.curve = AppAnimations.easeOut,
    this.borderRadius = 8,
  });

  @override
  State<HoverSurface> createState() => _HoverSurfaceState();
}

class _HoverSurfaceState extends State<HoverSurface> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: widget.duration,
        curve: widget.curve,
        decoration: BoxDecoration(
          color: _isHovered
              ? (widget.hoverColor ?? AppColors.surface)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: widget.child,
      ),
    );
  }
}
