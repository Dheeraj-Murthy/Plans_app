import 'package:flutter/material.dart';
import '../../theme/app_animations.dart';
import '../../theme/app_theme.dart';

class HoverActionIcon extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const HoverActionIcon({super.key, required this.icon, this.onTap});

  @override
  State<HoverActionIcon> createState() => _HoverActionIconState();
}

class _HoverActionIconState extends State<HoverActionIcon> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          curve: AppAnimations.easeOut,
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.elevated : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            widget.icon,
            size: 15,
            color: _isHovered ? AppColors.textSecondary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
