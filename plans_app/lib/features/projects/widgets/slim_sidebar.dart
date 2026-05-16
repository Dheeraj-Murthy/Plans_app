import 'package:flutter/material.dart';
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

    final totalTasks = ref.watch(tasksProvider).length;
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
                return SidebarItem(
                  icon: _projectIcon(project.name),
                  label: project.name,
                  isActive: selection is ProjectSelection &&
                      selection.projectId == project.id,
                  activeColor: color,
                  onTap: () => ref
                      .read(sidebarSelectionProvider.notifier)
                      .state = ProjectSelection(project.id),
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

class _SidebarSearch extends StatelessWidget {
  const _SidebarSearch();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sidebarPadding,
        vertical: AppSpacing.sm,
      ),
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.search_rounded,
              size: 15,
              color: AppColors.textMuted,
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Search tasks...',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddProjectButton extends StatelessWidget {
  const _AddProjectButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            color: AppColors.textMuted,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Add Project',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
