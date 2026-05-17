# Plans App — Session Summary

## Goal
Todoist/Linear-style Flutter desktop task manager with premium macOS-native feel.

## Architecture
- **State**: Riverpod providers (`sidebarSelectionProvider`, `filteredTasksProvider`, etc.)
- **DB**: `sqflite_common_ffi` (Dart FFI, no native plugin needed on macOS)
- **Font**: Inter bundled as assets (4 weights), NOT google_fonts
- **Theme**: Dark only (#151618 bg, #1B1D21 surface, #23262B elevated, #7C6DF2 accent)

## Key Decisions
- Inter .ttf bundled locally (google_fonts HTTP download blocked by macOS sandbox)
- SidebarSelection sealed class (ViewSelection + ProjectSelection) replaces old String provider
- StickyComposer (inline "Add a task...") replaces FAB
- All animations: easeOutCubic 200ms, gentle springs
- sqflite_common_ffi uses OpenDatabaseOptions factory (sqflite API changed)

## File Map
```
lib/
  main.dart
  theme/
    app_spacing.dart       — 4px grid, dimensions
    app_animations.dart    — durations, curves, springs
    app_typography.dart    — Inter text styles (plain TextStyle, no GoogleFonts)
    app_theme.dart         — AppColors palette + AppTheme.dark
  shared/
    database/database_service.dart
    widgets/               — hover_surface, app_checkbox, pill_button, priority_dot
    widgets/sidebar/       — sidebar_item, sidebar_section_header, sticky_composer
  features/
    projects/
      providers/project_provider.dart   — SidebarSelection, providers
      widgets/slim_sidebar.dart          — 240px sidebar, smart lists, search, projects
    tasks/
      providers/task_provider.dart       — filteredTasksProvider
      screens/task_list_screen.dart      — header + StickyComposer
      widgets/task_tile.dart             — 48px rows, hover, strikethrough; checkbox grouped with title on same row; description indented 30px to align with title; tasks with description get CrossAxisAlignment.start + 2pt extra top padding; tasks without description get CrossAxisAlignment.center
      widgets/add_task_sheet.dart        — modal sheet
fonts/
  Inter-{Regular,Medium,SemiBold,Bold}.ttf
macos/Runner/
  DebugProfile.entitlements   — has network.client
  Release.entitlements         — has network.client
```

## Status
- **flutter analyze**: 0 issues
- **flutter pub get**: succeeds, google_fonts removed
- **flutter build web --release**: passes
- **flutter build macos --debug**: blocked by local Xcode clang deployment target conflict (not code)

## Note
LSP may show cached errors for `add_task_dialog.dart` and `project_sidebar.dart` — these files no longer exist. `flutter analyze` confirms 0 real issues.

## To Resume
1. `cd plans_app && flutter pub get`
2. `flutter analyze` (should be 0 issues)
3. `flutter build macos --debug` (may fail due to local Xcode env)
4. If building manually in Xcode: open `macos/Runner.xcworkspace`, ensure Runner target has correct deployment target
