import 'dart:io';
import 'package:image/image.dart' as img;

/// Generates two 1024x1024 launcher icon source PNGs:
///
/// 1. `assets/icon/app_icon.png` — flat icon with opaque #1565C0 background
///    and white glass silhouette (used for iOS and Android legacy fallback).
/// 2. `assets/icon/app_icon_foreground.png` — glass silhouette on transparent
///    background (used for Android adaptive icon foreground layer).
///
/// Run from repo root: `dart run tool/generate_icon.dart`
Future<void> main() async {
  const size = 1024;
  const bgR = 0x15, bgG = 0x65, bgB = 0xC0; // #1565C0

  // --- 1. Flat icon (opaque, for iOS + Android legacy fallback) ---
  final flat = img.Image(width: size, height: size, numChannels: 4);
  img.fill(flat, color: img.ColorRgba8(bgR, bgG, bgB, 255));
  _drawGlass(flat);

  // --- 2. Foreground only (transparent bg, for Android adaptive) ---
  final fg = img.Image(width: size, height: size, numChannels: 4);
  // Explicitly fill with transparent to be safe (Open Question 1 from RESEARCH.md)
  img.fill(fg, color: img.ColorRgba8(0, 0, 0, 0));
  _drawGlass(fg);

  // --- 3. Save ---
  final dir = Directory('assets/icon');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  await img.encodePngFile('assets/icon/app_icon.png', flat);
  await img.encodePngFile('assets/icon/app_icon_foreground.png', fg);

  print('Icons generated in assets/icon/');
}

/// Draws a white water glass silhouette onto [image].
///
/// The glass is a trapezoid (wider at top, narrower at bottom) with a
/// water fill region in the lower portion. All coordinates stay within the
/// Android adaptive icon safe zone: center 66% = pixels [174..850] on a
/// 1024 canvas.
void _drawGlass(img.Image image) {
  final white = img.ColorRgba8(255, 255, 255, 255);
  // Slightly transparent white for the "empty" upper portion of the glass
  final glassRim = img.ColorRgba8(255, 255, 255, 200);

  // Glass body trapezoid — wider at top, narrower at bottom
  // All vertices within safe zone [174..850]
  // Top edge: y=240, bottom edge: y=780
  // Top width: ~380px (322..702), bottom width: ~260px (382..642)
  final glassBody = [
    img.Point(322, 240), // top-left
    img.Point(702, 240), // top-right
    img.Point(642, 780), // bottom-right
    img.Point(382, 780), // bottom-left
  ];

  // Draw the glass body outline (the "empty glass" upper portion)
  img.fillPolygon(image, vertices: glassBody, color: glassRim);

  // Water fill region — lower 60% of the glass interior
  // Water line at approximately y=456 (60% fill from bottom)
  // Interpolate x at y=456:
  //   left edge: lerp(322, 382, (456-240)/(780-240)) = 322 + 60*(216/540) = 322 + 24 = 346
  //   right edge: lerp(702, 642, (456-240)/(780-240)) = 702 - 60*(216/540) = 702 - 24 = 678
  final waterFill = [
    img.Point(346, 456), // water-line left
    img.Point(678, 456), // water-line right
    img.Point(642, 780), // bottom-right (same as glass)
    img.Point(382, 780), // bottom-left (same as glass)
  ];
  img.fillPolygon(image, vertices: waterFill, color: white);

  // Glass rim — a thin horizontal bar across the top for definition
  final rimBar = [
    img.Point(314, 230), // slightly wider than body
    img.Point(710, 230),
    img.Point(710, 250),
    img.Point(314, 250),
  ];
  img.fillPolygon(image, vertices: rimBar, color: white);
}
