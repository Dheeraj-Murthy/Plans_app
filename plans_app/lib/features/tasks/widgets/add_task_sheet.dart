import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../../projects/providers/project_provider.dart';
import '../../../theme/app_animations.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_typography.dart';
import '../../../shared/widgets/app_chip.dart';

class AddTaskSheet extends ConsumerStatefulWidget {
  final Task? existingTask;

  const AddTaskSheet({super.key, this.existingTask});

  @override
  ConsumerState<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<AddTaskSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late DateTime? _dueDate;
  late TaskPriority _priority;
  late int _localProjectIndex;
  final _priorityKey = GlobalKey();
  final _projectKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final task = widget.existingTask;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController =
        TextEditingController(text: task?.description ?? '');
    _dueDate = task?.dueDate;
    _priority = task?.priority ?? TaskPriority.none;

    if (task != null) {
      final projects = ref.read(projectsProvider);
      _localProjectIndex =
          projects.indexWhere((p) => p.id == task.projectId);
      if (_localProjectIndex < 0) _localProjectIndex = 0;
    } else {
      _localProjectIndex = 0;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.existingTask != null;

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final currentProjectId = projects.isNotEmpty
        ? projects[_localProjectIndex % projects.length].id
        : 'default';

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl + bottomInset,
        ),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.radio_button_unchecked_rounded,
                size: 20,
                color: switch (_priority) {
                  TaskPriority.high => AppColors.priorityHigh,
                  TaskPriority.medium => AppColors.priorityMedium,
                  TaskPriority.low => AppColors.priorityLow,
                  TaskPriority.none => AppColors.textMuted,
                }.withValues(alpha: 0.4),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: _titleController,
                  autofocus: !_isEditing,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'What needs to be done?',
                    hintStyle: AppTypography.bodyLarge.copyWith(
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
            ],
          ),
          const SizedBox(height: AppSpacing.md),
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
                label: projects
                    .firstWhere((p) => p.id == currentProjectId)
                    .name,
                onTap: _showProjectMenu,
              ),
              const Spacer(),
              if (_isEditing)
                GestureDetector(
                  onTap: () {
                    ref
                        .read(tasksProvider.notifier)
                        .deleteTask(widget.existingTask!.id);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              if (_isEditing) const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: _submit,
                child: AnimatedContainer(
                  duration: AppAnimations.fast,
                  curve: AppAnimations.easeOut,
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_upward_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.short_text_rounded,
                size: 20,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
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
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  maxLines: null,
                  minLines: 3,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  }

  void _showPriorityMenu() {
    final box = _priorityKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;
    showMenu<TaskPriority>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx , offset.dy,
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
      if (picked != null) setState(() => _priority = picked);
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
        if (idx >= 0) setState(() => _localProjectIndex = idx);
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

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    final desc = _descriptionController.text.trim();

    final projects = ref.read(projectsProvider);
    final projectId = projects.isNotEmpty
        ? projects[_localProjectIndex % projects.length].id
        : 'default';

    final notifier = ref.read(tasksProvider.notifier);

    if (_isEditing) {
      notifier.updateTask(
        widget.existingTask!.id,
        widget.existingTask!.copyWith(
          title: title,
          description: desc.isNotEmpty ? desc : null,
          dueDate: _dueDate,
          priority: _priority,
          projectId: projectId,
        ),
      );
    } else {
      notifier.addTask(
        title: title,
        description: desc.isNotEmpty ? desc : null,
        dueDate: _dueDate,
        priority: _priority,
        projectId: projectId,
      );
    }

    Navigator.of(context).pop();
  }
}
