# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Todoist/Linear-style Flutter task manager targeting macOS (primary) with offline-first architecture. Phase 3 — database/business logic in Rust via `flutter_rust_bridge` v2.12.0 (`rusqlite`, `serde`, `uuid`, `chrono`).

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
  main.dart                     — init RustLib, initDatabase (Rust), inject DatabaseService, wrap in ProviderScope
  routing/app_router.dart       — GoRouter (currently single route: / → TaskListScreen)
  theme/                        — AppColors, AppTheme.dark, AppTypography, AppSpacing, AppAnimations
  shared/
    database/database_service.dart   — Rust FFI wrapper (calls rust_tasks/rust_projects top-level functions)
    helpers/task_helpers.dart        — shared projectIcon(), showPriorityMenu(), showProjectMenu(), pickDate()
    widgets/                         — reusable: HoverSurface, AppCheckbox, AppChip, PriorityDot
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
src/
  rust/                              — auto-generated flutter_rust_bridge Dart bindings
rust/                                — Rust crate (plans_core): api/, db.rs, models.rs, Cargo.toml
```

**State flow**: `sidebarSelectionProvider` (sidebar selection) + `tasksProvider` (all tasks) → `filteredTasksProvider` (derived, drives task list).

**`SidebarSelection`** is a sealed class: `ViewSelection(ViewType)` or `ProjectSelection(projectId)`. Pattern-match it everywhere, not string comparisons. `ViewType` values: `inbox`, `today`, `completed`.

**`DatabaseService`** is instantiated once in `main()` and injected via `databaseServiceProvider.overrideWithValue(db)`. Never call `ref.read(databaseServiceProvider)` in providers that run before the override is set. For tests, use `FakeDatabaseService` from `test/shared/fake_database_service.dart`.

**Default projects** are seeded by Rust on DB creation (`db.rs`) with hardcoded IDs: `'default'` (Inbox), `'work'`, `'personal'`, `'ideas'`. `Task.projectId` defaults to `'default'`.

## Key Constraints

- **Font**: Inter `.ttf` bundled locally in `fonts/`. Do NOT use `google_fonts` — macOS sandbox blocks HTTP font downloads.
- **Rust crate**: `plans_app/rust/` — build with `rust/build_macos.sh` (produces `plans_core.framework`). Xcode build phase copies framework into app bundle. Loaded at runtime via `@rpath/plans_core.framework/plans_core`.
- **macOS launch**: `./run_macos.sh` builds Rust then `flutter run -d macos`.
- **Theme**: Dark only. Palette — bg `#151618`, surface `#1B1D21`, elevated `#23262B`, accent `#7C6DF2`.
- **Animations**: `easeOutCubic`, 200ms standard duration, gentle springs.
- **IDs**: UUIDs in Rust (`uuid` crate). Never auto-increment.
- **Offline-first**: All mutations go to local SQLite via Rust; no network calls yet.
- **Tests**: Use `FakeDatabaseService` from `test/shared/fake_database_service.dart` (synchronous in-memory fake extending DatabaseService; overrides all methods).

## Planned Architecture (future phases)

- Phase 4: sync engine (last-write-wins initially, then CRDT)
- Phase 5: Axum/PostgreSQL backend
- Soft deletes (`is_deleted`) and change log table already in Rust schema for sync

## Known Issues

- `flutter build macos --debug` may fail due to local Xcode deployment target conflict (not a code issue).
- LSP may show stale errors for `add_task_dialog.dart` / `project_sidebar.dart` — these files were deleted. `flutter analyze` is authoritative.
