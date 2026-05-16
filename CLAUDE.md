# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Todoist/Linear-style Flutter task manager targeting macOS (primary) with offline-first architecture. Currently in Phase 2 (local persistence with `sqflite_common_ffi`). Rust backend integration planned for Phase 3+.

All Flutter code lives in `plans_app/`. Run all Flutter commands from that directory.

## Commands

```bash
cd plans_app

flutter pub get           # install deps
flutter analyze           # lint (must stay at 0 issues)
flutter test              # run tests
flutter test test/widget_test.dart   # single test file

flutter run -d macos      # run on macOS
flutter build macos --debug
flutter build web --release
```

## Architecture

```
lib/
  main.dart                     — init sqflite FFI, inject DatabaseService, wrap in ProviderScope
  routing/app_router.dart       — GoRouter (currently single route: / → TaskListScreen)
  theme/                        — AppColors, AppTheme.dark, AppTypography, AppSpacing, AppAnimations
  shared/
    database/database_service.dart   — sqflite_common_ffi wrapper; Provider must be overridden at root
    widgets/                         — reusable: HoverSurface, AppCheckbox, PillButton, PriorityDot
    widgets/sidebar/                 — SidebarItem, SidebarSectionHeader, StickyComposer
  features/
    projects/
      models/project.dart
      providers/project_provider.dart   — SidebarSelection sealed class, projectsProvider, sidebarSelectionProvider
      widgets/slim_sidebar.dart          — 240px sidebar
    tasks/
      models/task.dart
      providers/task_provider.dart       — tasksProvider (StateNotifier), filteredTasksProvider (derived)
      screens/task_list_screen.dart
      widgets/task_tile.dart, add_task_sheet.dart
fonts/                                   — Inter TTF (4 weights) bundled as assets
```

**State flow**: `sidebarSelectionProvider` (sidebar selection) + `tasksProvider` (all tasks) → `filteredTasksProvider` (derived, drives task list).

**`SidebarSelection`** is a sealed class: `ViewSelection(ViewType)` or `ProjectSelection(projectId)`. Pattern-match it everywhere, not string comparisons.

**`DatabaseService`** is instantiated once in `main()` and injected via `databaseServiceProvider.overrideWithValue(db)`. Never call `ref.read(databaseServiceProvider)` in providers that run before the override is set.

## Key Constraints

- **Font**: Inter `.ttf` bundled locally in `fonts/`. Do NOT use `google_fonts` — macOS sandbox blocks HTTP font downloads.
- **SQLite**: Use `sqflite_common_ffi` + `databaseFactoryFfi` + `OpenDatabaseOptions` (not the deprecated `openDatabase` signature).
- **Theme**: Dark only. Palette — bg `#151618`, surface `#1B1D21`, elevated `#23262B`, accent `#7C6DF2`.
- **Animations**: `easeOutCubic`, 200ms standard duration, gentle springs.
- **IDs**: UUIDs everywhere (package `uuid`). Never auto-increment.
- **Offline-first**: All mutations go to local SQLite first; no network calls exist yet.

## Planned Architecture (future phases)

Per `todo_app_full_srs_flutter_rust.md`:
- Phase 3: move DB + business logic to Rust via `flutter_rust_bridge`
- Phase 4: sync engine (last-write-wins initially, then CRDT)
- Phase 5: Axum/PostgreSQL backend
- Soft deletes (`is_deleted`) and change log table will be required when sync lands

## Known Issues

- `flutter build macos --debug` may fail due to local Xcode deployment target conflict (not a code issue).
- LSP may show stale errors for `add_task_dialog.dart` / `project_sidebar.dart` — these files were deleted. `flutter analyze` is authoritative.
