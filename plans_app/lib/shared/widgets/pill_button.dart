import 'package:flutter/material.dart';
import '../../theme/app_animations.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';

class PillButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const PillButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedContainer(
          duration: AppAnimations.fast,
          curve: AppAnimations.easeOut,
          transform: _isPressed
              ? (Matrix4.identity()..scaleByDouble(0.97, 0.97, 0.97, 1))
              : Matrix4.identity(),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: _isHovered
                ? (widget.backgroundColor ?? AppColors.accentHover)
                : (widget.backgroundColor ?? AppColors.accent),
            borderRadius: BorderRadius.circular(20),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: (widget.backgroundColor ?? AppColors.accent)
                          .withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 16,
                  color: widget.foregroundColor ?? Colors.white,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: AppTypography.label.copyWith(
                  color: widget.foregroundColor ?? Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
