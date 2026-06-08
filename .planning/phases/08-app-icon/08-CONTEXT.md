# Phase 8: App Icon — Context

**Gathered:** 2026-06-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 8 delivers a custom water glass launcher icon across all iOS and Android sizes using `flutter_launcher_icons`:

1. **Programmatic icon generation** — A Dart script (`tool/generate_icon.dart`) renders a 1024×1024 source PNG (glass on solid blue background) and a foreground-only PNG (glass on transparent background for adaptive icon)
2. **flutter_launcher_icons config** — `flutter_launcher_icons: ^0.14.4` added as dev_dependency; YAML config in pubspec.yaml generates all platform sizes
3. **iOS** — opaque PNG, no alpha channel (App Store requirement); all appiconset sizes overwritten
4. **Android** — adaptive icon (API 26+) with separate foreground and background layers; flat fallback for older Android

No screens, no navigation, no DB changes, no runtime dependencies added.

</domain>

<decisions>
## Implementation Decisions

### Icon Source
- **D-01:** Icon is generated programmatically via a Dart script (`tool/generate_icon.dart`) using the `image` package. No external design tool required; the script runs as a one-shot generator before `flutter_launcher_icons` runs.
- **D-02:** The script produces two PNG files:
  - `assets/icon/app_icon.png` — 1024×1024 flat icon (glass silhouette on #1565C0 background); used for iOS and Android legacy fallback
  - `assets/icon/app_icon_foreground.png` — 1024×1024 foreground only (glass silhouette on transparent background); used for Android adaptive icon foreground layer
- **D-03:** The `assets/icon/` directory is created by the script. These are build-time assets not referenced by Flutter's asset system; they are source files for flutter_launcher_icons only.

### Visual Design
- **D-04:** Background color: `#1565C0` (deep blue — matches the app's static blue seed palette from Phase 6). Used for: iOS opaque background, Android adaptive background layer, flat PNG background.
- **D-05:** Glass motif: a white, minimal/flat water glass silhouette centered in the 1024×1024 canvas. Style: flat design, no gradients, no shadows. The glass shape is a trapezoid body with a subtle water fill line. Claude has discretion over exact geometry.
- **D-06:** iOS opaque requirement: satisfied automatically by using a solid #1565C0 background with no alpha. The generated PNG has no transparency.

### Android Adaptive Icon
- **D-07:** Android adaptive icon: YES. Generates both `ic_launcher_foreground` and `ic_launcher_background` layers. Android 8+ renders the adaptive shape (circle, squircle, etc.) clipped from the foreground; older Android falls back to the flat `ic_launcher.png`.
- **D-08:** The adaptive background layer is a solid #1565C0 fill — flutter_launcher_icons accepts a hex color string directly for the adaptive background, so no separate background PNG is needed.

### Tool Configuration
- **D-09:** `flutter_launcher_icons: ^0.14.4` added to `dev_dependencies` in `pubspec.yaml`.
- **D-10:** flutter_launcher_icons config lives in `pubspec.yaml` under the `flutter_launcher_icons:` key (not a separate `flutter_launcher_icons.yaml`).
- **D-11:** `dart run flutter_launcher_icons` is run after generating the source PNGs. This overwrites all existing platform icon files in `ios/Runner/Assets.xcassets/AppIcon.appiconset/` and `android/app/src/main/res/mipmap-*/`.

### Claude's Discretion
- Exact water glass geometry (trapezoid proportions, handle presence, water level indicator)
- Whether to use the `image` package (pub.dev) or a pure `dart:ui` canvas + `dart:io` file approach for the generation script
- Specific `image` package version; must be a pure Dart package (no native code) so it works in a plain `dart run` context without Flutter
- flutter_launcher_icons YAML keys: `image_path`, `image_path_android`, `adaptive_icon_foreground`, `adaptive_icon_background`, `min_sdk_android`, `ios`, `android`

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope
- `.planning/REQUIREMENTS.md` — ICON-01 requirement
- `.planning/ROADMAP.md` — Phase 8 goal, success criteria

### Files that change in this phase
- `pubspec.yaml` — add `flutter_launcher_icons: ^0.14.4` to dev_dependencies; add `flutter_launcher_icons:` config block
- `tool/generate_icon.dart` — new Dart script; generates source PNGs
- `assets/icon/app_icon.png` — generated source (created by script)
- `assets/icon/app_icon_foreground.png` — generated adaptive foreground (created by script)
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/` — all PNGs overwritten by flutter_launcher_icons
- `android/app/src/main/res/mipmap-*/ic_launcher.png` — overwritten
- `android/app/src/main/res/mipmap-anydpi-v26/` — adaptive XML files created (new directory)

### Key context from prior phases
- `.planning/phases/06-bug-fix-theme-l-display/06-CONTEXT.md` — static blue seed palette `#1565C0` established in Phase 6 (D-04 above matches this color)

</canonical_refs>

<code_context>
## Existing Code Insights

### Current Icon State
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/` — 14 default Flutter placeholder PNGs; `Contents.json` present with full appiconset manifest. All will be overwritten.
- `android/app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png` — 5 default Flutter placeholder PNGs. Overwritten. No existing adaptive icon layers.
- No `mipmap-anydpi-v26/` directory — flutter_launcher_icons will create it.

### pubspec.yaml State
- `flutter_launcher_icons` is **not** in pubspec.yaml yet — must be added as dev_dependency.
- No `flutter_launcher_icons:` config block yet.
- No `assets:` section — the `assets/icon/` directory is not declared (correct: these are build-time sources, not runtime assets).

### Generation Script Context
- `tool/` directory does not exist — the script will create it.
- Must use a pub.dev package (or `dart:ui`) that works in a plain `dart run` context (no Flutter engine needed).
- The `image` package (pure Dart) is the standard choice for programmatic PNG generation in CLI Dart scripts.

</code_context>

<specifics>
## Specific Values

- Source icon size: 1024×1024 px
- Background: `#1565C0` (R=21, G=101, B=192)
- Glass silhouette: white (`#FFFFFF`), flat style, centered
- Android adaptive: foreground = `assets/icon/app_icon_foreground.png`; background = hex color `#1565C0` (no separate background PNG needed)
- flutter_launcher_icons version: `^0.14.4`

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 8-App Icon*
*Context gathered: 2026-06-08*
