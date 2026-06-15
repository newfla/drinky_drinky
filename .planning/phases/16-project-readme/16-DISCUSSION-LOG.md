# Phase 16: Project README - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-15
**Phase:** 16-project-readme
**Areas discussed:** Screenshot acquisition, README language, README depth, Screenshot storage path

---

## Screenshot Acquisition

| Option | Description | Selected |
|--------|-------------|----------|
| Manual — I'll provide them | User takes screenshots from Simulator or device, places them in the agreed folder before execution | ✓ |
| Automated — via Simulator CLI | Planner uses xcrun simctl to launch iOS Simulator and take screenshots programmatically | |
| Placeholder images for now | Simple placeholder PNGs with "replace with real screenshots" note | |

**User's choice:** Manual — I'll provide them

Follow-up Q: When?

| Option | Description | Selected |
|--------|-------------|----------|
| Before execution | Capture and place files first, then run /gsd-execute-phase | |
| During execution — planner pauses | Execution pauses at a checkpoint, user adds files, then resumes | |
| After execution | Write README first with placeholder paths, user swaps in real files afterward | ✓ (free text) |

**Notes:** User clarified via freeform: "After" — README is written with expected paths (`docs/images/home_ios.png`, `docs/images/home_android.png`), then the developer drops in the actual screenshot files and they render automatically on GitHub.

---

## README Language

| Option | Description | Selected |
|--------|-------------|----------|
| English | Standard for open-source repos, consistent with CLAUDE.md and code comments | ✓ |
| Italian | Matches developer's working language; requirements in REQUIREMENTS.md are in Italian | |
| Bilingual (EN + IT) | English first with Italian section below — covers both audiences | |

**User's choice:** English
**Notes:** No additional context provided.

---

## README Depth

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal — clone + flutter run | Assumes Flutter installed; just clone, flutter pub get, flutter run | |
| Standard — includes code gen + platform notes | Adds dart run build_runner build (Drift + Riverpod code gen), Android compileSdk 36, iOS 13+ | ✓ |
| Full — contributor guide | Also covers tests, project structure, architecture, contribution notes | |

**User's choice:** Standard — includes code gen + platform notes
**Notes:** The code gen step (`dart run build_runner build`) is easy to miss and required for the app to compile.

---

## Screenshot Storage Path

| Option | Description | Selected |
|--------|-------------|----------|
| assets/screenshots/ (Recommended) | Extends existing assets/icon/ directory | |
| docs/images/ | Conventional GitHub documentation images location; new top-level docs/ directory | ✓ |
| screenshots/ at root | Flat, visible; new top-level directory alongside lib/, ios/, android/ | |

**User's choice:** docs/images/
**Notes:** Conventional GitHub convention for README images; kept separate from Flutter's bundled assets/ directory.

---

## Claude's Discretion

- Exact README section ordering and headings (standard GitHub convention: title, description, screenshots, features, getting started)
- Whether to include a brief tech stack line
- Exact screenshot file naming convention (`home_ios.png`, `home_android.png` chosen for clarity)

## Deferred Ideas

None — discussion stayed within phase scope.
