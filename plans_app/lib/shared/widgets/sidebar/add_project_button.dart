import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/projects/providers/project_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

class AddProjectButton extends ConsumerStatefulWidget {
  const AddProjectButton({super.key});

  @override
  ConsumerState<AddProjectButton> createState() => _AddProjectButtonState();
}

class _AddProjectButtonState extends ConsumerState<AddProjectButton> {
  final _controller = TextEditingController();
  int _selectedColor = 0;

  void _showDialog() {
    _selectedColor = ref.read(projectsProvider).length % 5;
    _controller.clear();
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            _controller.addListener(() => setDialogState(() {}));
            final name = _controller.text.trim();
            final canCreate = name.isNotEmpty;

            void submit() {
              if (!canCreate) return;
              ref.read(projectsProvider.notifier).addProject(name, colorIndex: _selectedColor);
              Navigator.of(ctx).pop();
            }

            return AlertDialog(
              backgroundColor: AppColors.elevated,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.border),
              ),
              title: Text(
                'New Project',
                style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    onSubmitted: (_) => submit(),
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Project name',
                      hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.accent),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final isSelected = _selectedColor == i;
                      return GestureDetector(
                        onTap: () => setDialogState(() => _selectedColor = i),
                        child: Container(
                          width: 28,
                          height: 28,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: AppColors.projectColors[i],
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 2.5)
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : null,
                        ),
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'Cancel',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                  ),
                ),
                TextButton(
                  onPressed: canCreate ? submit : null,
                  child: Text(
                    'Create',
                    style: AppTypography.bodySmall.copyWith(color: canCreate ? AppColors.accent : AppColors.textMuted),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sidebarPadding),
      child: GestureDetector(
        onTap: _showDialog,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Icon(Icons.add_rounded, size: 16, color: AppColors.textMuted),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Add Project',
                style: AppTypography.sidebarItem.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
