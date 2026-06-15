# Phase 16: Project README - Context

**Gathered:** 2026-06-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Replace the default Flutter placeholder README.md in the repository root with a proper project README for Drinky Drinky. Must deliver:
1. Project description and core value proposition
2. Two home screen screenshots — one iOS, one Android — embedded in the README
3. Standard build instructions covering clone, pub get, code generation, and flutter run

This phase is documentation-only. No app code changes. Screenshots are provided manually by the developer after execution.

</domain>

<decisions>
## Implementation Decisions

### Screenshot acquisition and storage

- **D-01:** Screenshots are provided manually by the developer — the planner should NOT automate screenshot capture. Execution writes the README with placeholder image paths; the developer drops in the real files afterward and the paths just work.
- **D-02:** Screenshot files live at `docs/images/home_ios.png` and `docs/images/home_android.png`. A new `docs/images/` directory must be created. This is the conventional GitHub documentation images location.
- **D-03:** README must reference the screenshots with relative Markdown image syntax so they render on GitHub: `![Home screen — iOS](docs/images/home_ios.png)` and `![Home screen — Android](docs/images/home_android.png)`.

### Language

- **D-04:** README is written in **English** — consistent with CLAUDE.md and code comments, and standard for open-source discoverability.

### README depth and structure

- **D-05:** Build instructions should be **Standard** depth — sufficient for a developer with Flutter installed to clone and run the app, including the code generation step that is easy to miss:
  1. `git clone <repo>` + `cd drinky_drinky`
  2. `flutter pub get`
  3. `dart run build_runner build --delete-conflicting-outputs` (required — app uses Drift + Riverpod code gen)
  4. `flutter run`
- **D-06:** Include platform SDK requirements as a brief note:
  - Android: compileSdk 36, minSdk 26 (Android 8.0+)
  - iOS: iOS 13+
- **D-07:** README should include a brief feature list / what the app does — the project description section should cover: goal, core screens (home with progress ring, history calendar, settings), and offline-first nature.

### Claude's Discretion

- Exact section heading structure and ordering within the README — standard GitHub convention is: title/badge, description, screenshots, features, getting started/build
- Whether to include a brief tech stack mention (Flutter + Riverpod + Drift) — reasonable to include as one line in the project description
- Exact file name convention for screenshots (e.g. `home_ios.png` vs `screenshot_ios.png`) — use `home_ios.png` and `home_android.png` for clarity

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` §v1.4 — DOC-01 exact acceptance text: "README.md describes the project with two home screen screenshots (iOS and Android) and essential build instructions"

### Roadmap / success criteria
- `.planning/ROADMAP.md` Phase 16 — Success criteria: (1) README.md exists with description, two screenshots, build instructions; (2) build instructions sufficient for a Flutter developer to clone and run

### Existing README (to replace)
- `README.md` — current file: default Flutter placeholder ("A new Flutter project.") — this file is being fully replaced

### Existing app for description accuracy
- `.planning/PROJECT.md` §What This Is + §Core Value — authoritative description of the app to draw from
- `pubspec.yaml` — app name and dependencies to reference if listing tech stack

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `assets/icon/app_icon.png` — the app icon exists and can be referenced in the README badge or visual identity section if desired
- `docs/images/` — does NOT yet exist; must be created as part of this phase

### Established Patterns
- `assets/` directory structure: currently only `assets/icon/` — `docs/images/` is a separate conventional location for README images on GitHub (outside `assets/` which Flutter bundles into the app)
- CLAUDE.md language: English — README must match

### Integration Points
- `README.md` in repo root — file is fully replaced (not appended); existing content is the default Flutter placeholder and has no value to preserve
- `docs/images/` directory — new; must be created with `.gitkeep` or actual screenshot files (placeholder approach: create directory and reference expected paths)

</code_context>

<specifics>
## Specific Ideas

- The planner should create `docs/images/` directory and potentially a `.gitkeep` placeholder so the directory is committed even before screenshots arrive
- Screenshot image paths in README: `docs/images/home_ios.png` and `docs/images/home_android.png` — these exact names should be used so the developer knows exactly what to name their files
- The developer will add the actual screenshot PNGs after execution; the README markdown will reference them and they'll render correctly on GitHub once the files exist

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 16-project-readme*
*Context gathered: 2026-06-15*
