# plans_app

Todoist/Linear-style Flutter task manager for macOS. Dark theme, offline-first, Rust backend via `flutter_rust_bridge`.

## Getting Started

```bash
cd plans_app
./run_macos.sh
```

Builds Rust (`plans_core` framework) then runs `flutter run -d macos`.

## Key Features

- Dark theme (bg #151618, accent #7C6DF2)
- Inter font bundled locally (no google_fonts)
- 240px sidebar with smart lists (Inbox/Today/Completed) + projects
- Inline task composer with priority, due date, project selection
- Animated checkboxes with priority-colored borders
- Rust backend: `rusqlite` SQLite, `serde` serialization, `uuid` IDs

## Architecture

```
plans_app/
  lib/          — Flutter UI (Riverpod state, feature-based layout)
  rust/         — Rust crate (plans_core): api/, db.rs, models.rs
  macos/        — Xcode project with "Copy Rust Framework" build phase
src/
  rust/         — Auto-generated flutter_rust_bridge Dart bindings
```

All mutations hit local SQLite via Rust FFI — no network calls yet.

## Planned

- Phase 4: Sync engine (CRDT)
- Phase 5: Axum/PostgreSQL server
