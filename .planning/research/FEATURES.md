# Feature Landscape

**Domain:** Water reminder / hydration tracker mobile app
**Researched:** 2026-06-03
**Confidence:** MEDIUM (based on competitor analysis of WaterMinder and Waterlogged official sites, 39+ open source hydration tracker projects on GitHub, and PROJECT.md confirmed requirements; web search was unavailable so user review sentiment draws on domain expertise)

## Table Stakes

Features users expect in any hydration tracker. Missing any of these and users uninstall within a day.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Daily water goal setting | Core purpose of the app; every competitor has this | Low | Already confirmed. Single global target is correct for v1 |
| Circular / visual progress indicator | Users need at-a-glance "how am I doing" without reading numbers; every major competitor uses a prominent visual (circle, wave, bar) | Medium | Already confirmed. Circular progress bar on home screen. Consider percent_indicator package or custom painter |
| Quick-add preset buttons | Logging must take < 2 seconds or users stop logging; preset cup sizes (250ml, 500ml, glass, bottle) are universal | Low | Already confirmed. Customizable amounts. 3-4 presets is the sweet spot |
| Reminder notifications | The "reminder" half of the value prop; without this it's just a manual log nobody uses | Medium | Already confirmed. Configurable interval via flutter_local_notifications with zonedSchedule |
| DND / quiet hours window | Nobody wants 3am hydration reminders; every serious competitor offers this | Low | Already confirmed. App-level time window filter on notification scheduling |
| Undo last entry | Fat-finger taps happen constantly with quick-add buttons; users rage-quit if they can't fix mistakes | Low | Already confirmed. Soft-delete or pop from today's entries |
| Calendar / history view | Users want to see multi-day patterns (did I drink enough this week?); color-coded calendar is the standard pattern | Medium | Already confirmed. Green (goal met) / red (goal missed) days via table_calendar |
| Persistent local data | Data must survive app restarts and phone reboots; losing a day's data is unforgivable | Low | Covered by Drift/SQLite. Table stakes for any tracker |
| Measurement unit preference | US users expect fl oz/cups, rest of world expects ml/L; not supporting both alienates half your audience | Low | **Not yet in requirements.** Critical to add. Settings toggle: metric (ml/L) or imperial (fl oz). Affects all display and preset labels |
| Today's intake log / timeline | Users want to see what they logged today (time + amount); builds trust in the data and helps identify dry periods | Low | **Not yet in requirements.** Show today's entries as a simple list below the progress bar (e.g., "8:15 AM -- 250ml, 10:30 AM -- 500ml") |

## Differentiators

Features that set Drinky Drinky apart. Not expected, but valued when present. These should be considered for v1 only if they don't jeopardize core quality.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Goal completion celebration | Dopamine hit when you reach 100%; WaterMinder and Waterlogged both do "celebration feedback." A small touch that makes daily completion feel rewarding | Low | Confetti animation or satisfying haptic pulse when progress bar hits 100%. Use HapticFeedback API (no extra package) |
| Animated water-fill progress | Delightful UI where the circle fills with a wave animation as you log; makes logging feel tangible | Medium | Custom painter wave animation inside circular indicator. Distinguishes from flat progress bars |
| Hydration streak counter | "You've hit your goal 7 days in a row!" -- gamification that drives retention without being obnoxious; Waterlogged prominently features streaks | Low | Derived from calendar data with a SQL query (consecutive days where intake >= target). Display on home screen or calendar view |
| Smart reminder suppression | Don't send a reminder if user recently logged water; basic interval reminders feel nagging when you just drank. WaterMinder calls these "smart reminders" | Medium | After logging, reset/postpone the next scheduled reminder. Requires notification rescheduling logic |
| Dark mode / theming | Many users expect dark mode; a "water blue" light theme + dark mode covers preferences well | Medium | Flutter + Material 3 has built-in dark mode support. Respect system theme setting at minimum |
| Haptic feedback on logging | Tactile confirmation that the tap registered; subtle but satisfying | Low | Flutter HapticFeedback API. No extra package needed. Add to quick-add button tap |
| Simple onboarding flow | First-launch experience that asks for unit preference and daily goal; without this, users land on an empty screen with no guidance | Low | **Common miss in open-source projects.** 2-3 screen flow: choose units, set goal (with suggestion), done |
| Data export (CSV) | Let users export their hydration history; appeals to health-conscious power users | Low | Simple CSV generation from Drift queries. Nice for trust ("your data, your control") |
| Home screen widget | Quick glance at progress without opening app; reduces friction to near zero; WaterMinder heavily promotes widgets | High | Requires platform-specific code (home_widget package for Android, WidgetKit for iOS). **Defer to v2** |
| Multiple drink types | Log coffee, tea, juice with hydration coefficients (coffee ~80% water); WaterMinder tracks this | Medium | Adds UI complexity (drink type picker). Nice but dilutes "water tracker" focus. **Defer to v2** |
| Weather-based goal adjustment | Increase daily target on hot days; Waterlogged shows weather, WaterMinder adjusts goals | High | Requires weather API, breaks offline-only constraint. **Defer to v2+** |
| Apple Health / Google Fit sync | Sync data with platform health stores; expected by fitness-focused users | High | Significant platform-specific integration work. **Defer to v2** per PROJECT.md |

## Anti-Features

Things to deliberately NOT build. These annoy users, add complexity, or dilute the app's focus.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Mandatory account creation / sign-up | Top uninstall trigger for utility apps. Users want to open and start, not create accounts. Every "simple" tracker that forces sign-up gets 1-star reviews | Stay offline-only. No accounts. No email. Already aligned with PROJECT.md |
| Social features / leaderboards | "Compare your hydration with friends!" -- nobody wants competitive water drinking. Adds backend complexity for zero retention benefit | Focus on personal tracking. Explicitly out of scope per PROJECT.md |
| Aggressive ads / interstitials | Full-screen ads after logging water destroy the UX. Hydration logging is a 2-second interaction that happens 8-10x a day | If monetizing later, use a one-time purchase. Skip monetization for v1 |
| Gamification with virtual pets / plants | Plant Nanny's approach (plant dies if you don't drink) creates guilt-based engagement. Polarizing mechanic that adds massive art/animation scope | Use streaks and celebrations -- positive reinforcement without guilt |
| Calorie / macro / meal tracking | Scope creep into nutrition tracking. Several GitHub projects tried this and became bloated. Drinky Drinky is a water tracker, not MyFitnessPal | Stay focused on hydration only. Out of scope per PROJECT.md |
| AI-powered recommendations | "AI suggests optimal hydration based on biometrics" -- marketing fluff that adds complexity without value for a simple tracker | Simple weight-based formula for goal suggestion is sufficient |
| Complex log editing (delete/edit arbitrary past entries) | Overcomplicates the UI for an infrequent need; adds modal dialogs, confirmation flows, edge cases with recalculating daily totals | Undo-last covers 95% of correction needs. Already decided in PROJECT.md |
| Overly granular notification settings | Per-day-of-week intervals, different morning/afternoon/evening schedules, custom messages per notification -- turns settings into a chore | Simple: interval (minutes) + DND window (start/end time). Two settings. Already confirmed |
| Per-day variable targets | Different goals for Monday vs Saturday adds data model and UX complexity for minimal benefit | Single global target. Already decided in PROJECT.md. Can revisit if validated need emerges |
| Manual free-text input per drink | Adds friction vs. preset buttons; edge case (odd amounts) not worth the UX cost | Configurable preset amounts cover 95% of use cases. Already decided |
| Cloud sync / backup in v1 | Requires backend infrastructure, authentication, conflict resolution. Massive scope increase | Defer. Consider local export/import as JSON in v2 for backup |

## Feature Dependencies

```
Measurement unit preference  (must exist before any amount is displayed or stored)
        |
        v
Daily goal setting  ------->  Circular progress bar (progress needs a target)
        |                              ^
        v                              |
Quick-add presets  -------->  Daily log entries (intake records in Drift)
        |                        |             |
        v                        v             v
Undo last entry           Today's timeline   Calendar view (aggregates daily data)
                                                |
                                                v
                                          Streak counter (consecutive green days)

Reminder notifications  --->  DND window (DND filters notification scheduling)
        |
        v
Smart reminder suppression (needs to know last log time from daily log)

Drift database setup  --->  All data features (presets, logging, calendar, streaks)
```

Key dependency chain:
1. **Drift database schema** -- everything depends on data persistence; set up first
2. **Unit preference** -- must be decided before any amounts are displayed or preset labels rendered
3. **Goal setting** -- must exist before progress bar is meaningful
4. **Quick-add logging** -- produces the data that everything else consumes
5. **Calendar view** -- depends on accumulated daily log data
6. **Streak counter** -- derived from calendar data (consecutive green days)
7. **Smart reminders** -- need access to the log to know "did user recently drink?"

## MVP Recommendation

### Phase 1 -- Foundation (Core Loop)
Ship the core "log and see progress" loop. User must be able to: set goal, log water, see progress, undo mistakes.

1. **Drift database schema** -- everything depends on data persistence
2. **Unit preference setting** (ml/L or fl oz) -- affects all display
3. **Daily goal setting** -- prerequisite for progress tracking
4. **Quick-add preset buttons** -- primary user interaction (customizable amounts)
5. **Circular progress bar** -- immediate visual feedback on home screen
6. **Today's intake timeline** -- show logged entries below progress bar
7. **Undo last entry** -- error recovery

### Phase 2 -- Engagement (Retention Drivers)
Ship notifications and history. This is what keeps users coming back after Day 1.

8. **Reminder notifications** with configurable interval
9. **DND window** for notifications
10. **Calendar view** with green/red color coding
11. **Streak counter** -- displayed on home or calendar screen
12. **Goal completion celebration** -- haptic + visual at 100%

### Phase 3 -- Polish
13. **Simple onboarding flow** -- first-launch unit/goal selection
14. **Dark mode** -- respect system theme
15. **Haptic feedback on logging** -- tactile confirmation
16. **Animated water-fill effect** -- wave animation in progress circle
17. **Smart reminder suppression** -- reset timer after logging

### Defer to v2+
- Home screen widget (high complexity, platform-specific)
- Multiple drink types (scope expansion)
- Health app integration (platform-specific APIs)
- Data export (low priority for launch)
- Weather-based goal adjustment (breaks offline constraint)
- Cloud sync / backup (requires backend)

## Insights from Competitor Analysis

**What WaterMinder gets right (market leader):**
- Extremely fast logging (< 2 taps from any state)
- Visual celebration on goal completion
- Smart reminders that adapt to logging behavior
- Multiple home screen layouts
- Widget support for zero-friction status checks
- Tracks multiple drink types with hydration coefficients
- Custom notification sounds

**What Waterlogged gets right:**
- Streaks prominently featured (retention driver)
- Container/bottle presets with photos
- "Celebrate every win" philosophy -- positive reinforcement
- Weather and location context displayed alongside progress

**What open-source projects commonly miss:**
- Onboarding flow (users land on empty screen with no guidance)
- Celebration/feedback on goal completion (just a number going up)
- Unit preference (hardcoded to one measurement system)
- Notification DND window (reminders fire at 3am)
- Today's timeline view (only show aggregate, not individual entries)

**The "2-second rule":**
Every hydration tracker lives or dies by logging speed. If it takes more than 2 seconds to log a glass of water, users stop logging within a week. The home screen must be optimized for: open app -> tap preset -> done. Everything else is secondary to this core loop.

## Sources

- WaterMinder official website (waterminder.com) -- comprehensive feature list [MEDIUM confidence]
- Waterlogged official website (waterlogged.com) -- feature list and positioning [MEDIUM confidence]
- GitHub topics: hydration-tracker (11 repos), water-tracker (28 repos), water-reminder (10+ repos) -- feature patterns across open source [MEDIUM confidence]
- PROJECT.md -- confirmed requirements and constraints [HIGH confidence]
- Domain expertise on mobile utility app UX patterns [LOW-MEDIUM confidence]
