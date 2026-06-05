# Phase 5: Notifications - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-05
**Phase:** 5-notifications
**Areas discussed:** Permission screen placement, Scheduling strategy, Goal-reached cancellation, Notification message content

---

## Permission Screen Placement

| Option | Description | Selected |
|--------|-------------|----------|
| On first app launch (Recommended) | Show before the user sees anything else. Gets permission out of the way immediately. | ✓ |
| When entering Settings for the first time | Show only when the user navigates to Settings and hasn't granted permission yet. | |
| On demand, from a banner in Settings | Show only when user taps 'Enable notifications' in the Notifications card. | |

**User's choice:** On first app launch.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Go straight to Home tab (Recommended) | After granting or denying, dismiss the screen and land on Home. | |
| Show a confirmation and then go to Home | Show a brief message ('Reminders enabled!' or 'You can enable later') before navigating to Home. | ✓ |
| You decide | Leave this detail to the planner. | |

**User's choice:** Show a confirmation message after grant/deny, then go to Home.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Show a subtle banner in Settings (Recommended) | If permission was denied, show a small info card in the Notifications section. | ✓ |
| Nothing — silent denial | App works fine without notifications; don't mention it again. | |
| You decide | Leave this to the planner. | |

**User's choice:** Subtle banner in Settings if permission was denied.

---

## Scheduling Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Rolling window — schedule next 4 days of slots (Recommended) | Cancel all + recompute next 4 days + zonedSchedule(). Handles iOS 64-limit and DST. | ✓ |
| Full-day pre-schedule — today's slots only | Schedule only today's remaining slots on each app open or midnight reset. | |
| You decide | Let the planner figure out the exact window within iOS limits. | |

**User's choice:** Rolling window — next 4 days of slots.

---

| Option | Description | Selected |
|--------|-------------|----------|
| App foreground (Recommended) | Every time the app resumes from background via AppLifecycleListener. Also reschedule when settings change. | ✓ |
| App open + periodic timer | Same as above plus a periodic timer inside the app that refreshes hourly. | |
| You decide | Let the planner pick the trigger points. | |

**User's choice:** App foreground (AppLifecycleResumed) + when settings change.

---

## Goal-Reached Cancellation

| Option | Description | Selected |
|--------|-------------|----------|
| Reactive — cancel from HomeScreen when total >= target (Recommended) | HomeScreen watches todayTotalProvider; add ref.listen to call cancelAll() when total crosses target. | ✓ |
| On foreground resume — check and cancel if goal met today | On every app foreground, check total >= target; if yes, cancel all pending. | |
| You decide | Let the planner decide the exact detection mechanism. | |

**User's choice:** Reactive detection via ref.listen in HomeScreen.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — reschedule on app open next day (Recommended) | Rolling window foreground reschedule handles this automatically on next morning's app open. | ✓ |
| Yes — also reschedule at midnight proactively | Additionally trigger reschedule at midnight even if app is open. | |
| You decide | Let the planner figure out the midnight resume logic. | |

**User's choice:** Next-day resume via foreground reschedule (no extra midnight trigger needed).

---

## Notification Message Content

| Option | Description | Selected |
|--------|-------------|----------|
| Static copy — 'Time to drink water! 💧' (Recommended) | Simple, always the same. Scheduled notifications can't fetch live data reliably. | ✓ |
| Semi-dynamic — title with app name, body fixed | 'Drinky Drinky' as title, 'Time to drink water!' as body. More branded. | |
| You decide | Let the planner choose the exact copy. | |

**User's choice:** Static copy. Title: "Drinky Drinky", Body: "Time to drink water! 💧"

---

## Claude's Discretion

- Exact `NotificationDetails` payload (large icon, sound, vibration) — use platform defaults
- iOS `DarwinNotificationDetails` options (badge, alert, sound) — set all to `true`
- Android `Priority.high` for notification importance
- `permissionScreenShown` SharedPreferences key name
- Whether to use `permission_handler` or `flutter_local_notifications` native permission request — planner picks based on research
- Sequential notification IDs starting at 1000
- Cap at 64 total slots (not a fixed 4-day window) to handle short intervals

## Deferred Ideas

None — discussion stayed within phase scope.
