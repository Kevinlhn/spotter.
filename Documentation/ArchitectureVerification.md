# Architecture refactor verification — October 11, 2026

## Implemented

All three applications now use `App/Application`, `App/Core/DesignSystem`, `App/Features`, `App/Models`, `App/Stores`, `App/Services`, `App/Persistence`, `App/Resources`, and `App/Configuration`. Optional Components, Formatting, feature Logic, and PreviewContent folders exist only where used. Tests are in `Tests/Unit` and `Tests/UI`; platform targets use `Extensions/<Kind>` and contracts use `Shared/<Concern>`.

Moved 225 files (Tracker 33, Counter 95, Spotter 97), with byte-for-byte verification before focused consolidation. Existing uncommitted work was preserved; no Git reset, staging, commit, user-data migration, or deletion was performed. Working-file backups and a hashed move manifest are at `/tmp/unified-architecture-before-20261011` (temporary recovery aid, not a permanent archive).

- Tracker: separated application, navigation, dock, reusable components, wallpaper/page, and money/date formatting. Currency formatter reuse is bounded to one locale/currency pair and main-actor isolated. Regression test verifies currency switching, signs, zero, and fraction digits.
- Counter: separated coaching card and coaching screen; consolidated protected JSON writes. Existing filenames, migration verification, schema checks, atomic writes, protection, and backup exclusion are preserved.
- Spotter: extracted WeekRhythm, separated preview fixtures, centralized container/context setup, and removed unreferenced fatal save wrappers. Existing synchronous test loading and asynchronous production loading remain.

## Results

Xcode Debug iOS Simulator builds passed for Tracker, Counter (including CounterWidgets), and Spotter (including SpotterActivity and SpotterWatch). The test invocations rebuilt the final consolidation changes. Tests ran serially on iPhone 17 Pro / iOS 26.0 with signing disabled and isolated test fixtures.

| App | Unit tests | UI verification |
| --- | ---: | --- |
| Tracker | 27 passed | Main pages in light and dark passed |
| Counter | 81 passed | Main surfaces/settings in both appearances and measured meal entry passed |
| Spotter | 77 passed | Start, resume, complete, and repeat workout passed |

Total: 185 unit tests and four UI test methods passed. Persistence coverage includes legacy migration, failure handling, snapshot publication, planning, and workout commands.

One additional Counter UI test, `testCompactMainPagesLightAndDark`, failed because it expects `today-log-meal`. That identifier was already absent from the pre-refactor HomeView and TodayEnergyCard; both files remain byte-for-byte identical to the backup. The obsolete test remains unchanged and needs a separate update to the current Today interaction contract. Current navigation/settings/meal-entry checks pass; the failure was not hidden by changing production UI.

All three project files pass `plutil -lint`; `git diff --check` passes. Asset catalogs, entitlements, Info.plists, and Core Data model versions match their pre-refactor bytes. Product identifiers, module/product names, platform deployment versions, actor-isolation settings, and signing teams were compared with the originals and preserved.

## Limits and intentional differences

- Full UI suites, physical-device signing, camera/Health integration, actual Home Screen Clear/Tinted rendering, and paired Watch connectivity were not rerun. Extension/Watch compilation and packaging were verified; this is not an end-to-end device check.
- Release builds were not rerun in this pass; older Release results elsewhere in the guides are historical.
- Existing Spotter preference tests emit two Swift 6 actor-isolation warnings under the current Swift 5 language setting; all 77 unit tests pass. App Intents metadata-skipped warnings remain on targets that do not use AppIntents.
- Codable versus Core Data storage, app-specific stores/navigation, and extension capabilities remain intentionally different. Equivalent responsibilities have equivalent locations; no new cross-app package or mandatory view-model layer was introduced.
- Larger single-responsibility feature views remain together. Further feature-specific optimization should be driven by profiling or demonstrated duplication, rather than file length.

Evidence: `/tmp/unified-{tracker,counter,spotter}-build.log`, `/tmp/unified-{tracker,counter,spotter}-tests.xcresult`, and `/tmp/unified-counter-ui-current.xcresult`.
