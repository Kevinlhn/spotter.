# Apple Watch companion

SpotterWatch is a watchOS 26 companion bundled with the iOS 26 app. Install Spotter from the iPhone Watch app, open both apps, and start or resume a workout on iPhone. The Watch follows that active session automatically. Settings → Apple Watch explains installation and reports pairing, installation, and reachability.

## On the wrist

The main screen shows the current exercise, set/exercise progress, load and reps, and one Log Set action. During rest it shows a date-driven countdown and End Rest. When time reaches zero, the active Watch view returns to logging. Planned sets complete leads to the next exercise; finishing/reviewing the workout remains on iPhone.

Adjust & more contains equipment-aware load steps, rep changes, Undo last set, and exercise navigation. Phone-side editing of an already recorded set blocks Watch changes until editing is complete. A successful acknowledged change gives a confirmation haptic. There is no guaranteed background rest alert: no HealthKit session or extended runtime is requested.

This version is an iPhone companion. It does not independently start workouts, collect heart rate/calories, write Apple Health workouts, or add complications. It needs a reachable companion to save changes. Offline, the last synced summary and absolute rest deadline remain visible; mutation controls are disabled. Refresh confirms the phone state before continuing after an unacknowledged action.

## Data and synchronization

- `Shared/WatchWorkoutMessage.swift`: versioned Codable request, reply, and snapshot values. No managed objects or workout notes cross the connection.
- `Services/WatchWorkoutBridge.swift`: starts WatchConnectivity at iPhone process launch, attaches to the existing `WorkoutRuntime` store, and publishes committed store updates. Latest-state application context supports reconnection; reachable message delivery updates an open Watch immediately.
- `SpotterWatch/WatchWorkoutStore.swift`: caches only the last snapshot, requests fresh state on activation/foreground/reconnection, and permits one outstanding request. Responses have matching request IDs and snapshots carry persisted sequence numbers, so older snapshots from the same installation cannot replace newer ones.
- Every mutation carries workout ID and the rendered revision. The phone validates them and calls the existing atomic `TrainingStore.performWorkoutAction`. Late/double-tapped commands cannot insert duplicate sets or mutate another exercise. Commands are never queued for offline replay or automatically retried against a newer revision.
- Phone UI, Watch, and Live Activity share the same persisted sets, input values, and rest deadline. Watch commands also refresh existing Live Activities while the iPhone UI is backgrounded. Finish/discard publishes an empty active-workout snapshot.

No database migration, cloud service, new entitlement, or data-store relocation is required. The Watch uses Spotter’s existing dark icon and steel-blue palette. The system applies its circular icon mask.

## Build and verification

Use the `Spotter` scheme for the complete iPhone app, which embeds `SpotterWatch.app`. Use `SpotterWatch` to run directly on a paired Watch simulator or device. Both targets use the existing development team; signing/provisioning on physical devices still needs verification.

The Watch simulator build and combined unsigned iPhone/watchOS device Release build pass. The existing 69 unit tests and eight new Watch command/protocol tests pass. New tests cover duplicate logging, phone edits invalidating Watch commands, rest-deadline preservation, skip/undo, recorded-set editing, completion, equipment adjustments, navigation, protocol rejection, and out-of-order snapshots.

Hands-on verification used a dedicated paired iOS 26 / watchOS 26 simulator and the 42 mm Series 11 display. A workout started on iPhone appeared on Watch through real WatchConnectivity. Logging on Watch advanced the set count and showed the rest countdown; expiry returned to Log Set. Undo on Watch removed the same recorded set on iPhone, with both devices showing the restored count. The ready, resting, and adjustment screens were inspected. A bodyweight label that wrapped and crowded Log Set was changed to fit on one line; the final rendered button is fully visible. Crown scrolling reaches the secondary controls.

Physical-device signing/installation, confirmation haptics, VoiceOver, and connection recovery across real-device sleep/termination remain unverified. The additional attempt to log while iPhone was backgrounded was blocked by intermittent simulator window-control errors, so that lifecycle interaction is not claimed as verified. Command-level tests cover adjustments, navigation, rest skipping, stale revisions, and duplicate protection; they do not replace those device checks.

Apple platform references:
- [WatchConnectivity session lifecycle and transfer methods](https://developer.apple.com/documentation/watchconnectivity/wcsession)
- [Transferring data with Watch Connectivity](https://developer.apple.com/documentation/watchconnectivity/transferring-data-with-watch-connectivity)
- [Setting up a watchOS project](https://developer.apple.com/documentation/watchos-apps/setting-up-a-watchos-project)
