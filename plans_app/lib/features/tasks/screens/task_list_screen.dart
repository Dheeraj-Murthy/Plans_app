import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/task_tile.dart';
import '../../projects/providers/project_provider.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_animations.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_typography.dart';
import '../../../shared/widgets/sidebar/sticky_composer.dart';

class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = switch (ref.watch(sidebarSelectionProvider)) {
      ViewSelection(:final view) => switch (view) {
          ViewType.inbox => 'Inbox',
          ViewType.today => 'Today',
          ViewType.completed => 'Completed',
        },
      ProjectSelection(:final projectId) =>
        ref.watch(projectsProvider).where((p) => p.id == projectId).firstOrNull?.name ?? 'Tasks',
    };

    final isDesktop = !kIsWeb && Platform.isMacOS;

    return Column(
      children: [
        if (isDesktop)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.sm,
            ),
            child: Text(title, style: AppTypography.headingLarge),
          ),
        const Expanded(child: _TaskListBody()),
        if (isDesktop) const StickyComposer(),
      ],
    );
  }
}

class _TaskListBody extends ConsumerWidget {
  const _TaskListBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtered = ref.watch(filteredTasksProvider);
    final completingIds = ref.watch(completingTaskIdsProvider);
    final uncompletingIds = ref.watch(uncompletingTaskIdsProvider);

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 48,
              color: AppColors.textMuted.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No tasks yet',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    final incomplete = <Task>[];
    final completed = <Task>[];
    for (final t in filtered) {
      if (completingIds.contains(t.id)) {
        incomplete.add(t);
      } else if (uncompletingIds.contains(t.id)) {
        completed.add(t);
      } else if (t.isCompleted) {
        completed.add(t);
      } else {
        incomplete.add(t);
      }
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppSpacing.maxContentWidth,
        ),
        child: ListView(
          padding: const EdgeInsets.only(top: 8),
          children: [
            if (incomplete.isNotEmpty)
              ReorderableListView.builder(
                shrinkWrap: true,
                buildDefaultDragHandles: false,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: incomplete.length,
                onReorder: (oldIndex, newIndex) {
                  ref
                      .read(tasksProvider.notifier)
                      .reorderTask(oldIndex, newIndex);
                },
                itemBuilder: (context, index) {
                  final task = incomplete[index];
                  final isCompleting = completingIds.contains(task.id);
                  return _ExitAnimation(
                    key: ValueKey(task.id),
                    isCompleting: isCompleting,
                    child: TaskTile(
                      task: task,
                      index: index,
                    ),
                  );
                },
              ),
            if (completed.isNotEmpty && incomplete.isNotEmpty)
              _SectionDivider(count: completed.length),
            ...completed.asMap().entries.map(
              (e) => TaskTile(
                key: ValueKey('completed-${e.value.id}'),
                task: e.value,
                index: incomplete.length + e.key,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExitAnimation extends StatefulWidget {
  final bool isCompleting;
  final Widget child;

  const _ExitAnimation({
    required this.isCompleting,
    required this.child,
    super.key,
  });

  @override
  State<_ExitAnimation> createState() => _ExitAnimationState();
}

class _ExitAnimationState extends State<_ExitAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.medium,
    );
    if (widget.isCompleting) _scheduleExit();
  }

  @override
  void didUpdateWidget(_ExitAnimation old) {
    super.didUpdateWidget(old);
    if (!old.isCompleting && widget.isCompleting) _scheduleExit();
  }

  void _scheduleExit() {
    Future.delayed(const Duration(milliseconds: 4700), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final v = _controller.value;
        if (v == 0) return child!;
        return Opacity(
          opacity: 1 - v,
          child: Transform.scale(
            scale: 1 - 0.15 * v,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _SectionDivider extends StatelessWidget {
  final int count;

  const _SectionDivider({required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Text(
            'Completed — $count',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Divider(
              color: AppColors.border,
              thickness: 0.5,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
