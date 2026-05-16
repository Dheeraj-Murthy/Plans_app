Building Your Todoist-Style App — Practical Starting Roadmap

Goal

Build a fast, cross-platform productivity app with:

- Tasks / projects / labels
- Sync between Android + macOS initially
- Offline-first architecture
- Widgets (Android homescreen)
- Notifications / reminders
- Calendar integration
- Future support for Linux + Windows
- Flutter frontend + Rust backend/core

⸻

1. Recommended Tech Stack

Frontend

Flutter

Use Flutter for:

- Android
- macOS
- Future Linux/Windows support

Why:

- Single UI codebase
- Excellent productivity
- Strong widget ecosystem
- Good desktop support
- Fast iteration

⸻

Core Logic + Sync Engine

Rust

Use Rust for:

- Local database layer
- Sync engine
- Conflict resolution
- Business logic
- Encryption (future)

Expose Rust to Flutter using:

flutter_rust_bridge

This is currently the best setup for Flutter + Rust integration.

⸻

Local Database

SQLite

Use:

- SQLite on-device
- Drift OR direct sqlite package in Flutter
- Or use SQLite entirely from Rust

Recommended:

Keep DB in Rust.

Why:

- Single source of truth
- Easier sync logic
- Better future portability
- Cleaner architecture

⸻

Backend

Start simple.

Initial Backend:

- Rust (Axum)
- PostgreSQL
- Docker deploy
- REST API initially

You DO NOT need:

- Microservices
- Kubernetes
- Event sourcing
- AI infrastructure

Not yet.

⸻

2. Architecture

High-Level

Flutter UI ↓ Rust Core Library ↓ SQLite Local DB ↓ Sync Engine ↓ Backend API ↓
Postgres

⸻

3. MVP Scope (VERY IMPORTANT)

Do NOT build everything immediately.

Your first goal:

MVP Features

Tasks

- Create/edit/delete task
- Due date
- Priority
- Completed state

Projects

- Group tasks

Offline Support

- Everything works without internet

Sync

- Sync across devices

Notifications

- Local reminders

Simple Widget

- Show today’s tasks

That is enough.

Do NOT start with:

- AI scheduling
- Team collaboration
- Shared workspaces
- Realtime collaboration
- Natural language parsing
- Kanban
- Notes
- Habit tracking

Those come later.

⸻

4. Suggested Development Order

Phase 1 — Flutter Prototype

Goal: Get UI working quickly.

Build:

- Task list screen
- Add task modal
- Project sidebar
- State management

Use:

- Riverpod
- go_router

Do NOT integrate Rust yet.

Just build UI + fake data.

Expected time: 1–2 weeks.

⸻

Phase 2 — Local Persistence

Now add:

- SQLite
- Local storage
- CRUD operations

Still single-device.

Expected time: 1 week.

⸻

Phase 3 — Introduce Rust

Move:

- DB layer
- Business logic

into Rust.

Flutter becomes mostly UI.

This is where architecture becomes solid.

Expected time: 1–2 weeks.

⸻

Phase 4 — Sync Engine

Most important technical challenge.

Implement:

- Device IDs
- Change tracking
- Last modified timestamps
- Pull/push sync
- Conflict handling

Start VERY simple.

Use:

last_write_wins

initially.

Do not overengineer sync.

Expected time: 2–4 weeks.

⸻

Phase 5 — Backend

Build:

- Auth
- Task storage
- Sync endpoints

Suggested stack:

- Axum
- PostgreSQL
- sqlx
- JWT auth

Deploy:

- Hetzner VPS
- Railway
- Fly.io
- Render

Expected time: 2 weeks.

⸻

Phase 6 — Widgets + Notifications

Android

Use:

- home_widget package
- flutter_local_notifications

Widgets are slightly annoying in Flutter but manageable.

Expected time: 1 week.

⸻

5. Recommended Folder Structure

Flutter

app/ ├── features/ ├── shared/ ├── widgets/ ├── routing/ ├── theme/ └──
main.dart

⸻

Rust

rust_core/ ├── db/ ├── sync/ ├── models/ ├── api/ ├── notifications/ └── lib.rs

⸻

6. Important Engineering Decisions

Offline First

Everything should work locally.

Sync should be additive.

Do NOT depend on server availability.

This is critical.

⸻

UUID-Based IDs

Use UUIDs everywhere.

Never use incremental IDs.

Reason:

Sync becomes easier.

⸻

Soft Deletes

Never truly delete immediately.

Use:

is_deleted = true

This helps sync.

⸻

Change Log Table

Maintain operation logs.

Example:

changes

- id
- entity_type
- entity_id
- operation
- timestamp

This simplifies syncing enormously.

⸻

7. Authentication

Initially:

- Email/password

Later:

- Google login
- GitHub login
- Apple login

Keep auth simple initially.

⸻

8. Calendar Integration

Do NOT deeply integrate initially.

Start with:

- Export reminders
- Read-only calendar view

Later:

- Two-way sync

Calendar sync is more annoying than it looks.

⸻

9. UI Inspiration

Look at:

- Todoist
- TickTick
- Things 3
- Superlist
- Linear

Observe:

- Spacing
- Typography
- Keyboard shortcuts
- Animation smoothness
- Fast task entry

The UX matters more than feature count.

⸻

10. What Actually Makes Todoist Hard

Not UI.

The hard parts are:

1. Sync correctness
2. Conflict resolution
3. Offline support
4. Notifications reliability
5. Cross-platform consistency
6. Widget integration
7. Fast interactions

⸻

11. Best Learning Path

Learn These Properly

Flutter

- Riverpod
- Async state
- Desktop support
- Platform channels

Rust

- Ownership
- async/await
- serde
- sqlx
- Axum

Databases

- SQLite
- PostgreSQL
- Indexing
- Transactions

Sync Concepts

- CRDT basics
- Event logs
- Conflict resolution
- Optimistic updates

⸻

12. Realistic Timeline

Solo Developer

Functional MVP

2–3 months

Good polished app

6–12 months

Truly production-grade sync platform

1–2 years

That is normal.

⸻

13. Immediate First Steps (This Week)

Day 1

Install:

- Flutter
- Android Studio
- Rust
- cargo
- flutter_rust_bridge

⸻

Day 2

Create:

flutter create plans_app

Build:

- Task list UI
- Add task button

No backend.

⸻

Day 3–4

Add:

- Riverpod
- Routing
- Theme system

⸻

Day 5–7

Build:

- Local task persistence
- Projects
- Task detail page

By end of week:

You should have a clean local-only app.

That is the correct start.

⸻

14. Recommended Packages

Flutter

State

- flutter_riverpod

Routing

- go_router

Local notifications

- flutter_local_notifications

Widgets

- home_widget

Local storage

- sqlite3
- drift

UI

- flex_color_scheme
- animations

⸻

Rust

Backend

- axum
- tokio
- serde
- sqlx

DB

- rusqlite

Flutter bridge

- flutter_rust_bridge

⸻

15. Biggest Advice

Do NOT try to build Todoist fully.

Build:

small fast stable offline-first

A tiny app with excellent sync and smooth UX is already very impressive.

Most productivity apps fail because they become bloated.

Focus on:

- Speed
- Reliability
- Great interactions
- Keyboard shortcuts
- Clean UX

That matters far more than 100 features.
