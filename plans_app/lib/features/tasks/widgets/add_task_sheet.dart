import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../../projects/providers/project_provider.dart';
import '../../../theme/app_animations.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_typography.dart';

class AddTaskSheet extends ConsumerStatefulWidget {
  const AddTaskSheet({super.key});

  @override
  ConsumerState<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<AddTaskSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _dueDate;
  TaskPriority _priority = TaskPriority.none;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final currentProjectId = projects.isNotEmpty
        ? projects[_localProjectIndex % projects.length].id
        : 'default';

    return Padding(
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
          TextField(
            controller: _titleController,
            autofocus: true,
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
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
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
              contentPadding: EdgeInsets.zero,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(
            color: AppColors.border,
            height: 1,
            thickness: 1,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _ActionChip(
                icon: Icons.flag_outlined,
                label: _priority == TaskPriority.none
                    ? 'Priority'
                    : _priority.name,
                color: _priority == TaskPriority.high
                    ? AppColors.priorityHigh
                    : _priority == TaskPriority.medium
                        ? AppColors.priorityMedium
                        : null,
                onTap: _cyclePriority,
              ),
              const SizedBox(width: AppSpacing.sm),
              _ActionChip(
                icon: Icons.calendar_today_outlined,
                label: _dueDate != null
                    ? '${_dueDate!.month}/${_dueDate!.day}'
                    : 'Due date',
                onTap: _pickDate,
              ),
              const SizedBox(width: AppSpacing.sm),
              _ActionChip(
                icon: Icons.folder_outlined,
                label: projects
                    .firstWhere((p) => p.id == currentProjectId)
                    .name,
                onTap: _cycleProject,
              ),
              const Spacer(),
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
        ],
      ),
    );
  }

  void _cyclePriority() {
    final values = TaskPriority.values;
    final currentIndex = values.indexOf(_priority);
    setState(() => _priority = values[(currentIndex + 1) % values.length]);
  }

  int _localProjectIndex = 0;

  void _cycleProject() {
    final projects = ref.read(projectsProvider);
    if (projects.isEmpty) return;
    _localProjectIndex = (_localProjectIndex + 1) % projects.length;
    setState(() {});
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
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(0),
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

    ref.read(tasksProvider.notifier).addTask(
          title: title,
          description: desc.isNotEmpty ? desc : null,
          dueDate: _dueDate,
          priority: _priority,
          projectId: projectId,
        );

    Navigator.of(context).pop();
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: color ?? AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: color ?? AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
