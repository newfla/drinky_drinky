# Requirements: Drinky Drinky v1.1 Polish & UX

*Created: 2026-06-08. Scoped requirements for milestone v1.1.*

---

## Milestone v1.1 Requirements

### Home Screen Polish

- [ ] **HOME-01**: User sees goal and current intake on the home screen expressed in liters with locale-aware decimal formatting (e.g. "1,75 L / 2,00 L" on Italian devices)
- [ ] **HOME-02**: SnackBar undo notification auto-dismisses after 5 seconds and does not persist indefinitely

### Theming

- [ ] **THEME-01**: App uses Material You dynamic color on Android 12+, derived from the device wallpaper
- [ ] **THEME-02**: App falls back to a static blue seed palette on Android <12; iOS retains the existing static palette unchanged
- [ ] **THEME-03**: App supports system dark mode; all screens adapt correctly, including semantic colors (goal-met green, goal-missed red, partial orange)

### Intake Redesign

- [ ] **INTAKE-01**: Home screen quick-add buttons are removed; a FAB opens the add-intake interface
- [ ] **INTAKE-02**: Add-intake modal bottom sheet displays 3 configurable preset buttons (reduced from 4)
- [ ] **INTAKE-03**: Add-intake sheet includes a custom ml text field with numeric keyboard; submitting adds the entry and closes the sheet
- [ ] **INTAKE-04**: Settings screen preset editing is reduced to 3 configurable slots; the 4th preset slot is retired

### App Icon

- [ ] **ICON-01**: App uses a water glass motif icon across all required iOS and Android launcher sizes; iOS variant has an opaque background (no alpha channel)

---

## Future Requirements

- Dark mode semantic color refinement (if auto-adaptation is insufficient for THEME-03)
- fl oz unit support — deferred to v2 (European market focus for v1)
- Full locale formatting for settings values — defer to v1.2
- Apple Health / Google Fit integration — v2
- Smart/adaptive reminder timing — v2

## Out of Scope for v1.1

- Variable per-day targets — single global target for simplicity
- Detailed log editing (delete arbitrary past entries) — undo last is sufficient
- Social / sharing features — personal tracking focus
- Backend / cloud sync — offline-first
- fl oz unit support — ml/L for v1; European market focus

## Traceability

| REQ-ID | Phase | Notes |
|--------|-------|-------|
| HOME-01 | Phase 6 | L-display with intl.NumberFormat locale-aware formatting |
| HOME-02 | Phase 6 | SnackBar persist: false fix (Flutter 3.38+ breaking change) |
| THEME-01 | Phase 6 | DynamicColorBuilder wraps MaterialApp.router; dynamic_color ^1.8.1 |
| THEME-02 | Phase 6 | Static blue seed fallback via ColorScheme.fromSeed when dynamic is null |
| THEME-03 | Phase 6 | darkTheme from dynamic/seed; audit hardcoded semantic colors for contrast |
| INTAKE-01 | Phase 7 | FAB on inner HomeScreen Scaffold; remove inline quick-add Row |
| INTAKE-02 | Phase 7 | Modal bottom sheet with 3 presets from DrinkPresets table (take 3) |
| INTAKE-03 | Phase 7 | Custom ml TextField in sheet; numeric keyboard; submit logs + closes |
| INTAKE-04 | Phase 7 | Settings preset editing reduced to 3 slots; 4th slot retired at UI layer |
| ICON-01 | Phase 8 | flutter_launcher_icons config; opaque PNG for iOS; adaptive for Android 8+ |
