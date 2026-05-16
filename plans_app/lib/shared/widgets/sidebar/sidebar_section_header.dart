import 'package:flutter/material.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_typography.dart';

class SidebarSectionHeader extends StatelessWidget {
  final String label;

  const SidebarSectionHeader({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sidebarPadding,
        AppSpacing.sidebarSectionGap,
        AppSpacing.sidebarPadding,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: AppTypography.overline.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
