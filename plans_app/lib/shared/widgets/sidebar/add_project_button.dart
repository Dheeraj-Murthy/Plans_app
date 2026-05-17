import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_typography.dart';
import '../../../features/projects/providers/project_provider.dart';

class AddProjectButton extends ConsumerStatefulWidget {
  const AddProjectButton({super.key});

  @override
  ConsumerState<AddProjectButton> createState() => _AddProjectButtonState();
}

class _AddProjectButtonState extends ConsumerState<AddProjectButton> {
  bool _isAdding = false;
  bool _isHovered = false;
  final _controller = TextEditingController();
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          _cancel();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startAdding() {
    setState(() => _isAdding = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) {
      final projects = ref.read(projectsProvider);
      final colorIndex = projects.length % AppColors.projectColors.length;
      ref.read(projectsProvider.notifier).addProject(name, colorIndex: colorIndex);
    }
    _cancel();
  }

  void _cancel() {
    _controller.clear();
    setState(() => _isAdding = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdding) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sidebarPadding,
          AppSpacing.sm,
          AppSpacing.sidebarPadding,
          AppSpacing.lg,
        ),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Project name...',
            hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: AppColors.accent),
            ),
            isDense: true,
          ),
          onSubmitted: (_) => _submit(),
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: _startAdding,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sidebarPadding + 4,
            AppSpacing.sm,
            AppSpacing.sidebarPadding,
            AppSpacing.lg,
          ),
          child: Row(
            children: [
              Icon(
                Icons.add_rounded,
                size: 16,
                color: _isHovered ? AppColors.textSecondary : AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Add Project',
                style: AppTypography.bodySmall.copyWith(
                  color: _isHovered ? AppColors.textSecondary : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
