import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../../../theme/app_animations.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_typography.dart';
import '../../../shared/widgets/app_checkbox.dart';
import '../../../shared/widgets/priority_dot.dart';

class TaskTile extends ConsumerStatefulWidget {
  final Task task;

  const TaskTile({super.key, required this.task});

  @override
  ConsumerState<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends ConsumerState<TaskTile> {
  bool _isHovered = false;

  String _formatDueDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(date.year, date.month, date.day);
    final diff = due.difference(today).inDays;

    return switch (diff) {
      0 => 'Today',
      1 => 'Tomorrow',
      -1 => 'Yesterday',
      _ => '${date.month}/${date.day}',
    };
  }

  bool get _isOverdue {
    final due = widget.task.dueDate;
    if (due == null) return false;
    if (widget.task.isCompleted) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(due.year, due.month, due.day);
    return dueDate.isBefore(today);
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppAnimations.normal,
        curve: AppAnimations.easeOut,
        height: AppSpacing.taskTileHeight,
        decoration: BoxDecoration(
          color: _isHovered ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            // Priority bar
            AnimatedContainer(
              duration: AppAnimations.normal,
              curve: AppAnimations.easeOut,
              width: 3,
              height: task.isCompleted ? 0 : 20,
              decoration: BoxDecoration(
                color: switch (task.priority) {
                  TaskPriority.high => AppColors.priorityHigh,
                  TaskPriority.medium => AppColors.priorityMedium,
                  TaskPriority.low => AppColors.priorityLow,
                  TaskPriority.none => Colors.transparent,
                },
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Checkbox
            AppCheckbox(
              value: task.isCompleted,
              onChanged: (_) {
                ref.read(tasksProvider.notifier).toggleTask(task.id);
              },
            ),
            const SizedBox(width: AppSpacing.md),

            // Title
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: AppAnimations.medium,
                curve: AppAnimations.easeOut,
                style: AppTypography.bodyMedium.copyWith(
                  color: task.isCompleted
                      ? AppColors.textMuted
                      : AppColors.textPrimary,
                ),
                child: task.isCompleted
                    ? _StrikethroughText(
                        text: task.title,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textMuted,
                        ),
                      )
                    : Text(task.title),
              ),
            ),

            // Metadata row
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Priority dot
                if (task.priority != TaskPriority.none && !task.isCompleted)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: PriorityDot(priority: task.priority),
                  ),

                // Due date pill
                if (task.dueDate != null && !task.isCompleted)
                  AnimatedOpacity(
                    duration: AppAnimations.fast,
                    opacity: _isHovered ? 0 : 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _isOverdue
                            ? AppColors.danger.withValues(alpha: 0.12)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatDueDate(task.dueDate),
                        style: AppTypography.label.copyWith(
                          fontSize: 11,
                          color: _isOverdue
                              ? AppColors.danger
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),

                // Hover actions
                AnimatedOpacity(
                  duration: AppAnimations.fast,
                  opacity: _isHovered ? 1 : 0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _HoverActionIcon(icon: Icons.flag_outlined),
                      const SizedBox(width: 2),
                      _HoverActionIcon(icon: Icons.more_horiz_rounded),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(width: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

class _StrikethroughText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const _StrikethroughText({required this.text, required this.style});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppAnimations.medium,
      curve: AppAnimations.easeOut,
      builder: (context, value, child) {
        return Stack(
          children: [
            Text(text, style: style),
            Positioned(
              bottom: style.fontSize! * 0.4,
              left: 0,
              right: 0,
              child: FractionallySizedBox(
                widthFactor: value,
                child: Container(
                  height: 1,
                  color: AppColors.textMuted.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HoverActionIcon extends StatefulWidget {
  final IconData icon;

  const _HoverActionIcon({required this.icon});

  @override
  State<_HoverActionIcon> createState() => _HoverActionIconState();
}

class _HoverActionIconState extends State<_HoverActionIcon> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
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
          color: _isHovered
              ? AppColors.textSecondary
              : AppColors.textMuted,
        ),
      ),
    );
  }
}
