import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/project_provider.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_typography.dart';
import '../../../shared/widgets/sidebar/sidebar_item.dart';
import '../../../shared/widgets/sidebar/sidebar_section_header.dart';
import '../../tasks/providers/task_provider.dart';

class SlimSidebar extends ConsumerWidget {
  const SlimSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider);
    final selection = ref.watch(sidebarSelectionProvider);

    final totalTasks = ref.watch(tasksProvider).where((t) => !t.isCompleted).length;
    final todayCount = ref.watch(todayCountProvider);
    final completedCount = ref.watch(completedCountProvider);

    return Container(
      width: AppSpacing.sidebarWidth,
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          right: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header
          const _SidebarHeader(),

          // Search
          const _SidebarSearch(),

          const SizedBox(height: AppSpacing.sm),

          // Smart lists
          SidebarItem(
            icon: Icons.inbox_rounded,
            label: 'Inbox',
            count: totalTasks,
            isActive: selection is ViewSelection &&
                selection.view == ViewType.inbox,
            activeColor: AppColors.accent,
            onTap: () => ref
                .read(sidebarSelectionProvider.notifier)
                .state = const ViewSelection(ViewType.inbox),
          ),
          SidebarItem(
            icon: Icons.calendar_today_rounded,
            label: 'Today',
            count: todayCount,
            isActive: selection is ViewSelection &&
                selection.view == ViewType.today,
            activeColor: AppColors.accent,
            onTap: () => ref
                .read(sidebarSelectionProvider.notifier)
                .state = const ViewSelection(ViewType.today),
          ),
          SidebarItem(
            icon: Icons.check_circle_outline_rounded,
            label: 'Completed',
            count: completedCount,
            isActive: selection is ViewSelection &&
                selection.view == ViewType.completed,
            activeColor: AppColors.success,
            onTap: () => ref
                .read(sidebarSelectionProvider.notifier)
                .state = const ViewSelection(ViewType.completed),
          ),

          // Projects section
          const SidebarSectionHeader(label: 'Projects'),

          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                final color =
                    AppColors.projectColors[project.colorIndex % AppColors.projectColors.length];
                final count = ref.watch(projectTaskCountProvider(project.id));
                return GestureDetector(
                  onSecondaryTapDown: (details) => _showProjectMenu(
                    context, ref, project.id, project.name, details.globalPosition,
                  ),
                  child: SidebarItem(
                    icon: _projectIcon(project.name),
                    label: project.name,
                    count: count > 0 ? count : null,
                    isActive: selection is ProjectSelection &&
                        selection.projectId == project.id,
                    activeColor: color,
                    onTap: () => ref
                        .read(sidebarSelectionProvider.notifier)
                        .state = ProjectSelection(project.id),
                  ),
                );
              },
            ),
          ),

          // Add project button
          const _AddProjectButton(),
        ],
      ),
    );
  }

  void _showProjectMenu(
    BuildContext context,
    WidgetRef ref,
    String projectId,
    String projectName,
    Offset position,
  ) {
    final screenSize = MediaQuery.of(context).size;
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        screenSize.width - position.dx,
        screenSize.height - position.dy,
      ),
      items: [
        PopupMenuItem(
          value: 'rename',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.edit_outlined, size: 15),
              const SizedBox(width: 8),
              Text('Rename', style: AppTypography.bodySmall),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.delete_outline_rounded, size: 15, color: AppColors.danger),
              const SizedBox(width: 8),
              Text('Delete', style: AppTypography.bodySmall.copyWith(color: AppColors.danger)),
            ],
          ),
        ),
      ],
    ).then((action) async {
      if (!context.mounted) return;
      if (action == 'rename') {
        _showRenameDialog(context, ref, projectId, projectName);
      } else if (action == 'delete') {
        final currentSelection = ref.read(sidebarSelectionProvider);
        await ref.read(projectsProvider.notifier).deleteProject(projectId);
        if (!context.mounted) return;
        if (currentSelection is ProjectSelection &&
            currentSelection.projectId == projectId) {
          ref.read(sidebarSelectionProvider.notifier).state =
              const ViewSelection(ViewType.inbox);
        }
      }
    });
  }

  void _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    String projectId,
    String currentName,
  ) {
    final controller = TextEditingController(text: currentName);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Rename Project', style: AppTypography.headingMedium),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Project name',
            hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.accent),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
          ),
          onSubmitted: (_) => _submitRename(ctx, ref, projectId, controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => _submitRename(ctx, ref, projectId, controller.text),
            child: Text('Rename', style: AppTypography.bodySmall.copyWith(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  void _submitRename(
    BuildContext context,
    WidgetRef ref,
    String projectId,
    String name,
  ) {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) {
      ref.read(projectsProvider.notifier).updateProject(projectId, name: trimmed);
    }
    Navigator.of(context).pop();
  }

  IconData _projectIcon(String name) {
    return switch (name.toLowerCase()) {
      'work' => Icons.work_outline_rounded,
      'personal' => Icons.person_outline_rounded,
      'ideas' => Icons.lightbulb_outline_rounded,
      'inbox' => Icons.inbox_rounded,
      _ => Icons.folder_outlined,
    };
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sidebarPadding,
        AppSpacing.xl,
        AppSpacing.sidebarPadding,
        AppSpacing.lg,
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            'Plans',
            style: AppTypography.headingLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarSearch extends ConsumerStatefulWidget {
  const _SidebarSearch();

  @override
  ConsumerState<_SidebarSearch> createState() => _SidebarSearchState();
}

class _SidebarSearchState extends ConsumerState<_SidebarSearch> {
  final _controller = TextEditingController();
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          _clear();
          node.unfocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
    );
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  void _clear() {
    _controller.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(searchFocusRequestProvider, (prev, _) => _focusNode.requestFocus());

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sidebarPadding,
        vertical: AppSpacing.sm,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _isFocused ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.search_rounded,
              size: 15,
              color: _isFocused ? AppColors.accent : AppColors.textMuted,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search tasks...',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  suffixIcon: _controller.text.isNotEmpty
                      ? GestureDetector(
                          onTap: _clear,
                          child: const Icon(Icons.close_rounded, size: 14, color: AppColors.textMuted),
                        )
                      : null,
                ),
                onChanged: (val) {
                  ref.read(searchQueryProvider.notifier).state = val;
                  setState(() {}); // rebuild for suffix icon
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddProjectButton extends ConsumerStatefulWidget {
  const _AddProjectButton();

  @override
  ConsumerState<_AddProjectButton> createState() => _AddProjectButtonState();
}

class _AddProjectButtonState extends ConsumerState<_AddProjectButton> {
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
