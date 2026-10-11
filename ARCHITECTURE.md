# Spotter project guide

## Purpose and navigation

Spotter helps a user choose a strength workout, log sets quickly, and see progress. The four destinations in the bottom dock have distinct jobs:

- **Today**: resume an active session; otherwise start today's earliest plan; otherwise open quick start (saved workouts, last session, starters, custom). Weekly completion and one upcoming/last-workout context keep the page useful without becoming a dashboard of cards.
- **Plan**: a selected week with marked workout days and an independently scrolling day agenda. The month button opens a locale-aware calendar. Upcoming, overdue, active, and completed entries have text/symbol statuses; old plans are never silently marked missed. Selection survives tab changes.
- **Library**: reusable saved workouts, starter routines, and exercise content. No scheduled records appear here. Templates can be edited, used immediately, or copied into a dated plan.
- **Progress**: consistency, contained complete workout history, exercise trends, repeat, and saving a completed lineup as a template.

`App/SpotterRoute.swift` defines typed tabs and root sheet routes. `App/TabBar.swift` owns builder-to-session transitions, waiting for sheets to dismiss before presenting their destination. Feature-local sheets stay with the feature. `App/SpotterDock.swift` provides the sole bottom navigation: a compact glass capsule and separate quick-action menu, following Counter’s navigation pattern. The root reserves space with `safeAreaInset`; it does not overlay content with a second system tab bar. Plan selection and Library search are owned above the destination switch so they survive tab changes. Today no longer repeats generic Plan and Library shortcuts; its contextual upcoming-workout link remains useful.

## Shared organizational philosophy with Counter

Both apps use framework-native SwiftUI and observable stores. Neither needs a new dependency or a second view-model layer merely to match the other.

- `App`: composition, launch, navigation, presentation routing.
- `Design`: materials, wallpaper, generic layout and platform presentation components; shared brand tokens are in `Shared/SpotterStyle.swift`. No workout-specific rows or business calculations.
- `Models`: Core Data records, drafts/preferences, starter definitions, pure calendar/progress calculations.
- `Stores`: observable read state and validated, atomic data mutations.
- `Services`: opening/migrating the database, exporting data, and coordinating the local workout Live Activity.
- `Views/Today`, `Planning`, `Library`, `Progress`, `Settings`, `Workouts`: screen/feature UI and its local components. Workouts contains editors, session controls, history detail, and reusable workout rows/pickers.
- Project-root `Shared`: the small, nonisolated `WorkoutActivityAttributes` value contract compiled into the app and extension. No managed objects or app services belong here.
- Project-root `SpotterActivity`: a WidgetKit Live Activity extension with its own entry point, views, and Info.plist. The app target builds and embeds it.
- Project-root `SpotterWatch`: the watchOS companion with its own SwiftUI entry point, connection store, workout screen, and icon. It compiles the value-only `Shared/WatchWorkoutMessage.swift` contract and sends revision-checked commands to the iPhone store. See `Documentation/AppleWatch.md`.
- `Assets.xcassets`, versioned `spotter_.xcdatamodeld`, and target-level test directories remain in their standard Xcode locations. Filesystem-synchronized groups discover moved/new files without hand-maintained build lists.

Counter follows the same responsibility rules. Its Codable/UserDefaults/file persistence remains appropriate; Spotter retains Core Data for existing relationships, history, and migrations. Counter's ambiguous Dashboard group was distributed into Today, Meals, and Nutrition; Stats became Progress, and domain UI/calculations moved out of Design/views to their proper homes. No app data was deleted or reset.

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

`Models/WorkoutActivitySnapshot.swift` projects the active workout into plain values: workout identity/start, selected exercise and position, set counts, and an optional rest-end date. It never sends managed objects or workout notes to ActivityKit. `Shared/WorkoutActivityAttributes.swift` is the matching Codable contract. Its nonisolated types compile consistently in the app, which uses default MainActor isolation, and the extension.

`Services/WorkoutActivityCoordinator.swift` owns one local ActivityKit activity. Reconciliation coalesces state changes into an ordered worker, adopts an existing matching activity, removes duplicates, and ends the activity when the workout finishes, is discarded, or the preference is disabled. A successful request is remembered across launches so dismissing or system-ending an activity does not cause it to repeatedly reappear. Saving the preference off and then on provides an explicit restart. Availability or request failures do not interrupt workout saving.

The Lock Screen and Dynamic Island show the exercise, set progress, weight/reps, and rest countdown. One primary action logs the displayed set or ends rest; a secondary Undo corrects the last log. Completed planned sets link back to the app for the next exercise or workout review. Dates drive system-rendered timers while the app is suspended; rest stops at zero and is labeled “Rest timer.” iOS can defer layout changes at the deadline, so End Rest remains an explicit, reliable return to logging. There is no background timer, push server, App Group, or new data store. ActivityKit controls actual availability and lifetime.

Tapping the activity opens `spotter://workout/<UUID>`. `Models/SpotterDeepLink.swift` validates the route, the app buffers it through loading, and root routing resumes an active session or opens a completed session’s history. Invalid/missing workout IDs are ignored. The Lock Screen and expanded Dynamic Island also edit the real session through LiveActivityIntent buttons. See `Documentation/WorkoutInteractions.md` for persistence, concurrency, and platform behavior. No separate Home Screen widget is present.

The app Info.plist declares Live Activity support and the URL scheme. The embedded `SpotterActivity` target uses the existing development team and the `com.kevinlhn.spotter-.activity` bundle identifier. Its light/dark previews include logging and resting states.

## Design and verification

The supplied Spotter palette is centralized in `Shared/SpotterStyle.swift` for both targets. The atmospheric wallpaper and Liquid Glass remain. The UI pass consolidates icon sizing, headings, row spacing, quieter passive glass, stronger primary-action contrast, and reusable press feedback. The dock animates its selected destination; Reduce Motion removes the selection spring/press compression. Reduce Transparency and increased-contrast treatments remain in the shared surfaces. Subjective visual tuning stays separate from session logic.

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
