import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/tasks/models/task.dart';
import '../../features/projects/providers/project_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';

IconData projectIcon(String name) {
  return switch (name.toLowerCase()) {
    'work' => Icons.work_outline_rounded,
    'personal' => Icons.person_outline_rounded,
    'ideas' => Icons.lightbulb_outline_rounded,
    'inbox' => Icons.inbox_rounded,
    _ => Icons.folder_outlined,
  };
}

Future<TaskPriority?> showPriorityMenu(
    BuildContext context, GlobalKey anchorKey) async {
  final box = anchorKey.currentContext?.findRenderObject() as RenderBox?;
  if (box == null) return null;
  final offset = box.localToGlobal(Offset.zero);
  final size = box.size;
  return showMenu<TaskPriority>(
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
  );
}

Future<String?> showProjectMenu(
    BuildContext context, GlobalKey anchorKey, WidgetRef ref) async {
  final box = anchorKey.currentContext?.findRenderObject() as RenderBox?;
  if (box == null) return null;
  final projects = ref.read(projectsProvider);
  if (projects.isEmpty) return null;
  final offset = box.localToGlobal(Offset.zero);
  final size = box.size;
  return showMenu<String>(
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
                projectIcon(projects[i].name),
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
  );
}

Future<DateTime?> pickDate(BuildContext context, DateTime? currentDate) async {
  final date = await showDatePicker(
    context: context,
    initialDate: currentDate ?? DateTime.now(),
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
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(0.82)),
          child: child!,
        ),
      );
    },
  );
  return date;
}
