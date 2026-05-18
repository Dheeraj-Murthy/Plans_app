# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Todoist/Linear-style Flutter task manager targeting macOS (primary) with offline-first architecture. Phase 3 — database/business logic in Rust via `flutter_rust_bridge` v2.12.0 (`rusqlite`, `serde`, `uuid`, `chrono`).

All Flutter commands run from `plans_app/`.

## Commands

**After fresh clone**: run FRB codegen first, then `flutter pub get`:
```bash
cd plans_app
flutter_rust_bridge_codegen generate   # regenerates lib/src/rust/ and rust/src/frb_generated.rs
```

```bash
cd plans_app

flutter pub get           # install deps
flutter analyze           # lint (must stay at 0 issues)
flutter test              # run tests
flutter test test/widget_test.dart   # single test file

flutter run -d macos      # run on macOS
flutter build macos --debug
flutter build web --release

./run_macos.sh            # builds Rust framework then flutter run -d macos
```

**Rust rebuild**: `bash rust/build_macos.sh` (produces `rust/target/release/plans_core.framework`). Run before `flutter run` if Rust code changed.

**Rust quick check**: `cargo check --manifest-path rust/Cargo.toml` — fast compile-only validation without rebuilding the framework.

**FRB codegen**: run `flutter_rust_bridge` codegen when any type in `rust/src/api/` changes. Config at `flutter_rust_bridge.yaml`. Output lands in `lib/src/rust/` (auto-generated — do not hand-edit).

## Architecture

```
lib/
  main.dart                     — init RustLib, initDatabase (Rust), NotificationService.init(), inject DatabaseService, wrap in ProviderScope
  routing/app_router.dart       — GoRouter (single route: / → TaskListScreen)
  theme/                        — AppColors, AppTheme.dark, AppTypography, AppSpacing, AppAnimations
  shared/
    database/database_service.dart   — Rust FFI wrapper (calls rust_tasks/rust_projects top-level functions)
    helpers/task_helpers.dart        — shared projectIcon(), showPriorityMenu(), showProjectMenu(), pickDate()
    notifications/notification_service.dart  — static singleton; schedules/cancels macOS notifications per task
    widgets/                         — HoverSurface, AppCheckbox, AppChip, PriorityDot, HoverActionIcon
    widgets/sidebar/                 — SidebarItem, SidebarSectionHeader, StickyComposer, SidebarSearch, AddProjectButton
  features/
    projects/
      models/project.dart
      providers/project_provider.dart   — SidebarSelection sealed class, projectsProvider, sidebarSelectionProvider
      widgets/slim_sidebar.dart          — 240px sidebar
    tasks/
      models/task.dart                   — Task, TaskPriority enum; copyWith uses _absent sentinel for nullable fields
      providers/task_provider.dart       — tasksProvider (StateNotifier), filteredTasksProvider, undo stack, search/count providers
      screens/task_list_screen.dart
      widgets/task_tile.dart, add_task_sheet.dart
fonts/                                   — Inter TTF (4 weights) bundled as assets
lib/src/rust/                            — auto-generated flutter_rust_bridge Dart bindings (api/, models.dart, frb_generated.dart)
rust/                                    — Rust crate (plans_core): api/tasks.rs, api/projects.rs, db.rs, models.rs
```

## State / Providers

**State flow**: `sidebarSelectionProvider` + `tasksProvider` + `searchQueryProvider` → `filteredTasksProvider` (derived, drives task list).

**`SidebarSelection`** is a sealed class: `ViewSelection(ViewType)` or `ProjectSelection(projectId)`. Pattern-match everywhere, never string-compare. `ViewType` values: `inbox`, `today`, `completed`.

**`DatabaseService`** instantiated once in `main()`, injected via `databaseServiceProvider.overrideWithValue(db)`. Never call `ref.read(databaseServiceProvider)` in providers that run before the override is set.

**Count providers** (all derived from `tasksProvider`): `todayCountProvider`, `completedCountProvider`, `projectTaskCountsProvider` (Map), `projectTaskCountProvider` (family by projectId).

**Undo system**: `UndoStackNotifier` / `undoStackProvider` holds `List<UndoAction>`. Sealed class: `TaskDeleted(task)` | `TaskToggled(id, wasCompleted)`. `lastUndoActionProvider` is a `StateProvider<UndoAction?>` for snackbar display.

**Focus/search providers**: `searchQueryProvider` (String), `composerFocusRequestProvider` (int counter), `searchFocusRequestProvider` (int counter) — increment to request focus imperatively.

**Reorder**: `TasksNotifier.reorderTask(oldIndex, newIndex)` updates state and calls `db.reorderTasks(List<String> ids)` to persist sort order.

**`NotificationService`** (static): initialized in `main()`. `scheduleForTask` schedules a due-time notification and an optional reminder. Called on every task create/update/toggle/restore. Permission is requested natively (AppDelegate.swift); `NotificationService.init()` only activates if permission granted.

## Key Constraints

- **Font**: Inter `.ttf` bundled locally in `fonts/`. Do NOT use `google_fonts` — macOS sandbox blocks HTTP font downloads.
- **Rust crate**: `plans_app/rust/` — build with `rust/build_macos.sh`. Xcode build phase copies framework into app bundle. Loaded at runtime via `@rpath/plans_core.framework/plans_core`.
- **Theme**: Dark only. Palette — bg `#151618`, surface `#1B1D21`, elevated `#23262B`, accent `#7C6DF2`.
- **Animations**: `easeOutCubic`, 200ms standard duration, gentle springs.
- **IDs**: UUIDs generated in Rust (`uuid` crate v4). Never auto-increment.
- **Offline-first**: All mutations go to local SQLite via Rust; no network calls.
- **`Task.copyWith`**: nullable fields (`description`, `dueDate`, `reminderMinutes`) use a private `_absent` sentinel so callers can explicitly set them to `null`.

## Default Projects

Seeded by Rust on DB creation (`db.rs`) with hardcoded IDs: `'default'` (Inbox), `'work'`, `'personal'`, `'ideas'`. `Task.projectId` defaults to `'default'`.

## Testing

Use `FakeDatabaseService` from `test/shared/fake_database_service.dart` — synchronous in-memory fake extending `DatabaseService`, overrides all methods including `restoreTask`, `clearCompleted`, `reorderTasks`.

**Seed before use**: call `db.seedProject(Project(id: 'default', name: 'Inbox', colorIndex: 0))` before reading tasks that filter by project.

**Provider test pattern**:
```dart
final db = FakeDatabaseService()..seedProject(...);
final container = createContainer(db);
await Future(() {}); await Future(() {}); // flush async providers
final tasks = container.read(tasksProvider);
container.dispose();
```

**Widget test pattern**: pump `ProviderScope` with override → `await Future.delayed(Duration(milliseconds: 300))` → `await tester.pump(...)`.

`flutter analyze` is authoritative. LSP may show stale errors for deleted files (`add_task_dialog.dart`, `project_sidebar.dart`).

## Planned Architecture (future phases)

- Phase 4: sync engine (last-write-wins initially, then CRDT)
- Phase 5: Axum/PostgreSQL backend
- Soft deletes (`is_deleted`) and change log table already in Rust schema for sync

## Known Issues

- `flutter build macos --debug` may fail due to local Xcode deployment target conflict (not a code issue).
