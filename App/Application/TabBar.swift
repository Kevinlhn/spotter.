import SwiftUI

struct TabBar: View {
    @ObservedObject var store: TrainingStore
    @Binding var incomingURL: URL?
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var activities = WorkoutActivityCoordinator()
    @State private var libraryQuery = ""
    @State private var deferredWorkout: WorkoutEntity?
    @AppStorage("spotter.liveActivitiesEnabled") private var liveActivitiesEnabled = true
    @State private var selectedTab: SpotterTab = .today
    @State private var selectedDate = Date()
    @State private var sheet: SpotterSheet?
    @State private var session: WorkoutEntity?
    @State private var pendingSession: WorkoutEntity?
    @State private var pendingSheet: SpotterSheet?

    var body: some View {
        ZStack {
            switch selectedTab {
            case .today:
                TodayScreen(onQuickStart: quickStart, onStart: start,
                            onPlan: { selectedDate = $0; selectedTab = .plan },
                            onOpen: open, onSettings: { sheet = .settings })
            case .plan:
                PlanScreen(selectedDate: $selectedDate, onAdd: { sheet = .choosePlan($0) }, onOpen: open, onCreate: { sheet = .builder($0, $1) })
            case .library:
                LibraryScreen(query: $libraryQuery)
            case .progress:
                ProgressScreen(onOpen: open, onTrends: { sheet = .exerciseTrends })
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            SpotterDock(selection: $selectedTab, activeWorkout: store.active, onStart: quickStart,
                        onPlan: { sheet = .choosePlan(selectedTab == .plan ? selectedDate : Date()) },
                        onCreate: { sheet = .builder(TrainingDraft(), .template) })
        }
        .tint(SpotterStyle.foregroundAccent)
        .environmentObject(store)
        .environmentObject(activities)
        .sheet(item: $sheet, onDismiss: presentPending) { route in
            sheetContent(route).environmentObject(store).environmentObject(activities)
        }
        .fullScreenCover(item: $session, onDismiss: {
            if let deferredWorkout { session = deferredWorkout; self.deferredWorkout = nil }
        }) { workout in
            TrainingSession(workout: workout).environmentObject(store)
        }
        .onChange(of: activityRequest, initial: true) { _, request in
            // A presented workout must keep updating even while the underlying tab is covered.
            Task { await activities.reconcile(snapshot: request.snapshot, enabled: request.enabled, foreground: request.foreground) }
        }
        .onChange(of: incomingURL, initial: true) { _, url in
            guard let url else { return }
            incomingURL = nil
            handle(url)
        }
        .alert("Couldn’t complete that", isPresented: Binding(get: { store.error != nil && sheet == nil && session == nil }, set: { if !$0 { store.error = nil } })) {
            Button("OK") { store.error = nil }
        } message: { Text(store.error ?? "") }
    }

    @ViewBuilder private func sheetContent(_ route: SpotterSheet) -> some View {
        switch route {
        case .exerciseTrends: ExerciseProgressView()
        case .settings: TrainingSettings()
        case .quickStart:
            WorkoutPicker(title: "Start workout", onSuggest: { transition(to: .builder($0, .workout)) }) { draft in
                if draft.moves.isEmpty { transition(to: .builder(draft, .workout)) }
                else if let workout = store.save(draft, start: true) { launchAfterDismiss(workout) }
            }
            .alert("Couldn’t start", isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) {
                Button("OK") { store.error = nil }
            } message: { Text(store.error ?? "") }
        case .choosePlan(let date):
            WorkoutPicker(title: "Plan a workout") { draft in
                var planned = draft; planned.date = date
                transition(to: .builder(planned, .plan))
            }
        case .builder(let draft, let mode):
            WorkoutBuilder(draft: draft, mode: mode, onStart: launchAfterDismiss)
        case .journal(let workout):
            WorkoutJournal(workout: workout) { transition(to: .builder(TrainingDraft(workout: workout, repeatWorkout: true), .workout)) }
        }
    }
    private func open(_ workout: WorkoutEntity) {
        switch workout.workoutStatus {
        case .active: session = workout
        case .completed: sheet = .journal(workout)
        case .scheduled: sheet = .builder(TrainingDraft(workout: workout), .plan)
        case .template: sheet = .builder(TrainingDraft(workout: workout), .template)
        }
    }
    private func start(_ workout: WorkoutEntity) {
        if store.begin(workout) { session = workout }
    }
    private func launchAfterDismiss(_ workout: WorkoutEntity) {
        pendingSession = workout; sheet = nil
    }
    private func transition(to route: SpotterSheet) { pendingSheet = route; sheet = nil }
    private func presentPending() {
        if let pendingSession { session = pendingSession; self.pendingSession = nil }
        else if let pendingSheet { sheet = pendingSheet; self.pendingSheet = nil }
    }
    private var activityRequest: WorkoutActivityRequest {
        WorkoutActivityRequest(snapshot: WorkoutActivitySnapshot.make(workout: store.active),
                               enabled: liveActivitiesEnabled, foreground: scenePhase == .active)
    }
    private func quickStart() {
        if let active = store.active { session = active }
        else { sheet = .quickStart }
    }
    private func handle(_ url: URL) {
        guard let id = SpotterDeepLink.workoutID(from: url),
              let workout = store.workouts.first(where: { $0.id == id && $0.workoutStatus != .template }) else { return }
        if workout.workoutStatus == .active {
            if session?.id == workout.id { return }
            if sheet != nil { pendingSheet = nil; pendingSession = workout; sheet = nil }
            else if session != nil { deferredWorkout = workout; session = nil }
            else { session = workout }
        } else if workout.workoutStatus == .completed, session == nil {
            if sheet != nil { transition(to: .journal(workout)) }
            else { sheet = .journal(workout) }
        }
    }

}
