# Spotter project guide

## Purpose and navigation

Spotter helps a user choose a strength workout, log sets quickly, and see progress. The four destinations in the bottom dock have distinct jobs:

- **Today**: resume an active session; otherwise start today's earliest plan; otherwise open quick start (saved workouts, last session, starters, custom). Weekly completion and one upcoming/last-workout context keep the page useful without becoming a dashboard of cards.
- **Plan**: Schedule and Routines sections; reusable templates/starters are edited, duplicated, started, or scheduled here. Schedule shows a selected week with marked workout days and an independently scrolling day agenda. The month button opens a locale-aware calendar. Upcoming, overdue, active, and completed entries have text/symbol statuses; old plans are never silently marked missed. Selection survives tab changes.
- **Library**: one exercise catalog for browsing, muscle/custom filters, technique, history, performance, and custom exercise editing. The workout builder reuses the same browser.
- **Progress**: consistency, contained complete workout history, exercise trends, repeat, and saving a completed lineup as a template.

`App/Application/SpotterRoute.swift` defines typed tabs and root sheet routes. `App/Application/TabBar.swift` owns builder-to-session transitions, waiting for sheets to dismiss before presenting their destination. Feature-local sheets stay with the feature. `App/Application/SpotterDock.swift` provides the sole bottom navigation: a compact glass capsule and separate quick-action menu, following Counter’s navigation pattern. The root reserves space with `safeAreaInset`; it does not overlay content with a second system tab bar. Plan selection and Library search are owned above the destination switch so they survive tab changes. Today no longer repeats generic Plan and Library shortcuts; its contextual upcoming-workout link remains useful.

## Unified architecture — October 11, 2026

Tracker, Counter, and Spotter use the same source layout and responsibility rules:

```text
App/
  Application/         Entry point, dependency ownership, navigation, routing
  Core/DesignSystem/   App-specific colors, typography, surfaces, wallpaper
  Core/Components/     Shared, domain-independent UI (when needed)
  Core/Formatting/     Reusable formatting and parsing (when needed)
  Features/<Feature>/  Screens, editors, and closely related components
    Logic/             Feature-specific calculations (when needed)
  Models/              Shared domain records, value types, pure calculations
  Stores/              Observable state and validated mutations
  Services/            External integrations and lifecycle coordination
  Persistence/         Storage, codecs, migrations, database setup
  Resources/           Assets, model versions, preview fixtures
  Configuration/       Info.plist and entitlements
Extensions/<Kind>/     Widgets, LiveActivities, or Watch targets that exist
Shared/<Concern>/      Contracts/tokens compiled into multiple targets
Tests/Unit/            Existing unit target
Tests/UI/              Existing UI target
```

Only folders with real responsibilities exist. Feature UI stays directly under its feature; use a nested folder only for a distinct responsibility. Reusable domain components stay with their feature. A large file is split by responsibility, not by line count.

App roots own dependencies; observable stores own mutations and published state; views own presentation state and editable drafts. Existing typed navigation and environment injection stay native to SwiftUI. Keep UI updates on the main actor and framework-specific concurrency in services. Do not add a view-model or repository for every screen.

Target names, product/module identifiers, bundle identifiers, persistence locations, model versions, and record schemas are unchanged. Separate synchronized Xcode roots keep extensions and shared files out of unintended targets. Cross-target exceptions and explicit source references are updated alongside physical paths. Watch follows Application, Features, Stores, and Resources conventions within its target root.

There is no cross-app package: branding, protected-storage policies, migration behavior, and business rules differ. Each app retains one source of truth for its own state and design; share across products only when behavior is identical and maintenance benefits justify the dependency.

## Persistence and lifecycle

`TrainingStore` is the mutation owner, including set edits/deletions. Views edit local drafts; cancelling a builder or Settings creates no records and commits no preferences. Failed Core Data saves roll back and report errors. A single active session is enforced.

Workout records have separate `template`, `scheduled`, `active`, and `completed` states. Templates have reusable exercises/targets/rest but no logged sets or assigned day. Using or repeating content creates fresh workout and exercise IDs. Deleting a template cannot delete sessions made from it.

Core Data V4 adds optional `scheduledDate`. A scheduled instance retains its assigned day after start changes `date` to the actual session date. Calendar uses assigned day (or actual day for spontaneous sessions); Progress uses actual session date. Rescheduling changes the assigned day. V1, V2, and V3 models remain bundled for lightweight migrations. Old completed records cannot recover originally assigned dates that earlier versions overwrote; their actual history dates remain intact.

Per-exercise rest nil/-1 follows the global preference; zero disables it. New sessions reset any previous rest countdown. Existing weight units remain unchanged; legacy unspecified units are not guessed or silently converted.

## Layout and settings

`FeaturePage` preserves a stable header and navigation while list/form regions scroll. Today uses `CompactContent`: it fits the viewport normally and scrolls only its content region when text size/height requires it. Session logging keeps the logger visible above its set list at normal heights; keyboard, short-height, and large-text fallback scrolls the content region below the stable exercise header. Editors use native lists/forms under fixed navigation/actions. No fixed screen heights or hidden duplicate tab bars are used. The dock reserves bottom space at the root, while the full-screen workout logger and its keyboard layout remain independent of the dock.

Settings is a navigation menu with Workout preferences, Units, Appearance, Live Activity, Apple Watch, Data & privacy, and About. Root presentations explicitly inject the shared activity coordinator so nested Settings destinations use the same lifecycle state as the main app. All preference destinations share one typed `TrainingPreferences` draft; going back never reloads/discards changes. Save applies it once, Cancel discards it, and appearance applies only on Save. The Live Activity destination participates in the same Save/Cancel draft and explains availability, local behavior, and system dismissal. Apple Watch reports connection status and explains the companion workflow; it has no draft preferences. Unsupported account and notifications categories are not presented.

JSON export version 3 includes scheduled dates, status, units, targets, rest, notes, ordered sets with timestamps, a separate templates array, and custom exercise-library entries. It regenerates on each share. Preferences are not exported and import is not currently supported; Settings explains both.

## Workout Live Activity

`App/Models/WorkoutActivitySnapshot.swift` projects the active workout into plain values: workout identity/start, selected exercise and position, set counts, and an optional rest-end date. It never sends managed objects or workout notes to ActivityKit. `Shared/LiveActivities/WorkoutActivityAttributes.swift` is the matching Codable contract. Its nonisolated types compile consistently in the app, which uses default MainActor isolation, and the extension.

`App/Services/WorkoutActivityCoordinator.swift` owns one local ActivityKit activity. Reconciliation coalesces state changes into an ordered worker, adopts an existing matching activity, removes duplicates, and ends the activity when the workout finishes, is discarded, or the preference is disabled. A successful request is remembered across launches so dismissing or system-ending an activity does not cause it to repeatedly reappear. Saving the preference off and then on provides an explicit restart. Availability or request failures do not interrupt workout saving.

The Lock Screen and Dynamic Island show the exercise, set progress, weight/reps, and rest countdown. One primary action logs the displayed set or ends rest; a secondary Undo corrects the last log. Completed planned sets link back to the app for the next exercise or workout review. Dates drive system-rendered timers while the app is suspended; rest stops at zero and is labeled “Rest timer.” iOS can defer layout changes at the deadline, so End Rest remains an explicit, reliable return to logging. There is no background timer, push server, App Group, or new data store. ActivityKit controls actual availability and lifetime.

Tapping the activity opens `spotter://workout/<UUID>`. `App/Models/SpotterDeepLink.swift` validates the route, the app buffers it through loading, and root routing resumes an active session or opens a completed session’s history. Invalid/missing workout IDs are ignored. The Lock Screen and expanded Dynamic Island also edit the real session through LiveActivityIntent buttons. See `Documentation/WorkoutInteractions.md` for persistence, concurrency, and platform behavior. No separate Home Screen widget is present.

The app Info.plist declares Live Activity support and the URL scheme. The embedded `SpotterActivity` target uses the existing development team and the `com.kevinlhn.spotter-.activity` bundle identifier. Its light/dark previews include logging and resting states.

## Design and verification

The supplied Spotter palette is centralized in `Shared/DesignSystem/SpotterStyle.swift` for both targets. The atmospheric wallpaper and Liquid Glass remain. The UI pass consolidates icon sizing, headings, row spacing, quieter passive glass, stronger primary-action contrast, and reusable press feedback. The dock animates its selected destination; Reduce Motion removes the selection spring/press compression. Reduce Transparency and increased-contrast treatments remain in the shared surfaces. Subjective visual tuning stays separate from session logic.

`UI_TESTING` uses an isolated in-memory Core Data store and freezes decorative animation. Unit coverage includes lifecycle, rollback-safe validation, template independence, calendar/DST/week starts, plan retention, preference drafts, export, and real V1/V2/V3 SQLite migrations. UI coverage exercises quick start/resume/completion, calendar/template separation, Settings draft navigation, targets/discard, keyboard logging, and accessibility navigation. See `REMAINING_WORK.md` for verification outcomes and deliberately deferred work.

## Completed architecture-pass verification — October 2, 2026

31 unit tests and five UI flows passed across small and regular iPhone simulators after fixes for keyboard identity, accessibility width, and full-row hit targets. Both apps pass Release simulator builds; Counter's source-only moves did not require repeating its full UI suite. At completion of that architecture pass, the actual Spotter source matched its tested staging. Physical-device/VoiceOver follow-ups and optional features are listed in `REMAINING_WORK.md`.


## UI and Live Activity pass — October 2, 2026

40 unit tests pass, including activity snapshot/deep-link values and preference defaults. Six distinct main UI flows pass across iPhone 16e, iPhone 17, and iPhone SE (3rd generation) simulators: quick start/resume/completion; calendar/template separation; Settings draft navigation/cancel/save; targets/discard; accessibility navigation; and dock quick-action menus. Coverage includes removal of redundant Today navigation and preserved Library search. The Settings activity-coordinator environment injection issue was fixed and its flow passed; the toggle test targets the actual trailing switch.

Two additional iPhone 17 simulator flows opt into real ActivityKit. They pass activity creation/status, background/foreground retention, preference off/on restoration, and completion cleanup; a system-surface flow verifies the rendered card and that tapping either the Dynamic Island or the larger activity card reopens the saved session with its logged set intact. Steady-state screenshots verify the visible rest countdown and the larger system card. These checks do not replace physical-device testing.

The actual Spotter project passes a Release build for a generic iOS device with code signing disabled. The built app embeds `SpotterActivity.appex`; app and extension versions match (1.0/1), Live Activity support is present, and the spotter URL scheme is registered. This verifies compilation/packaging, not device signing or installation. The integrated Debug simulator build also passes.

34 changed/new files were applied to the actual project using baseline-hash checks and a backup at `/private/tmp/spotter-before-live-polish`. Final test/documentation edits are synchronized, and the actual project matches tested staging. Light/dark app, accessibility, Dynamic Island, and larger system-card screenshots were reviewed. Physical-device signing/installation, cold launch, system dismissal, long background sessions, and VoiceOver remain follow-ups in `REMAINING_WORK.md`.

## October 9: palette, interactive workouts, local progression

Shared theme tokens now cover light/dark surfaces, text, brand, metrics, and status colors. Counter-family Spotter icon variants are bundled in the app catalog. V5 adds transactional workout session state; V6 adds planned load and rep-range minimums. Existing models and records are retained.

`WorkoutRuntime` supplies one training store to foreground launch and background intents. `ProgressiveOverloadEngine` provides deterministic recommendations through a shared planning/session suggestion view. See `Documentation/WorkoutInteractions.md` and `Documentation/ProgressiveOverload.md` for rules, architecture, and limitations.

The refinement adds `NextSetGuidance` for adaptive set-to-set targets: respond to missed reps, rep drops, changed loads, and completed planned sets. Active performance remains separate from completed historical progression. The shared suggestion view labels Next set versus Next workout, explains the action inline, and only changes inputs when accepted. All three family apps now have matching icon artwork; dark letter faces were brightened using their existing pale brand accents. See `Documentation/FamilyIcons.md` for installed catalogs and generation prompts.

## Architecture refactor — October 11, 2026

WeekRhythm is a feature-owned component. Preview fixtures are separated from production database setup. Synchronous and asynchronous loading share container/context configuration; unreferenced fatal save wrappers were removed after checking all source and target references. TrainingStore remains the mutation owner. Watch and Live Activity packaging are retained.

Verification results are recorded in `Documentation/ArchitectureVerification.md`.

## Training refinement — October 11, 2026

`ExerciseCatalog`/`ExerciseBrowser` centralize exercise selection. `TrainingProgress` adds read-only historical insights; `CoachingPreferences` joins the existing settings draft and drives the shared progression engine and reviewable routine suggestions. Watch uses viewport-sized screens and an explicit atomic target command. See `Documentation/TrainingRefinement.md` for behavior, data limits, and verification.
