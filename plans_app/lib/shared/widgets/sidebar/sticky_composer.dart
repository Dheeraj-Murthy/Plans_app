import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_animations.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../features/tasks/models/task.dart';
import '../../../features/tasks/providers/task_provider.dart';
import '../../../features/projects/providers/project_provider.dart';
import '../app_chip.dart';

class StickyComposer extends ConsumerStatefulWidget {
  const StickyComposer({super.key});

  @override
  ConsumerState<StickyComposer> createState() => _StickyComposerState();
}

class _StickyComposerState extends ConsumerState<StickyComposer> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _focusNode = FocusNode();
  final _priorityKey = GlobalKey();
  final _projectKey = GlobalKey();

  bool _isHovered = false;
  bool _hasText = false;
  bool _isExpanded = false;

  TaskPriority _priority = TaskPriority.none;
  DateTime? _dueDate;
  int _localProjectIndex = 0;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  void _onTextChanged() {
    final hasText = _titleController.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _syncProjectToSelection();
      setState(() => _isExpanded = true);
    }
  }

  void _requestFocus() {
    _focusNode.requestFocus();
  }

  void _syncProjectToSelection() {
    final selection = ref.read(sidebarSelectionProvider);
    final projects = ref.read(projectsProvider);
    if (projects.isEmpty) return;
    if (selection is ProjectSelection) {
      final idx = projects.indexWhere((p) => p.id == selection.projectId);
      if (idx >= 0) _localProjectIndex = idx;
    } else if (selection is ViewSelection &&
        selection.view == ViewType.inbox) {
      final idx = projects.indexWhere((p) => p.id == 'default');
      if (idx >= 0) _localProjectIndex = idx;
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTextChanged);
    _titleController.dispose();
    _descriptionController.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _titleController.text.trim();
    if (text.isEmpty) return;
    final desc = _descriptionController.text.trim();
    final projects = ref.read(projectsProvider);
    final projectId = projects.isNotEmpty
        ? projects[_localProjectIndex % projects.length].id
        : 'default';
    ref.read(tasksProvider.notifier).addTask(
          title: text,
          description: desc.isNotEmpty ? desc : null,
          dueDate: _dueDate,
          priority: _priority,
          projectId: projectId,
        );
    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _priority = TaskPriority.none;
      _dueDate = null;
      _isExpanded = false;
    });
    _focusNode.unfocus();
  }

  void _showPriorityMenu() {
    final box = _priorityKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;
    showMenu<TaskPriority>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx, offset.dy,
        offset.dx + size.width, offset.dy,
      ),
      items: [
        for (final p in TaskPriority.values)
          PopupMenuItem(
            value: p,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  p == TaskPriority.none
                      ? Icons.flag_outlined
                      : Icons.flag_rounded,
                  size: 16,
                  color: switch (p) {
                    TaskPriority.high => AppColors.priorityHigh,
                    TaskPriority.medium => AppColors.priorityMedium,
                    TaskPriority.low => AppColors.priorityLow,
                    TaskPriority.none => AppColors.textMuted,
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  p == TaskPriority.none ? 'None' : p.name,
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
      ],
    ).then((picked) {
      if (picked != null) {
        setState(() => _priority = picked);
      }
    });
  }

  void _showProjectMenu() {
    final box = _projectKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final projects = ref.read(projectsProvider);
    if (projects.isEmpty) return;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx, offset.dy,
        offset.dx + size.width, offset.dy,
      ),
      items: [
        for (int i = 0; i < projects.length; i++)
          PopupMenuItem(
            value: projects[i].id,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _projectIcon(projects[i].name),
                  size: 16,
                  color: AppColors.projectColors[
                      projects[i].colorIndex % AppColors.projectColors.length],
                ),
                const SizedBox(width: 8),
                Text(projects[i].name, style: AppTypography.bodySmall),
              ],
            ),
          ),
      ],
    ).then((picked) {
      if (picked != null) {
        final idx = projects.indexWhere((p) => p.id == picked);
        if (idx >= 0) {
          setState(() => _localProjectIndex = idx);
        }
      }
    });
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

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: DatePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              todayBorder: const BorderSide(color: AppColors.accent, width: 1),
              todayForegroundColor:
                  WidgetStateProperty.all(AppColors.accent),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return AppColors.accent;
                return null;
              }),
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return Colors.white;
                return null;
              }),
              dayShape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              headerHelpStyle: const TextStyle(fontSize: 11),
              headerHeadlineStyle: const TextStyle(fontSize: 22),
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(0.82)),
            child: child!,
          ),
        );
      },
    );
    if (date != null) {
      setState(() => _dueDate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(composerFocusRequestProvider, (prev, _) => _requestFocus());

    final isExpanded = _isExpanded;
    final projects = ref.watch(projectsProvider);
    final currentProjectName = projects.isNotEmpty
        ? projects[_localProjectIndex % projects.length].name
        : 'Inbox';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: AppAnimations.normal,
          curve: AppAnimations.easeOut,
          decoration: BoxDecoration(
            color: isExpanded || _isHovered
                ? AppColors.surface
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isExpanded || _isHovered
                  ? AppColors.border
                  : AppColors.border.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Input row
              SizedBox(
                height: 40,
                child: Row(
                  children: [
                    const SizedBox(width: AppSpacing.md),
                    Icon(
                      Icons.add_rounded,
                      size: 18,
                      color: isExpanded
                          ? AppColors.accent
                          : (_isHovered
                              ? AppColors.accent
                              : AppColors.textMuted),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        controller: _titleController,
                        focusNode: _focusNode,
                        onSubmitted: (_) => _submit(),
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Add a task...',
                          hintStyle: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textMuted,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_hasText)
                      IconButton(
                        onPressed: _submit,
                        icon: Icon(
                          Icons.arrow_upward_rounded,
                          size: 16,
                          color: AppColors.accent,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                      ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                ),
              ),

              // Expandable description + options
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description field
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: TextField(
                          controller: _descriptionController,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Add description...',
                            hintStyle: AppTypography.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 4),
                            isDense: true,
                          ),
                          maxLines: 20,
                          minLines: 1,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // Chips row
                      Row(
                        children: [
                          AppChip(
                            key: _priorityKey,
                            icon: Icons.flag_outlined,
                            label: _priority == TaskPriority.none
                                ? 'Priority'
                                : _priority.name,
                            color: _priority == TaskPriority.high
                                ? AppColors.priorityHigh
                                : _priority == TaskPriority.medium
                                    ? AppColors.priorityMedium
                                    : null,
                            onTap: _showPriorityMenu,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          AppChip(
                            icon: Icons.calendar_today_outlined,
                            label: _dueDate != null
                                ? '${_dueDate!.month}/${_dueDate!.day}'
                                : 'Due date',
                            onTap: _pickDate,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          AppChip(
                            key: _projectKey,
                            icon: Icons.folder_outlined,
                            label: currentProjectName,
                            onTap: _showProjectMenu,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: AppAnimations.normal,
                reverseDuration: AppAnimations.fast,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
