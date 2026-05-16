import 'package:flutter/material.dart';
import '../../../theme/app_animations.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_typography.dart';

class SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final int? count;
  final Color? activeColor;
  final bool isActive;
  final VoidCallback onTap;

  const SidebarItem({
    super.key,
    required this.icon,
    required this.label,
    this.count,
    this.activeColor,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<SidebarItem> {
  bool _isHovered = false;

  Color get _resolvedColor =>
      widget.activeColor ?? AppColors.accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sidebarPadding,
        vertical: 1,
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: AppAnimations.normal,
            curve: AppAnimations.easeOut,
            height: AppSpacing.sidebarItemHeight,
            decoration: BoxDecoration(
              color: widget.isActive
                  ? _resolvedColor.withValues(alpha: 0.12)
                  : (_isHovered
                      ? AppColors.surface
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const SizedBox(width: AppSpacing.md),
                Icon(
                  widget.icon,
                  size: 17,
                  color: widget.isActive
                      ? _resolvedColor
                      : (_isHovered
                          ? AppColors.textPrimary
                          : AppColors.textSecondary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    widget.label,
                    style: (widget.isActive
                            ? AppTypography.sidebarActive
                            : AppTypography.sidebarItem)
                        .copyWith(
                      color: widget.isActive
                          ? _resolvedColor
                          : (_isHovered
                              ? AppColors.textPrimary
                              : AppColors.textSecondary),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.count != null && widget.count! > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${widget.count}',
                      style: AppTypography.sidebarCount.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
