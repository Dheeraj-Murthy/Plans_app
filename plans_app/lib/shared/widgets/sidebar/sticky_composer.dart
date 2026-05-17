import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_animations.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../features/tasks/models/task.dart';
import '../../../features/tasks/providers/task_provider.dart';
import '../../../features/projects/providers/project_provider.dart';
import '../app_chip.dart';
import '../../helpers/task_helpers.dart';

class StickyComposer extends ConsumerStatefulWidget {
  const StickyComposer({super.key});

  @override
  ConsumerState<StickyComposer> createState() => _StickyComposerState();
}

class _StickyComposerState extends ConsumerState<StickyComposer> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  late final FocusNode _focusNode;
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
    _focusNode = FocusNode(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          _collapse();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
    );
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

  void _collapse() {
    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _priority = TaskPriority.none;
      _dueDate = null;
      _isExpanded = false;
    });
    _focusNode.unfocus();
  }

  void _showPriorityMenu() async {
    final picked = await showPriorityMenu(context, _priorityKey);
    if (picked != null) setState(() => _priority = picked);
  }

  void _showProjectMenu() async {
    final projects = ref.read(projectsProvider);
    if (projects.isEmpty) return;
    final picked = await showProjectMenu(context, _projectKey, ref);
    if (picked != null) {
      final idx = projects.indexWhere((p) => p.id == picked);
      if (idx >= 0) setState(() => _localProjectIndex = idx);
    }
  }

  Future<void> _pickDate() async {
    final date = await pickDate(context, _dueDate);
    if (date != null) setState(() => _dueDate = date);
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
                      color: _priority != TaskPriority.none
                          ? switch (_priority) {
                              TaskPriority.high => AppColors.priorityHigh,
                              TaskPriority.medium => AppColors.priorityMedium,
                              TaskPriority.low => AppColors.priorityLow,
                              TaskPriority.none => AppColors.textMuted,
                            }
                          : isExpanded || _isHovered
                              ? AppColors.accent
                              : AppColors.textMuted,
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
                      const SizedBox(height: AppSpacing.md),
                      const Divider(
                        color: AppColors.border,
                        height: 1,
                        thickness: 1,
                      ),
                      const SizedBox(height: AppSpacing.md),
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
