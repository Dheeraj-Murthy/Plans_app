import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/task_tile.dart';
import '../../projects/providers/project_provider.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_typography.dart';
import '../../../shared/widgets/sidebar/sticky_composer.dart';

class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SidebarSelection selection = ref.watch(sidebarSelectionProvider);
    final projects = ref.watch(projectsProvider);
    final filtered = ref.watch(filteredTasksProvider);

    final title = switch (selection) {
      ViewSelection(:final view) => switch (view) {
          ViewType.inbox => 'Inbox',
          ViewType.today => 'Today',
          ViewType.completed => 'Completed',
        },
      ProjectSelection(:final projectId) =>
        projects.where((p) => p.id == projectId).firstOrNull?.name ?? 'Tasks',
    };

    final incomplete = <Task>[];
    final completed = <Task>[];
    for (final t in filtered) {
      if (t.isCompleted) {
        completed.add(t);
      } else {
        incomplete.add(t);
      }
    }

    final isDesktop = !kIsWeb && Platform.isMacOS;

    return Column(
      children: [
        if (isDesktop) _buildHeader(ref, title, completed),
        Expanded(
          child: filtered.isEmpty
              ? Center(
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
                )
              : Center(
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
                              return TaskTile(
                                key: ValueKey(incomplete[index].id),
                                task: incomplete[index],
                                index: index,
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
                ),
        ),
        if (isDesktop) const StickyComposer(),
      ],
    );
  }

  Widget _buildHeader(WidgetRef ref, String title, List<Task> completed) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        0,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.headingMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (completed.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    ref.read(tasksProvider.notifier).clearCompleted();
                  },
                  child: Text(
                    'Clear completed',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
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
