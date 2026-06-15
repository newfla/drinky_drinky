---
phase: 16-project-readme
reviewed: 2026-06-15T00:00:00Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - README.md
  - docs/images/.gitkeep
findings:
  critical: 1
  warning: 3
  info: 2
  total: 6
status: issues_found
---

# Phase 16: Code Review Report

**Reviewed:** 2026-06-15
**Depth:** standard
**Files Reviewed:** 2
**Status:** issues_found

## Summary

Phase 16 is a documentation-only change: the Flutter placeholder README is replaced with a project README, and a `docs/images/` directory placeholder is created. The replacement README is well-structured and follows the plan's section order. However, one platform requirement is factually wrong (iOS deployment target), and several features listed in the feature table are either unverifiable from the README alone or confirmed shipped but described in ways that could mislead a developer. The build instructions are in the correct order and the Markdown image syntax will render correctly on GitHub.

---

## Critical Issues

### CR-01: iOS deployment target is wrong — README says iOS 13+, Xcode project requires iOS 16.0

**File:** `README.md:66`
**Issue:** The Platform Requirements table states `iOS 13+` as the minimum iOS version. The actual Xcode project configuration (`ios/Runner.xcodeproj/project.pbxproj`) sets `IPHONEOS_DEPLOYMENT_TARGET = 16.0` in all three build configurations (Debug, Profile, Release). A developer following the README who tries to target iOS 13, 14, or 15 will hit a runtime or App Store submission failure. The CLAUDE.md tech-stack document also says iOS 13+ (derived from flutter_local_notifications 21.x requirements), but the actual project target has been raised above that baseline.

**Fix:** Update the Platform Requirements table to reflect the actual Xcode setting:

```markdown
| Platform | Requirement |
|----------|-------------|
| Android  | compileSdk 36, minSdk 26 (Android 8.0+) |
| iOS      | iOS 16.0+ |
```

If iOS 13 is the intended floor, the Xcode project must be updated to match — but README must not contradict the build config in its current state.

---

## Warnings

### WR-01: Screenshot images referenced in README do not exist — broken image links on GitHub

**File:** `README.md:11`
**Issue:** The README references `docs/images/home_ios.png` and `docs/images/home_android.png` in a Markdown image table. Neither file exists in the repository (only the `.gitkeep` placeholder is committed). On GitHub, these will render as broken image icons rather than screenshots. The plan acknowledges this is intentional (Task 2 is a human-verify checkpoint requiring the developer to add the PNGs), but the README contains no note informing a viewer that the images are placeholders pending addition.

The plan explicitly requires an italic note below the screenshot table: `"Screenshots are added manually -- see docs/images/ for expected file names."` This note is absent from the delivered README.

**Fix:** Add the italic note below the screenshot table as specified in the plan (16-01-PLAN.md line 82):

```markdown
| iOS | Android |
|-----|---------|
| ![Home screen -- iOS](docs/images/home_ios.png) | ![Home screen -- Android](docs/images/home_android.png) |

_Screenshots are added manually -- see docs/images/ for expected file names._
```

### WR-02: H1 heading is missing the required water-drop emoji prefix

**File:** `README.md:1`
**Issue:** The plan (16-01-PLAN.md line 75) specifies: `"H1 heading: 'Drinky Drinky' with a water drop emoji prefix."` The delivered README opens with `# Drinky Drinky` — no emoji. This is a deliberate design decision captured in the locked plan; its omission means the acceptance criteria from the phase plan is not fully met.

**Fix:**
```markdown
# Drinky Drinky
```
should be:
```markdown
# Drinky Drinky
```
Add the water drop emoji (U+1F4A7) as the plan specifies:
```markdown
# Drinky Drinky
```

### WR-03: `flutter_local_notifications` minSdk constraint (24) conflicts with README-stated minSdk 26

**File:** `README.md:66`
**Issue:** The README correctly states `minSdk 26`. However, the CLAUDE.md tech-stack documentation states that `flutter_local_notifications 21.x` requires `minSdk 24`. The actual build config (`android/app/build.gradle.kts:27`) sets `minSdk = 26`, which satisfies both constraints. The concern is directional: `flutter_local_notifications` sets the lower bound at 24, and the project has chosen 26. A developer reading only the README has no way to know whether minSdk 26 is a hard requirement of a dependency or a project choice they could lower. If a contributor lowers minSdk to 24 or 25 (thinking the README overstated the requirement), `permission_handler 12.x` or another dependency may break.

**Fix:** Add a parenthetical to clarify the source of the constraint:

```markdown
| Android  | compileSdk 36, minSdk 26 (Android 8.0+; required by permission_handler and flutter_local_notifications) |
```

---

## Info

### IN-01: Clone URL uses a generic placeholder — will silently be wrong if repo is ever public

**File:** `README.md:40`
**Issue:** The clone step uses `https://github.com/user/drinky_drinky.git`. This is a placeholder acknowledged by the plan ("use a generic GitHub URL placeholder"). When the repository is published or shared with collaborators, this URL will silently point to a non-existent path. There is no inline comment or note indicating it is a placeholder.

**Fix:** Add a short comment after the URL, or replace with the actual repository URL when known:

```sh
git clone https://github.com/user/drinky_drinky.git   # replace with actual repo URL
cd drinky_drinky
```

### IN-02: "Undo last intake entry" feature description understates scope

**File:** `README.md:19`
**Issue:** The feature bullet reads `Undo last intake entry`. The implementation (`water_entry_dao.dart:34`) deletes the most recent entry for the current date. The feature correctly undoes only the last entry (not an arbitrary entry), which the README captures accurately. However, whether undo is surfaced as a persistent button, a snackbar action, or only within a time window is not described — first-time developers may not find it without guidance. This is a minor documentation completeness gap, not a technical inaccuracy.

**Fix:** Consider expanding to: `Undo last water entry (removes the most recent logged drink)` to set expectations about scope.

---

_Reviewed: 2026-06-15_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
