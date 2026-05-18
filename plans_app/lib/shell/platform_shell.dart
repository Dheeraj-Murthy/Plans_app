import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/tasks/screens/task_list_screen.dart';
import '../features/tasks/widgets/add_task_sheet.dart';
import '../features/projects/widgets/slim_sidebar.dart';
import '../features/projects/providers/project_provider.dart';
import '../features/tasks/providers/task_provider.dart';
import '../shared/widgets/sidebar/sidebar_item.dart';
import '../shared/widgets/sidebar/sidebar_section_header.dart';
import '../shared/widgets/sidebar/add_project_button.dart';
import '../shared/helpers/task_helpers.dart';
import '../shared/notifications/notification_service.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

class PlatformAdaptiveShell extends ConsumerStatefulWidget {
  const PlatformAdaptiveShell({super.key});

  @override
  ConsumerState<PlatformAdaptiveShell> createState() =>
      _PlatformAdaptiveShellState();
}

class _PlatformAdaptiveShellState
    extends ConsumerState<PlatformAdaptiveShell> {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb && Platform.isMacOS) {
      HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    }
  }

  @override
  void dispose() {
    if (!kIsWeb && Platform.isMacOS) {
      HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    }
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (!HardwareKeyboard.instance.isMetaPressed) return false;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.keyN:
        ref.read(composerFocusRequestProvider.notifier).request();
        return true;
      case LogicalKeyboardKey.keyK:
        ref.read(searchFocusRequestProvider.notifier).request();
        return true;
      case LogicalKeyboardKey.digit1:
        ref
            .read(sidebarSelectionProvider.notifier)
            .select(const ViewSelection(ViewType.inbox));
        return true;
      case LogicalKeyboardKey.digit2:
        ref
            .read(sidebarSelectionProvider.notifier)
            .select(const ViewSelection(ViewType.today));
        return true;
      case LogicalKeyboardKey.digit3:
        ref
            .read(sidebarSelectionProvider.notifier)
            .select(const ViewSelection(ViewType.completed));
        return true;
      case LogicalKeyboardKey.keyZ:
        final action = ref.read(undoStackProvider.notifier).pop();
        if (action != null) {
          switch (action) {
            case TaskDeleted(:final task):
              ref.read(tasksProvider.notifier).restoreTask(task);
            case TaskToggled(:final id):
              ref.read(tasksProvider.notifier).toggleTask(id);
          }
        }
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
          action: SnackBarAction(
            label: 'Undo',
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

    if (!kIsWeb && Platform.isMacOS) {
      return _DesktopShell();
    }
    return _MobileShell();
  }
}

class _DesktopShell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          SlimSidebar(),
          Expanded(child: TaskListScreen()),
        ],
      ),
    );
  }
}

class _MobileShell extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SidebarSelection selection = ref.watch(sidebarSelectionProvider);
    final projects = ref.watch(projectsProvider);
    final completed =
        ref.watch(filteredTasksProvider).where((t) => t.isCompleted).toList();

    final title = switch (selection) {
      ViewSelection(:final view) => switch (view) {
          ViewType.inbox => 'Inbox',
          ViewType.today => 'Today',
          ViewType.completed => 'Completed',
        },
      ProjectSelection(:final projectId) =>
        projects.where((p) => p.id == projectId).firstOrNull?.name ?? 'Tasks',
    };

    final navIndex = switch (selection) {
      ViewSelection(view: ViewType.inbox) => 0,
      ViewSelection(view: ViewType.today) => 1,
      ViewSelection(view: ViewType.completed) => 2,
      _ => 0,
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(title, style: AppTypography.headingMedium),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(
              Icons.menu_rounded,
              color: AppColors.textSecondary,
            ),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          // TODO: remove test button
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined,
                color: AppColors.accent),
            tooltip: 'Test notification',
            onPressed: () => NotificationService.showTestNotification(),
          ),
          if (completed.isNotEmpty)
            TextButton(
              onPressed: () =>
                  ref.read(tasksProvider.notifier).clearCompleted(),
              child: Text(
                'Clear',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
        ],
      ),
      drawer: _MobileDrawer(),
      body: const TaskListScreen(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const AddTaskSheet(),
        ),
        child: const Icon(Icons.add_rounded),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navIndex,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: AppTypography.caption,
        unselectedLabelStyle: AppTypography.caption,
        onTap: (index) {
          switch (index) {
            case 0:
              ref
                  .read(sidebarSelectionProvider.notifier)
                  .select(const ViewSelection(ViewType.inbox));
            case 1:
              ref
                  .read(sidebarSelectionProvider.notifier)
                  .select(const ViewSelection(ViewType.today));
            case 2:
              ref
                  .read(sidebarSelectionProvider.notifier)
                  .select(const ViewSelection(ViewType.completed));
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inbox_rounded),
            label: 'Inbox',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_rounded),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline_rounded),
            label: 'Done',
          ),
        ],
      ),
    );
  }
}

class _MobileDrawer extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider);
    final SidebarSelection selection = ref.watch(sidebarSelectionProvider);
    final totalTasks =
        ref.watch(tasksProvider).where((t) => !t.isCompleted).length;
    final todayCount = ref.watch(todayCountProvider);
    final completedCount = ref.watch(completedCountProvider);

    void close() => Navigator.of(context).pop();

    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Text(
                'Plans',
                style: AppTypography.headingLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            SidebarItem(
              icon: Icons.inbox_rounded,
              label: 'Inbox',
              count: totalTasks,
              isActive: selection is ViewSelection &&
                  selection.view == ViewType.inbox,
              onTap: () {
                ref
                    .read(sidebarSelectionProvider.notifier)
                    .select(const ViewSelection(ViewType.inbox));
                close();
              },
            ),
            SidebarItem(
              icon: Icons.calendar_today_rounded,
              label: 'Today',
              count: todayCount,
              isActive: selection is ViewSelection &&
                  selection.view == ViewType.today,
              onTap: () {
                ref
                    .read(sidebarSelectionProvider.notifier)
                    .select(const ViewSelection(ViewType.today));
                close();
              },
            ),
            SidebarItem(
              icon: Icons.check_circle_outline_rounded,
              label: 'Completed',
              count: completedCount,
              isActive: selection is ViewSelection &&
                  selection.view == ViewType.completed,
              onTap: () {
                ref
                    .read(sidebarSelectionProvider.notifier)
                    .select(const ViewSelection(ViewType.completed));
                close();
              },
            ),
            const SidebarSectionHeader(label: 'Projects'),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  final project = projects[index];
                  final count =
                      ref.watch(projectTaskCountProvider(project.id));
                  return SidebarItem(
                    icon: projectIcon(project.name),
                    label: project.name,
                    projectId: project.id,
                    colorIndex: project.colorIndex,
                    count: count > 0 ? count : null,
                    isActive: selection is ProjectSelection &&
                        selection.projectId == project.id,
                    onTap: () {
                      ref
                          .read(sidebarSelectionProvider.notifier)
                          .select(ProjectSelection(project.id));
                      close();
                    },
                  );
                },
              ),
            ),
            const AddProjectButton(),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
