import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/task_tile.dart';
import '../../projects/widgets/slim_sidebar.dart';
import '../../projects/providers/project_provider.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_typography.dart';
import '../../../shared/widgets/sidebar/sticky_composer.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final isCmd = HardwareKeyboard.instance.isMetaPressed;
    if (!isCmd) return false;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.keyN:
        ref.read(composerFocusRequestProvider.notifier).state++;
        return true;
      case LogicalKeyboardKey.keyK:
        ref.read(searchFocusRequestProvider.notifier).state++;
        return true;
      case LogicalKeyboardKey.digit1:
        ref.read(sidebarSelectionProvider.notifier).state =
            const ViewSelection(ViewType.inbox);
        return true;
      case LogicalKeyboardKey.digit2:
        ref.read(sidebarSelectionProvider.notifier).state =
            const ViewSelection(ViewType.today);
        return true;
      case LogicalKeyboardKey.digit3:
        ref.read(sidebarSelectionProvider.notifier).state =
            const ViewSelection(ViewType.completed);
        return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<UndoAction?>(lastUndoActionProvider, (_, action) {
      if (action == null) return;
      final label = switch (action) {
        TaskDeleted() => 'Task deleted',
        TaskToggled() => 'Task completed',
      };
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(label),
          duration: const Duration(seconds: 4),
          backgroundColor: AppColors.elevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppColors.border),
          ),
          action: SnackBarAction(
            label: 'Undo',
            textColor: AppColors.accent,
            onPressed: () async {
              final undo = ref.read(undoStackProvider.notifier).pop();
              if (undo == null) return;
              switch (undo) {
                case TaskDeleted(:final task):
                  await ref.read(tasksProvider.notifier).restoreTask(task);
                case TaskToggled(:final id):
                  ref.read(tasksProvider.notifier).toggleTask(id);
              }
            },
          ),
        ),
      );
    });

    final selection = ref.watch(sidebarSelectionProvider);
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          const SlimSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildHeader(title, completed),
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
                const StickyComposer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title, List<Task> completed) {
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
