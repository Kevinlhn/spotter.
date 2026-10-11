# Local progression suggestions

`ProgressiveOverloadEngine` is a pure deterministic function; `TrainingStore+Recommendations` projects the existing completed workout records into its input. There is no cloud LLM, network call, recurring cost, learned model, or duplicated history database. The first valid completed exercise performance is the baseline. Matching uses case-insensitive exercise names with normalized whitespace, consistent with Spotter's existing name-based history. Renaming an exercise starts a separate identity; different exercises should use distinct names.

The engine reports previous sets, baseline, six-session best, simple performance trend, and history confidence. Known lb/kg history is converted for comparison; unknown legacy units are excluded. Converted recommendations are rounded down to equipment steps for repeats and to the next step for increases. Every result has an explanation. Only the user's Use Suggestion action applies a result.

The active logger labels guidance **Next set**, with one concrete load/rep target and its short reason directly above the entry fields. Planning labels it **Next workout** and may retain a rep range. History stays collapsed. An **In use** state prevents redundant application. Recommendations are derived on each store refresh, including set edits, deletion, undo, and target changes. They are not cached or applied automatically; session revision-only changes preserve partially typed input. Editing an existing set hides next-set advice to avoid confusing retrospective edits with upcoming work.

Rules, in priority order:
1. During a workout, `NextSetGuidance` gives an exact next-set target. Repeat successful reps within the planned range; respond to falling reps at the same load. A miss of two or more reps, or two consecutive misses, suggests one equipment step lighter only when that reduction is at most 10%. Otherwise retry after rest with manual adjustment available. Bodyweight misses reduce the rep aim without adding external load. Completing the planned sets removes the apply action. Never escalate load between sets based on a single set.
2. With no completed history, request a starting load rather than inventing one. An explicit planned starting load can be used for the first set; once a set is logged, current performance supplies next-set guidance. Active sets never enter completed historical progression.
3. A substantial capacity drop, incomplete targets/sets, a missed prescribed load, or higher new targets prevents a load increase.
4. Mixed loads have no reliable warm-up/work-set distinction in the current model. Suggest the lightest recorded load with an explicit explanation and let the user choose.
5. Reaching the top of a rep range, or two successful sessions at the same fixed prescription and load, can unlock a small equipment step.
6. Limit the increase to 5%. Otherwise build one rep at the same load. Bodyweight remains bodyweight.

Barbells use 5 lb / 2.5 kg; dumbbells use 2.5 lb / 1 kg. Machines and unknown equipment use the existing configurable weight step. Spotter cannot know a gym's actual inventory, fatigue, pain, or form quality. Confidence describes the amount of recorded history, not certainty of physical readiness.

V6 adds an optional planned weight and an optional-by-convention minimum rep count (zero means the existing fixed target). Old data keeps its original fixed reps and unspecified planned load. All old model versions remain bundled for inferred migration. Suggestions saved into plans/templates survive start, repeat, export, and relaunch. Completed sets remain the only performance evidence. Export format 4 adds the prescription fields.
