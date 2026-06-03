# Phase 1: Data Foundation - Context

**Gathered:** 2026-06-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 1 delivers the complete persistence layer: Flutter project scaffold, Drift database schema, type-safe DAOs, repository interfaces, and Riverpod providers wired to repositories. No UI screens, no notifications. Every subsequent phase reads and writes data through this layer without touching SQLite directly.

</domain>

<decisions>
## Implementation Decisions

### Flutter Project Scaffold
- **D-01:** Bundle ID: `com.bizzarri.drinkydrinky` — app name: `Drinky Drinky`
- **D-02:** Minimum iOS: 16.0 (covers 95%+ active devices, supports all required APIs)
- **D-03:** Minimum Android: API 26 / Android 8.0 (>99% market share, flutter_local_notifications compatible)
- **D-04:** Scaffold command: `flutter create --org com.bizzarri --project-name drinky_drinky --platforms ios,android`

### Default Seed Values (first-launch experience)
- **D-05:** Daily target default: **2000 ml** (2 L)
- **D-06:** Quick-add preset defaults (4 buttons): **200 ml / 300 ml / 400 ml / 500 ml**
- **D-07:** Notification interval default: **60 minutes**
- **D-08:** DND window default: **23:00 – 07:00** (enabled by default)

### Code Generation & Style
- **D-09:** Riverpod: use **code generation** (`@riverpod` annotations + `build_runner`). build_runner already required by Drift — no additional cost.
- **D-10:** Use **Freezed** for domain model classes (UserSettings, DrinkPreset, DailyProgress, WaterEntry) — automatic `copyWith`, equality, `toString`.
- **D-11:** Use **GoRouter** for navigation between the 3 screens (Home / History / Settings).

### Folder Structure
- **D-12:** **Layer-first** organization:
  ```
  lib/
  ├── data/
  │   ├── database/     ← Drift AppDatabase, tables, DAOs
  │   ├── repositories/ ← Repository implementations
  │   └── models/       ← Drift generated, raw data models
  ├── domain/
  │   └── entities/     ← Freezed domain entities (WaterEntry, UserSettings, etc.)
  ├── presentation/
  │   └── screens/      ← Flutter screens (populated in Phase 2+)
  ├── core/
  │   ├── providers/    ← Riverpod provider declarations
  │   └── router/       ← GoRouter configuration
  └── main.dart
  ```

### Critical Drift Configuration (IRREVERSIBLE)
- **D-13:** `drift_options: store_date_time_values_as_text: true` MUST be set in `build.yaml` before writing any data. This is irreversible without a manual migration.
- **D-14:** Every `water_entries` row MUST store a `date_key` column (`TEXT`, format `YYYY-MM-DD` in local timezone) in addition to the UTC timestamp. Daily aggregates query by `date_key`, not by UTC date. This is mandatory for correct midnight-reset behavior across timezones and DST.

### Database Schema (Drift tables)
- **D-15:** Three tables:
  - `water_entries`: `id` (PK autoincrement), `amount_ml` (INTEGER), `logged_at` (DATETIME as text), `date_key` (TEXT, local date string YYYY-MM-DD)
  - `user_settings`: single-row table (id=1), `daily_target_ml` (INTEGER, default 2000), `notification_interval_minutes` (INTEGER, default 60), `dnd_start_hour` (INTEGER, default 23), `dnd_start_minute` (INTEGER, default 0), `dnd_end_hour` (INTEGER, default 7), `dnd_end_minute` (INTEGER, default 0), `dnd_enabled` (BOOLEAN, default true)
  - `drink_presets`: `id` (PK autoincrement), `amount_ml` (INTEGER), `sort_order` (INTEGER) — seeded with 200/300/400/500ml

### Testing Strategy
- **D-16:** Unit tests for all DAOs using Drift's in-memory database (no mocking). Cover: insert/read water entries, query by date_key, CRUD for settings, CRUD for presets.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Context
- `.planning/PROJECT.md` — project vision, constraints, key decisions
- `.planning/REQUIREMENTS.md` — all v1 requirements; Phase 1 has none directly but schema must support all 13
- `.planning/ROADMAP.md` — phase goals and success criteria (Phase 1 criteria lines 1-5)

### Research Findings
- `.planning/research/STACK.md` — current package versions, drift_flutter vs sqlite3_flutter_libs decision, table_calendar, percent_indicator
- `.planning/research/ARCHITECTURE.md` — layer architecture, Drift stream/.watch() integration with Riverpod StreamProvider, DAO patterns, build order rationale
- `.planning/research/PITFALLS.md` — 15 pitfalls; critical ones for Phase 1: Drift DateTime storage (pitfall #1), date_key column pattern (pitfall #2), Riverpod autoDispose decisions (pitfall #8)
- `.planning/research/SUMMARY.md` — executive summary and roadmap implications

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- None yet — greenfield Flutter project. Phase 1 creates the foundation.

### Established Patterns
- None yet — patterns established in this phase become the conventions for Phases 2-5.

### Integration Points
- Phase 1 output is consumed by all subsequent phases: repositories expose `Stream<T>` that Riverpod `StreamProvider`s watch; widgets (Phases 2-4) call `ref.watch(waterEntriesProvider)` etc.

</code_context>

<specifics>
## Specific Ideas

- The layer-first folder structure was explicitly chosen by the user (over feature-first) — respect this in all subsequent phases.
- GoRouter should be set up in Phase 1 even though only `main.dart` routing exists; subsequent phases add routes without restructuring.
- Seed the default presets (200/300/400/500ml) and default settings (2000ml target, 60min interval, DND 23:00–07:00) at first-launch via a Drift migration callback or an explicit `_ensureDefaults()` call in the repository.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 1-Data Foundation*
*Context gathered: 2026-06-03*
