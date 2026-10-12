# Exercise library, planning, fast Watch controls, and coaching

## Information architecture

Library is the exercise catalog: name/muscle search, muscle and custom filters, technique, recent sets, performance detail, and custom exercise creation/editing. The workout builder uses the same `ExerciseBrowser` and `ExerciseCatalog`. The catalog includes saved custom exercises, starter exercises, and names from existing workouts. Renaming a custom library entry never rewrites historical workouts; the editor explains this.

Plan has Schedule and Routines. Existing templates appear as routines without conversion or a database migration. The existing builder still handles creating, editing, starting a copy, scheduling, moving the assigned date, and deletion. Duplicate routine creates an unsaved independent draft with fresh exercise IDs. Starter routines open for review; suggested routines also open for review before creating records.

## Watch: no scrolling

The workout page, More page, and target editor use fixed viewport layouts, with no ScrollView/List or scrolling navigation. The main page shows exercise/progress, target or countdown, a primary action, Adjust, and More. More provides previous/next exercise, undo, and Back. The editor offers weight/reps selection, fine +/- buttons with native hold-to-repeat, jumps of ten equipment increments, Crown input without Crown haptics, Cancel, and Apply.

Editing is local and immediate. Apply sends one absolute weight/reps target with the original workout revision. The iPhone validates the revision, editing state, and bounds before one persisted change. Changes on the phone invalidate the draft instead of silently rebasing it. No offline command queue or automatic mutation replay is added. Per-increment connectivity and success haptics were removed; logged/undone sets still receive acknowledged haptics. Logging, navigation, rest, and undo retain the original shared store.

Debug-only `WATCH_LAYOUT_READY`, `WATCH_LAYOUT_REST`, `WATCH_LAYOUT_ADJUST`, and `WATCH_LAYOUT_MORE` launch flags provide isolated rendering fixtures. They do not create phone records or write cached workout state. Layout rendering is distinct from physical-device connectivity verification.

## Historical data

`TrainingProgress` projects existing completed sessions, exercises, sets, units, timestamps, and muscle groups. No new database or schema is added. Shared insights include configurable ranges, best weight/sets, reps, volume, estimated strength, prior performances, personal weight records, primary-muscle set distribution, exercise frequency, and steady/improving/declining comparisons.

Known lb/kg loads are converted only in analytical projections. Unspecified units remain separate; they are excluded from aggregate external-load volume. Bodyweight contributes zero external load and is excluded from estimated 1RM. Epley estimates use weighted sets of 1–12 reps and are explicitly estimates. No true completion timestamp exists: elapsed time is labeled “to last set,” not exact workout duration. Warm-up sets cannot be identified from existing records, so all valid logged sets are counted and no such classification is inferred.

Progress leads with sessions, sets, active days, weekly rhythm, and recent weight records. Exercise performance and Workload & consistency are separate drilldowns. Exercise charts offer date selection and best weight, volume, estimated 1RM, reps, and set metrics. Exercise detail reuses the same history and next-workout recommendation as planning; active logging retains its separate next-set advice and previous-session values.

## Local coaching

Coaching is one Settings destination sharing the existing Save/Cancel draft. Preferences cover goal, experience, weekly frequency, recovery, progression on/off, pace, equipment, preferred exercises, and exclusions. They are stored in local UserDefaults as a versioned Codable value, not in workout records. Existing export continues to exclude app preferences, as documented in Data & privacy.

Goal controls rep ranges in suggested routines. Experience and recovery affect suggested sets/rest; frequency affects suggested lineup size. Equipment/restrictions constrain candidates and substitutions; preferred and previously trained exercises sort first. Restricted equipment uses known starter-catalog mappings and does not guess what equipment a custom exercise needs. A filter can produce a shorter or empty routine, which must be edited before saving.

Progression uses the same historical engine in Plan, exercise detail, and active workouts. Conservative pace requires more successful sessions and caps equipment steps at 2.5%; Balanced/Aggressive use a 5% ceiling, with different evidence requirements. Beginner/recovery preferences increase the evidence requirement. Misses, mixed loads, and fatigue still block increases. Progression-off repeats targets. Repeated declines with recovery enabled can suggest one fewer set next workout, applied only explicitly. These are local rules, not cloud AI or medical/recovery measurements.

## Verification

Library/Plan unit and real simulator UI tests pass, including custom-name history preservation, reusable routine isolation, scheduling, and completion. Historical-data tests cover ranges, valid sets, unit conversion, PR baselines, estimated-strength exclusions, and elapsed-to-last-set labeling. Watch tests cover one-commit absolute targets, invalid values, phone-edit conflicts, and duplicate/stale actions alongside the existing session tests. Coaching tests cover persistence, conservative progression, exclusions, equipment, and non-persisting draft generation.

Final verification outcomes and device limitations are recorded in `REMAINING_WORK.md`. Existing work, app identities, schema versions, and persisted user data are preserved.
