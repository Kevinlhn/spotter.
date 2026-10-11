# Spotter remaining work — October 3, 2026

The functionality/organization and UI/Live Activity passes are complete and applied to the actual Spotter project. Existing user data and unrelated Git changes are preserved.

## Completed functionality and organization pass
- [x] Inspected Spotter and Counter before choosing a common organizational philosophy.
- [x] Organized Spotter UI into Today, Planning, Library, Progress, Settings, and Workouts; moved persistence/export into Services and domain calculations into Models.
- [x] Organized Counter's ambiguous Dashboard/Stats files into Today, Meals, Nutrition, and Progress; extracted domain UI from Design without changing Counter behavior.
- [x] Added contextual Today quick start/resume, separate Plan and Library tabs, reusable templates, and weekly/monthly calendar navigation.
- [x] Preserved assigned plan dates through start/completion with a V4 migration; templates copy independently and retain no logged sets.
- [x] Added stable page shells and contained lists; retained input identity when the keyboard opens; provided accessible calendar/day-list layouts.
- [x] Reorganized Settings into reusable destinations sharing one Save/Cancel draft; export now includes templates, exercise library, assigned dates, and set timestamps.
- [x] Centralized root presentation routes and made full action rows tappable.
- [x] Applied all changes to the actual projects with backups, without removing user data or resetting existing Git changes.

## Completed functionality/organization verification
- Spotter: 31 unit tests pass, including real SQLite V1/V2/V3 migrations to V4, template isolation, calendar/DST calculations, preferences, export, and workout lifecycle.
- Five Spotter UI flows pass across iPhone SE (3rd generation) and iPhone 16e: quick start/keyboard/resume/complete/history/repeat/trends; template/calendar separation and completion; Settings draft/back/cancel/save; targets/discard; largest accessibility text navigation.
- The combined UI run exposed a button hit-target issue; its corrected full navigation flow passed in the final targeted run. A stalled simulator launch was stopped and the same built test was run successfully on the working simulator.
- Both projects pass Release simulator builds. Only Xcode's standard skipped App Intents metadata extraction warning remains.
- Screenshot inspection checked normal light/dark and small-phone accessibility layouts. Source comparison confirms installed Spotter files match tested staging; both repositories pass git diff --check.
- Counter changes are structural only; its full UI suite was not rerun in this pass.

## Implemented UI and Live Activity work
- [x] Replaced the system tab bar with a Counter-style glass capsule dock and separate quick-action menu, reserved through the safe area.
- [x] Removed the redundant Today Plan/Library shortcuts; retained the primary workout action and contextual workout link.
- [x] Kept Library search and calendar selection above the destination switch so tab changes preserve them.
- [x] Refined shared spacing, typography, row icons, passive/primary glass balance, and reduced-motion-aware press/selection feedback.
- [x] Added the embedded `SpotterActivity` target and project-root `Shared` model contract.
- [x] Added Lock Screen/Dynamic Island exercise and set progress, elapsed time, date-driven rest countdown, and tap-to-resume routing.
- [x] Added a Live Activity Settings destination with shared draft behavior, availability feedback, and explicit off/on restart after dismissal.
- [x] Kept the implementation local: no push service, App Group, background timer, data migration, or Home Screen widget.
- [x] Applied 34 changed files to the actual project with baseline-hash checks and a backup at `/private/tmp/spotter-before-live-polish`.

## UI and Live Activity verification
- Integrated Debug app/extension simulator build passes.
- 40 unit tests pass, including activity snapshot/deep-link values and preference defaults.
- Six distinct main UI flows pass across iPhone 16e, iPhone 17, and iPhone SE (3rd generation) simulators: quick start/resume/completion; calendar/template separation; Settings draft/back/cancel/save; targets/discard; accessibility navigation; and dock quick-action menus. Coverage also checks the custom dock, removal of redundant Today shortcuts, and preserved Library search.
- Two real ActivityKit flows pass on the iPhone 17 simulator: start/status, background/foreground retention, preference off/on restoration, and completion cleanup; plus rendered system-card content and tap-to-resume from both Dynamic Island and the larger card, retaining the logged set.
- The Settings activity-coordinator environment injection crash is fixed and its UI flow passes. The toggle interaction test targets the actual trailing switch.
- The actual project passes a Release build for a generic iOS device with `CODE_SIGNING_ALLOWED=NO`. `SpotterActivity.appex` is embedded, app/extension versions match (1.0/1), `NSSupportsLiveActivities` is true, and the spotter URL scheme is present. Device signing and installation have not been verified.
- Reviewed light/dark app screens, accessibility layouts, the steady-state Dynamic Island rest countdown, and the larger system activity card. All changed/new actual project files match the tested staging; `git diff --check` passes.

## Must finish
- None identified for this pass. No known unresolved regression remains from these changes.

## Should finish
- Physical-device Live Activity checks: Lock Screen and Dynamic Island presentation/tap-to-resume, app cold launch, background rest reaching zero, system swipe-dismiss without unwanted recreation, and long-session/system time limits. Simulator coverage does not replace these checks.
- VoiceOver reading order and timer announcements, plus Reduce Motion/Transparency and large-text review on the dock and system activity surfaces.
- A separate Counter reliability pass could expose storage-decode failures through a recovery screen; this pre-existing behavior still logs failures.
- Optional export import/restore if a round-trip backup workflow becomes a product requirement. Export currently documents that import and preference backup are unsupported.

## Can polish manually later
- Further subjective spacing, typography, glass intensity, icon sizing, calendar-marker, and animation-timing adjustments. The shared components already received a first refinement pass.
- Additional starter content, a Home Screen widget, or optional reminder/Health/calendar integrations as separate feature work.

## Data limits
- Old completed workouts cannot recover assigned dates that earlier app versions already overwrote. Their actual history dates are preserved; new plans retain both dates.
- Existing units remain unchanged; no historic unit is guessed or silently converted.

## October 9 — three-priority implementation

- [x] Shared supplied palette across app and Live Activity, consistent icon treatment, and opaque light/dark/tinted Counter-family Spotter icons.
- [x] Real interactive Live Activity controls backed by the existing training store; persisted inputs/cursor/rest deadline and transaction revision; duplicate and stale action protection.
- [x] Deterministic local progression recommendations in planning and active workouts, with completed-only history, baseline, explanations, confidence, optional acceptance, unit conversion, and conservative equipment steps.
- [x] V1–V5 SQLite migrations tested against V6, retaining history. No App Group store relocation or cloud service.
- [x] 61 unit tests pass. Main workout flow, optional recommendation acceptance, and actual system-card weight/log controls pass simulator UI tests.
- [x] Final system-card screenshot inspected; controls fit within the 160-point layout. Icon assets verified as opaque 1024×1024.

Remaining verification: physical-device signing/installation, cold background launch after system termination, force-quit behavior, authentication before first unlock, VoiceOver, and iOS-imposed activity duration. Simulator interaction tests verify foreground/background state round trips, not all physical-device lifecycle conditions. Compact/minimal Dynamic Island remains status plus app navigation; expanded Island and Lock Screen provide buttons.

Implementation details: `Documentation/WorkoutInteractions.md`, `Documentation/ProgressiveOverload.md`, and `Documentation/IconAssets.md`.

Final verification: device Release build succeeded with code signing disabled, including the embedded SpotterActivity extension. The final validated-string intent passes the real system-card interaction test. All three icon appearance references resolve to opaque assets.

## October 10 — family icons, adaptive next sets, simpler activity

- [x] Installed matching Tracker and Counter light/dark/tinted icons using their established green and oxblood palettes. Brightened the letter faces of all three apps' dark icons, preserving the embossed family treatment. Opaque 1024×1024 assets and 64-pixel readability checked; Tracker/Counter asset compilation passes.
- [x] Added local next-set guidance using planned targets and current performance, including missed targets, fatigue, mixed loads, bodyweight, first-time exercises, and equipment steps. It recalculates after logs/edits/undo, offers explicit application beside entry controls, preserves manual input, and separates next-set advice from next-workout progression.
- [x] Replaced Live Activity editing/navigation toolbars with Log Set, End Rest, and a quiet Undo action. Tapping content opens the saved session. Preserved persisted state, revision protection, and absolute rest deadlines. Fixed the Lock Screen background resolving in a different appearance from its text.
- [x] 69 unit tests pass. Two adaptive-suggestion UI flows and two final real system-card UI flows pass, including countdown expiry while backgrounded and confirmation of the same saved sets in the app.
- [x] Final device Release build passes with signing disabled. Inspected the actual ready/resting Lock Screen card and compact/expanded Dynamic Island. Whitespace validation passes.

Platform limits: iOS may leave the rest layout showing 0:00 until another update; End Rest safely returns to logging without logging a set. Minimal Island has a dedicated preview but was not exercised with two concurrent system activities. Physical-device signing, lifecycle, and VoiceOver checks listed above remain outstanding. Existing user data and unrelated work are preserved.

Icon prompts and installed catalog locations: `Documentation/FamilyIcons.md`. Coaching behavior: `Documentation/ProgressiveOverload.md`. Activity behavior and verification: `Documentation/WorkoutInteractions.md`.

## October 10 — Apple Watch companion

- [x] Added an embedded watchOS 26 companion with the current exercise, progress, next-set target, Log Set, and an absolute-deadline rest countdown. Secondary controls provide equipment-aware adjustments, undo, and exercise navigation.
- [x] Connected Watch commands to the existing iPhone workout store and Live Activity updates. Preserved revision checks, duplicate protection, and persisted workout data. Disconnected Watch controls cannot queue mutations for later replay.
- [x] Added iPhone Settings → Apple Watch connection status and setup guidance, shared message contracts, and eight command/protocol tests.
- [x] Watch simulator and combined unsigned device Release builds pass. The existing 69 unit tests and eight Watch tests pass across their respective runs; whitespace validation passes.
- [x] Verified actual paired-simulator synchronization, Watch logging, rest countdown/expiry, and undo reflected on iPhone. Inspected ready/rest/adjustment screens on the 42 mm Watch and fixed the bodyweight target wrapping into the primary action's space.

Remaining platform checks: physical-device signing, installation, haptics, VoiceOver, and lifecycle/reconnection behavior. A final background-phone interaction attempt was blocked by simulator window-control errors. This companion requires a reachable iPhone to save changes; independent workouts, HealthKit metrics, complications, and guaranteed background rest alerts are outside this version. See `Documentation/AppleWatch.md`.
