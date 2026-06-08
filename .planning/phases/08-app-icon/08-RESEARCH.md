# Phase 8: App Icon - Research

**Researched:** 2026-06-08
**Domain:** Build-time asset generation (Dart CLI scripting + Flutter launcher icon tooling)
**Confidence:** HIGH

## Summary

Phase 8 replaces the default Flutter placeholder launcher icons with a custom water glass motif icon across all iOS and Android sizes. The phase has two distinct steps: (1) a pure-Dart CLI script generates two 1024x1024 PNG source images using the `image` package, and (2) `flutter_launcher_icons` reads those PNGs and the pubspec.yaml config to produce all platform-specific icon files.

This is a build-time-only phase. No runtime dependencies are added. The `image` package is used only inside `tool/generate_icon.dart` (a CLI script run with `dart run`), and `flutter_launcher_icons` is a dev dependency that generates static asset files. Neither package ships in the final app binary.

**Primary recommendation:** Add `image: ^4.9.0` as a dev dependency (it is only needed by the generator script). Add `flutter_launcher_icons: ^0.14.4` as a dev dependency. Write the generator script at `tool/generate_icon.dart`. Run `dart run tool/generate_icon.dart` then `dart run flutter_launcher_icons` in sequence.

<user_constraints>

## User Constraints (from CONTEXT.md)

### Locked Decisions
- D-01: Icon is generated programmatically via a Dart script (`tool/generate_icon.dart`) using the `image` package. No external design tool required.
- D-02: Two output PNGs: `assets/icon/app_icon.png` (1024x1024 flat, opaque blue bg) and `assets/icon/app_icon_foreground.png` (1024x1024 glass on transparent bg)
- D-03: Background color: `#1565C0` (deep blue)
- D-04: Glass motif: white, minimal/flat water glass silhouette centered in canvas
- D-05: iOS opaque: satisfied by solid #1565C0 background
- D-06: Glass shape: trapezoid body with subtle water fill line (Claude has discretion over exact geometry)
- D-07: Android adaptive icon: YES. Foreground PNG + hex color background.
- D-08: Adaptive background layer: solid #1565C0 fill via hex color string in flutter_launcher_icons config
- D-09: `flutter_launcher_icons: ^0.14.4` added to `dev_dependencies`
- D-10: Config in `pubspec.yaml` under `flutter_launcher_icons:` key (not a separate file)
- D-11: Run `dart run flutter_launcher_icons` after generating PNGs

### Claude's Discretion
- Exact water glass geometry (trapezoid proportions, handle presence, water level indicator)
- Whether to use `image` package or pure `dart:ui` canvas approach (research recommends `image` -- see below)
- Specific `image` package version
- flutter_launcher_icons YAML keys arrangement

### Deferred Ideas (OUT OF SCOPE)
None.

</user_constraints>

<phase_requirements>

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ICON-01 | App uses a water glass motif icon across all required iOS and Android launcher sizes; iOS variant has an opaque background (no alpha channel) | `flutter_launcher_icons` generates all platform sizes from a single 1024x1024 source; `remove_alpha_ios: true` with `background_color_ios` enforces opaque iOS icons; `image` package provides pure-Dart PNG generation for the source files |

</phase_requirements>

## Project Constraints (from CLAUDE.md)

- **Tech stack**: Flutter + Riverpod + Drift -- no deviation
- **Platform**: iOS and Android only (no web/desktop)
- **flutter_launcher_icons: ^0.14.4** is listed in CLAUDE.md as the standard tool for icon generation
- **Dev dependency only** -- CLAUDE.md lists it under Dev/Quality section

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Icon source PNG generation | Build tooling (CLI script) | -- | Pure Dart script, no Flutter engine needed |
| Platform icon file generation | Build tooling (flutter_launcher_icons) | -- | Reads source PNGs, writes to ios/ and android/ asset directories |
| iOS icon sizing | Build tooling | CDN / Static (App Store) | flutter_launcher_icons produces all required appiconset sizes |
| Android adaptive icon | Build tooling | -- | Generates mipmap-anydpi-v26 XML + foreground PNGs |

## Standard Stack

### Core (Dev Dependencies Only)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter_launcher_icons | ^0.14.4 | Generate all platform icon sizes | 7.9k likes on pub.dev; verified publisher (fluttercommunity.dev); de facto standard for Flutter icon generation [CITED: pub.dev/packages/flutter_launcher_icons] |
| image | ^4.9.0 | Pure-Dart image creation and PNG encoding | 1.7k likes; verified publisher (loki3d.com); pure Dart with no native deps; works in `dart run` without Flutter engine [CITED: pub.dev/packages/image] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `image` package | `dart:ui` + Canvas | `dart:ui` requires the Flutter engine and cannot run via plain `dart run`; the `image` package is pure Dart and works as a CLI tool [ASSUMED] |
| `image` package | Hand-craft PNG bytes | Technically possible but absurdly complex for polygon drawing; `image` handles all encoding |
| `flutter_launcher_icons` | Manual icon resizing | Would need to create 20+ PNG files at exact sizes; tool does this in one command |

**Installation (add to pubspec.yaml dev_dependencies):**
```yaml
dev_dependencies:
  # ... existing dev deps ...
  flutter_launcher_icons: ^0.14.4
  image: ^4.9.0
```

Then run `dart pub get`.

**Note:** The `image` package is listed as a dev dependency because it is only used by the `tool/generate_icon.dart` CLI script and is never imported by any Flutter app code. This keeps the runtime binary clean.

## Package Legitimacy Audit

> slopcheck was unavailable at research time. All packages are tagged `[ASSUMED]`.

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| flutter_launcher_icons | pub.dev | ~5 yrs | 7.9k likes | github.com/fluttercommunity/flutter_launcher_icons | N/A | [ASSUMED] -- verified publisher fluttercommunity.dev, 150/160 pub points |
| image | pub.dev | ~10 yrs | 1.7k likes | github.com/brendan-duncan/image | N/A | [ASSUMED] -- verified publisher loki3d.com, 135/160 pub points |

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

*slopcheck was unavailable at research time. Both packages above are tagged `[ASSUMED]`. However, both have verified publishers on pub.dev, thousands of likes, and multi-year track records. The planner should gate each install behind a checkpoint:human-verify task per protocol, though risk is minimal.*

## Architecture Patterns

### System Architecture Diagram

```
[tool/generate_icon.dart]
    |
    | (1) dart run tool/generate_icon.dart
    |
    v
[assets/icon/]
    |-- app_icon.png          (1024x1024, opaque, #1565C0 bg + white glass)
    |-- app_icon_foreground.png (1024x1024, transparent bg + white glass)
    |
    | (2) dart run flutter_launcher_icons
    |     reads pubspec.yaml flutter_launcher_icons: config
    |
    v
[ios/Runner/Assets.xcassets/AppIcon.appiconset/]
    |-- Icon-App-20x20@1x.png ... Icon-App-1024x1024@1x.png  (overwritten)
    |-- Contents.json (updated)
    |
[android/app/src/main/res/]
    |-- mipmap-mdpi/ic_launcher.png      (48x48, flat fallback)
    |-- mipmap-hdpi/ic_launcher.png      (72x72)
    |-- mipmap-xhdpi/ic_launcher.png     (96x96)
    |-- mipmap-xxhdpi/ic_launcher.png    (144x144)
    |-- mipmap-xxxhdpi/ic_launcher.png   (192x192)
    |-- mipmap-anydpi-v26/
        |-- ic_launcher.xml              (adaptive icon manifest)
    |-- mipmap-mdpi/ic_launcher_foreground.png  ... (foreground layers)
```

### Recommended Project Structure

```
tool/
  generate_icon.dart     # Pure-Dart CLI script (new)
assets/
  icon/
    app_icon.png              # Generated: flat icon (new)
    app_icon_foreground.png   # Generated: adaptive foreground (new)
```

### Pattern 1: Pure-Dart CLI Script for Asset Generation

**What:** A standalone Dart script in `tool/` that uses the `image` package to programmatically draw and save PNG files. It runs via `dart run tool/generate_icon.dart` without needing the Flutter engine.

**When to use:** When you need reproducible, version-controlled asset generation without external design tools.

**Example:**
```dart
// Source: pub.dev/documentation/image/latest/
import 'dart:io';
import 'package:image/image.dart' as img;

Future<void> main() async {
  // Create 1024x1024 RGBA image
  final image = img.Image(width: 1024, height: 1024, numChannels: 4);

  // Fill with background color #1565C0
  img.fill(image, color: img.ColorRgba8(0x15, 0x65, 0xC0, 0xFF));

  // Draw white glass silhouette using polygon
  final glassVertices = [
    img.Point(312, 250),  // top-left
    img.Point(712, 250),  // top-right
    img.Point(662, 774),  // bottom-right
    img.Point(362, 774),  // bottom-left
  ];
  img.fillPolygon(image,
    vertices: glassVertices,
    color: img.ColorRgba8(255, 255, 255, 255),
  );

  // Save as PNG
  final dir = Directory('assets/icon');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  await img.encodePngFile('assets/icon/app_icon.png', image);
}
```

### Pattern 2: flutter_launcher_icons pubspec.yaml Config

**What:** YAML config block in pubspec.yaml that tells flutter_launcher_icons where to find source images and what to generate.

**Example:**
```yaml
# Source: pub.dev/packages/flutter_launcher_icons (README)
flutter_launcher_icons:
  image_path: "assets/icon/app_icon.png"
  
  android: true
  min_sdk_android: 26
  adaptive_icon_foreground: "assets/icon/app_icon_foreground.png"
  adaptive_icon_background: "#1565C0"
  
  ios: true
  remove_alpha_ios: true
  background_color_ios: "#1565C0"
```

**Key points:**
- `image_path` is the global fallback used for any platform that does not have a platform-specific override [CITED: pub.dev/packages/flutter_launcher_icons]
- `adaptive_icon_background` accepts a hex color string (e.g., `"#1565C0"`) OR an image path [CITED: pub.dev/packages/flutter_launcher_icons]
- `adaptive_icon_foreground` must be a PNG path [CITED: pub.dev/packages/flutter_launcher_icons]
- `remove_alpha_ios: true` strips the alpha channel from iOS icons; `background_color_ios` provides the fill color for areas that were transparent [CITED: pub.dev/packages/flutter_launcher_icons]
- `min_sdk_android: 26` -- since our app already has `minSdk = 26` in build.gradle.kts, adaptive icons are supported on ALL target devices [VERIFIED: android/app/build.gradle.kts]

### Anti-Patterns to Avoid

- **Using `dart:ui` for the generator script:** `dart:ui` requires the Flutter engine and will fail with "Cannot open dart:ui" when run via `dart run`. Use the `image` package (pure Dart) instead. [ASSUMED]
- **Putting `image` in runtime `dependencies`:** The image package is only needed for the build-time generator. Listing it in `dependencies` bloats the app binary for no reason.
- **Setting `android: "custom_name"`:** Using a custom name generates new icon files WITHOUT removing the old defaults. Use `android: true` to replace the existing defaults. [CITED: pub.dev/packages/flutter_launcher_icons]
- **Omitting `adaptive_icon_background`:** If only `adaptive_icon_foreground` is set (without background), adaptive icons will NOT be generated. Both must be specified. [CITED: pub.dev/packages/flutter_launcher_icons]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Platform icon sizing | Manual resize of PNGs to 20+ sizes | `flutter_launcher_icons` | Handles iOS appiconset (15+ sizes), Android mipmap (5 densities), adaptive XML, Contents.json updates |
| PNG encoding | Raw byte manipulation | `image` package `encodePngFile()` | PNG format has compression, filtering, CRC checksums -- the library handles all of it |
| Polygon rasterization | Pixel-by-pixel drawing | `image` package `fillPolygon()` | Scan-line fill with ray casting is non-trivial to implement correctly |
| iOS alpha removal | ImageMagick shell commands | `remove_alpha_ios: true` in config | flutter_launcher_icons handles it natively |

**Key insight:** This phase has zero runtime complexity -- it is entirely build-time tooling. The only risk is incorrect configuration, not runtime bugs.

## Common Pitfalls

### Pitfall 1: Android Adaptive Icon Safe Zone

**What goes wrong:** The glass silhouette extends to the edge of the 1024x1024 foreground image and gets clipped on devices that use circle, squircle, or rounded-square masks.
**Why it happens:** Android adaptive icons guarantee only the center 66% (the "safe zone") is visible. The outer 17% on each side may be clipped depending on the OEM's chosen mask shape.
**How to avoid:** Keep the glass silhouette within the center 66% of the 1024x1024 canvas. In pixel terms: the safe zone is a 676x676 area centered at (512, 512), meaning content should stay within x:[174, 850] and y:[174, 850]. Leave generous padding. The `adaptive_icon_foreground_inset` config key (default 16%) can add additional padding but the source image itself should already respect the safe zone.
**Warning signs:** Icon looks fine in Android Studio but gets clipped on a Samsung device (which uses a different mask shape than Pixel).

### Pitfall 2: iOS Alpha Channel Rejection

**What goes wrong:** The App Store rejects the build because the icon PNG contains an alpha channel.
**Why it happens:** Apple requires fully opaque app icons. If the source PNG has `numChannels: 4` (RGBA) with any transparent pixels, the App Store validator flags it.
**How to avoid:** Two defenses: (1) the `app_icon.png` is generated with a solid #1565C0 fill covering the entire canvas -- no transparent pixels exist even though the PNG is RGBA format; (2) `remove_alpha_ios: true` in the flutter_launcher_icons config strips the alpha channel entirely from generated iOS icons. Using both is belt-and-suspenders. [CITED: pub.dev/packages/flutter_launcher_icons]
**Warning signs:** `flutter_launcher_icons` logs a warning about alpha channel when processing iOS icons.

### Pitfall 3: Foreground PNG Must Have Transparent Background

**What goes wrong:** The adaptive foreground PNG has a blue background, so on Android 8+ devices the icon shows a blue square layered on top of the #1565C0 adaptive background.
**Why it happens:** The foreground and background are composited as separate layers. If the foreground has its own background fill, you get double-background.
**How to avoid:** The `app_icon_foreground.png` must use a transparent background (`numChannels: 4` with alpha=0 for non-glass pixels). Only the glass silhouette itself should be white/opaque. The generator script creates this by starting with a fully transparent canvas and only filling the glass polygon.
**Warning signs:** Icon appears to have a visible square boundary inside the adaptive shape.

### Pitfall 4: Running Commands in Wrong Order

**What goes wrong:** `dart run flutter_launcher_icons` runs before the source PNGs exist, producing errors or using stale/missing images.
**Why it happens:** Developer forgets to run the generator first.
**How to avoid:** Always run `dart run tool/generate_icon.dart` THEN `dart run flutter_launcher_icons`. The planner should make these sequential tasks.
**Warning signs:** Error message about missing file at `assets/icon/app_icon.png`.

### Pitfall 5: `image` Package Import Collision

**What goes wrong:** `import 'package:image/image.dart'` conflicts with other `Image` class names (Flutter's `dart:ui` Image, for example).
**Why it happens:** The package exports an `Image` class that collides with common names.
**How to avoid:** Use a prefix import: `import 'package:image/image.dart' as img;` -- then use `img.Image(...)`, `img.fill(...)`, etc. Since this script is pure Dart (no Flutter imports), the collision is unlikely but the prefix is still best practice.
**Warning signs:** Compilation error about ambiguous `Image` reference.

## Code Examples

Verified patterns from official sources:

### Creating Both Source PNGs (Generator Script Pattern)

```dart
// Source: pub.dev/documentation/image/latest/
import 'dart:io';
import 'package:image/image.dart' as img;

Future<void> main() async {
  const size = 1024;
  const bgR = 0x15, bgG = 0x65, bgB = 0xC0; // #1565C0

  // --- 1. Flat icon (opaque, for iOS + Android fallback) ---
  final flat = img.Image(width: size, height: size, numChannels: 4);
  img.fill(flat, color: img.ColorRgba8(bgR, bgG, bgB, 255));
  _drawGlass(flat);

  // --- 2. Foreground only (transparent bg, for Android adaptive) ---
  final fg = img.Image(width: size, height: size, numChannels: 4);
  // Default pixels are (0,0,0,0) = fully transparent -- no fill needed
  _drawGlass(fg);

  // --- Save ---
  final dir = Directory('assets/icon');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  await img.encodePngFile('assets/icon/app_icon.png', flat);
  await img.encodePngFile('assets/icon/app_icon_foreground.png', fg);

  print('Icons generated in assets/icon/');
}

void _drawGlass(img.Image image) {
  final white = img.ColorRgba8(255, 255, 255, 255);
  // Trapezoid glass body -- stays within adaptive safe zone
  // Safe zone: center 66% = pixels [174..850] on a 1024 canvas
  final body = [
    img.Point(330, 280),  // top-left
    img.Point(694, 280),  // top-right
    img.Point(644, 744),  // bottom-right
    img.Point(380, 744),  // bottom-left
  ];
  img.fillPolygon(image, vertices: body, color: white);
}
```

### flutter_launcher_icons pubspec.yaml Config Block

```yaml
# Source: pub.dev/packages/flutter_launcher_icons (README)
flutter_launcher_icons:
  image_path: "assets/icon/app_icon.png"

  android: true
  min_sdk_android: 26
  adaptive_icon_foreground: "assets/icon/app_icon_foreground.png"
  adaptive_icon_background: "#1565C0"

  ios: true
  remove_alpha_ios: true
  background_color_ios: "#1565C0"
```

### Running the Pipeline

```bash
# Step 1: Generate source PNGs
dart run tool/generate_icon.dart

# Step 2: Generate all platform icons
dart run flutter_launcher_icons
```

## `image` Package API Reference (for the generator script)

All functions are top-level in `package:image/image.dart`. [CITED: pub.dev/documentation/image/latest/]

| Function | Signature | Purpose |
|----------|-----------|---------|
| `Image()` | `Image({required int width, required int height, int numChannels = 3, ...})` | Create blank image; use `numChannels: 4` for RGBA |
| `fill()` | `fill(Image image, {required Color color})` | Fill entire image with solid color |
| `fillPolygon()` | `fillPolygon(Image src, {required List<Point> vertices, required Color color})` | Fill a polygon defined by vertex list |
| `fillRect()` | `fillRect(Image src, {required int x1, y1, x2, y2, required Color color, num radius = 0})` | Fill rectangle; `radius` for rounded corners |
| `fillCircle()` | `fillCircle(Image image, {required int x, y, radius, required Color color})` | Fill a circle |
| `drawLine()` | `drawLine(Image image, {required int x1, y1, x2, y2, required Color color, num thickness = 1})` | Draw a line with configurable thickness |
| `drawPolygon()` | `drawPolygon(Image src, {required List<Point> vertices, required Color color})` | Draw polygon outline (not filled) |
| `encodePngFile()` | `Future<bool> encodePngFile(String path, Image image, {int level = 6})` | Save image as PNG to file path (async) |
| `ColorRgba8()` | `ColorRgba8(int r, int g, int b, int a)` | Create RGBA color from 0-255 values |
| `Point()` | `Point([num x = 0, num y = 0])` | Create a 2D point for polygon vertices |

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `flutter pub run flutter_launcher_icons:main` | `dart run flutter_launcher_icons` | flutter_launcher_icons 0.12+ | Old command still works but new is preferred [ASSUMED] |
| Manual icon resizing in Photoshop/Figma | `flutter_launcher_icons` from single source | N/A | Eliminates manual work, ensures consistency |
| iOS dark/tinted icons not supported | `image_path_ios_dark_transparent` and `image_path_ios_tinted_grayscale` keys | flutter_launcher_icons 0.14.x | iOS 18+ dark mode icon support (not needed for this phase) [CITED: pub.dev/packages/flutter_launcher_icons] |

**Deprecated/outdated:**
- `flutter pub run flutter_launcher_icons:main` -- use `dart run flutter_launcher_icons` instead [ASSUMED]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `dart:ui` cannot be used in a plain `dart run` context without Flutter engine | Anti-Patterns | LOW -- would just mean an alternative approach exists; `image` package works regardless |
| A2 | `flutter pub run flutter_launcher_icons:main` is the old command form | State of the Art | NONE -- `dart run flutter_launcher_icons` is confirmed to work by official docs |
| A3 | Default pixels in a new `img.Image` with `numChannels: 4` are fully transparent (0,0,0,0) | Code Examples | MEDIUM -- if defaults are not transparent, the foreground PNG would need explicit clearing; verify at implementation time |
| A4 | Both packages are legitimate (slopcheck unavailable) | Package Legitimacy | LOW -- both have verified publishers on pub.dev with thousands of likes and years of history |
| A5 | `image: ^4.9.0` is compatible with the project's Dart SDK `^3.10.0` | Standard Stack | LOW -- image 4.9.1 requires Dart SDK 3.0+; project uses 3.10.0+ |

## Open Questions

1. **Default pixel values for new Image with numChannels: 4**
   - What we know: The `image` package creates an `Image(width, height, numChannels: 4)` with some default pixel values
   - What's unclear: Whether default pixels are `(0,0,0,0)` (fully transparent) or something else
   - Recommendation: The generator script should explicitly clear the foreground image to transparent before drawing. Use `img.fill(fg, color: img.ColorRgba8(0, 0, 0, 0))` as a safety measure.

2. **Exact files generated by flutter_launcher_icons for adaptive icons**
   - What we know: It creates adaptive icon support when both `adaptive_icon_foreground` and `adaptive_icon_background` are specified; it writes to `mipmap-*` directories
   - What's unclear: Exact file names in `mipmap-anydpi-v26/` (likely `ic_launcher.xml` but not confirmed in docs)
   - Recommendation: Run the tool and inspect output. The tool is well-tested and will produce correct Android-compatible files.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Dart SDK | Generator script + all commands | Likely (Flutter installed) | >= 3.10.0 | -- |
| Flutter SDK | flutter_launcher_icons | Likely | >= 3.38.1 | -- |
| `dart run` CLI | Running generator script | Likely (comes with Dart SDK) | -- | -- |

**Missing dependencies with no fallback:** None expected.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | N/A |
| V3 Session Management | no | N/A |
| V4 Access Control | no | N/A |
| V5 Input Validation | no | N/A (no user input; script uses hardcoded values) |
| V6 Cryptography | no | N/A |

**Security note:** This phase adds zero runtime code. All work is build-time asset generation. The `image` package and `flutter_launcher_icons` are dev dependencies that do not ship in the app binary. No new attack surface is introduced.

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Supply chain (malicious dev dependency) | Tampering | Both packages are from verified pub.dev publishers with multi-year track records; human-verify checkpoint before install |

## Sources

### Primary (HIGH confidence)
- pub.dev/packages/flutter_launcher_icons -- README, configuration reference, score page
- pub.dev/packages/image -- API documentation (Image, fill, fillPolygon, encodePngFile, ColorRgba8, Point classes)
- pub.dev/documentation/image/latest/ -- Function signatures and parameters

### Secondary (MEDIUM confidence)
- github.com/fluttercommunity/flutter_launcher_icons -- README (same content as pub.dev, cross-verified)

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- both packages are well-established with verified publishers, confirmed via pub.dev
- Architecture: HIGH -- the two-step pipeline (generate PNGs then run flutter_launcher_icons) is the standard Flutter approach
- Pitfalls: HIGH -- adaptive safe zone, iOS alpha, and command ordering are well-documented issues
- `image` package API: HIGH -- function signatures verified via pub.dev/documentation/image/latest/

**Research date:** 2026-06-08
**Valid until:** 2026-07-08 (stable domain; icon tooling changes infrequently)
