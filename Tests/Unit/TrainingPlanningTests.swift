import Testing
import CoreData
@testable import spotter_

@MainActor
struct TrainingPlanningTests {
    private func makeStore() -> TrainingStore {
        TrainingStore(context: Persistence(inMemory: true).container.viewContext)
    }

    @Test func templatesStayReusableAndCopiesHaveIndependentExercisesAndSets() throws {
        let store = makeStore()
        let template = try #require(store.saveTemplate(TrainingDraft(routine: TrainingRoutine.starters[0])))
        #expect(store.templates == [template])
        #expect(store.scheduled.isEmpty)
        #expect(store.completed.isEmpty)
        #expect(store.active == nil)
        #expect(template.scheduledDate == nil)
        #expect(template.planningState() == nil)
        #expect(store.entries(on: Date()).isEmpty)
        #expect(!store.begin(template))
        #expect(store.save(TrainingDraft(workout: template), start: true) == nil)

        let session = try #require(store.save(TrainingDraft(template: template), start: true))
        let exercise = try #require(session.sortedExercises.first)
        #expect(Set(template.sortedExercises.map(\.id)).isDisjoint(with: session.sortedExercises.map(\.id)))
        #expect(store.logSet(exercise: exercise, weight: 25, reps: 8))
        #expect(store.finish(session))
        var edit = TrainingDraft(workout: template)
        edit.name = "Updated reusable workout"
        edit.moves.removeLast()
        #expect(store.saveTemplate(edit) == template)
        #expect(template.sortedExercises.count == 3)
        #expect(session.sortedExercises.count == 4)
        #expect(session.sortedExercises.first?.sortedSets.count == 1)
        #expect(template.sortedExercises.allSatisfy { $0.sortedSets.isEmpty })
        #expect(store.delete(template))
        #expect(store.completed == [session])
    }

    @Test func savingCompletedWorkoutAsTemplateDoesNotCopyItsHistory() throws {
        let store = makeStore()
        let session = try #require(store.save(TrainingDraft(routine: TrainingRoutine.starters[0]), start: true))
        let exercise = try #require(session.sortedExercises.first)
        #expect(store.logSet(exercise: exercise, weight: 25, reps: 8))
        #expect(store.finish(session))
        #expect(store.saveTemplate(TrainingDraft(workout: session)) == nil)
        let template = try #require(store.saveTemplate(TrainingDraft(workout: session, repeatWorkout: true)))
        #expect(template.sortedExercises.allSatisfy { $0.sortedSets.isEmpty })
        #expect(template.scheduledDate == nil)
        #expect(session.sortedExercises.first?.sortedSets.count == 1)
    }

    @Test func startingPlanRetainsItsCalendarDateAndCompletionStaysOnThatDay() throws {
        let store = makeStore()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
        let assigned = try #require(calendar.date(from: DateComponents(year: 2025, month: 6, day: 3, hour: 10)))
        var draft = TrainingDraft(routine: TrainingRoutine.starters[0])
        draft.date = assigned
        let plan = try #require(store.save(draft, start: false))
        #expect(plan.scheduledDate == assigned)
        #expect(plan.planningState(now: assigned, calendar: calendar) == .scheduled)
        #expect(plan.planningState(now: assigned.addingTimeInterval(86_400), calendar: calendar) == .overdue)
        #expect(store.begin(plan))
        #expect(plan.scheduledDate == assigned)
        #expect(plan.date > assigned)
        #expect(plan.planningState() == .active)
        let exercise = try #require(plan.sortedExercises.first)
        #expect(store.logSet(exercise: exercise, weight: 25, reps: 8))
        #expect(store.finish(plan))
        #expect(plan.planningState() == .completed)
        #expect(store.entries(on: assigned, calendar: calendar) == [plan])
        #expect(store.entries(on: Date(), calendar: calendar).isEmpty)
        #expect(store.thisWeek.contains(plan))
    }

    @Test func legacyPlanCapturesDateAndEditingMovesItToNewCalendarDay() throws {
        let store = makeStore()
        var draft = TrainingDraft(routine: TrainingRoutine.starters[0])
        draft.date = Date().addingTimeInterval(-172_800)
        let plan = try #require(store.save(draft, start: false))
        // Migration leaves this optional field nil; the old date remains the source of truth.
        plan.scheduledDate = nil
        #expect(store.persist())
        #expect(plan.calendarDate == draft.date)
        var edit = TrainingDraft(workout: plan)
        edit.date = Date().addingTimeInterval(172_800)
        #expect(store.save(edit, start: true) == plan)
        #expect(plan.scheduledDate == edit.date)
        #expect(plan.calendarDate == edit.date)
    }

    @Test func setEditsRejectInvalidForeignAndCompletedDataWithoutPartialMutation() throws {
        let store = makeStore()
        let session = try #require(store.save(TrainingDraft(routine: TrainingRoutine.starters[0]), start: true))
        let exercise = try #require(session.sortedExercises.first)
        #expect(store.logSet(exercise: exercise, weight: 10, reps: 8))
        let set = try #require(exercise.sortedSets.first)
        #expect(!store.updateSet(set, weight: .nan, reps: 10))
        #expect(!store.updateSet(set, weight: 20, reps: 1000))
        #expect(set.weight == 10 && set.reps == 8)
        #expect(!makeStore().updateSet(set, weight: 20, reps: 10))
        #expect(!makeStore().deleteSet(set))
        #expect(!makeStore().delete(session))
        #expect(store.updateSet(set, weight: 20, reps: 10))
        #expect(set.weight == 20 && set.reps == 10)
        #expect(store.finish(session))
        #expect(!store.updateSet(set, weight: 30, reps: 12))
        #expect(!store.deleteSet(set))
        #expect(set.weight == 20 && set.reps == 10)
    }

    @Test func calendarGridUsesLocaleWeekStartAndHandlesDST() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
        calendar.firstWeekday = 2 // Monday
        let march = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 15)))
        let cells = TrainingCalendar.days(in: march, calendar: calendar)
        let days = cells.compactMap { $0 }
        #expect(cells.count % 7 == 0)
        #expect(cells.prefix(6).allSatisfy { $0 == nil }) // March 1 is Sunday.
        #expect(days.count == 31)
        #expect(days.map { calendar.component(.day, from: $0) } == Array(1...31))
        #expect(Set(days).count == 31)
        #expect(TrainingCalendar.weekdaySymbols(calendar: calendar).first == calendar.veryShortStandaloneWeekdaySymbols[1])
    }

    @Test func exportSeparatesTemplatesAndRetainsAssignedDay() throws {
        let store = makeStore()
        let template = try #require(store.saveTemplate(TrainingDraft(routine: TrainingRoutine.starters[0])))
        var draft = TrainingDraft(template: template)
        draft.date = Date(timeIntervalSince1970: 1_800_000_000)
        let plan = try #require(store.save(draft, start: false))
        #expect(store.begin(plan))
        let file = try SpotterExportManager.shared.exportJSONFile(from: store.context)
        defer { try? FileManager.default.removeItem(at: file) }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(SpotterExportManager.ExportPayload.self, from: Data(contentsOf: file))
        #expect(payload.version == 4)
        #expect(payload.templates.map(\.id) == [template.id])
        #expect(payload.workouts.map(\.id) == [plan.id])
        #expect(payload.workouts.first?.scheduledDate == draft.date)
        #expect(payload.templates.first?.scheduledDate == nil)
    }

    @Test func exerciseLibraryExportsWithoutAnyWorkoutRecords() throws {
        let store = makeStore()
        store.saveToLibrary(TrainingMove(name: "Custom cable row", muscle: "Back"))
        let saved = try #require(store.library.first)
        saved.isFavorite = true
        #expect(store.persist())
        let file = try SpotterExportManager.shared.exportJSONFile(from: store.context)
        defer { try? FileManager.default.removeItem(at: file) }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(SpotterExportManager.ExportPayload.self, from: Data(contentsOf: file))
        #expect(payload.workouts.isEmpty)
        #expect(payload.templates.isEmpty)
        let exported = try #require(payload.exerciseLibrary.first)
        #expect(exported.id == saved.id)
        #expect(exported.name == "Custom cable row")
        #expect(exported.primaryMuscle == "Back")
        #expect(exported.isFavorite)
        #expect(exported.isCustom)
    }

    @Test func customExerciseEditsDoNotRewriteHistoricalSessions() throws {
        let store = makeStore()
        let move = TrainingMove(name: "Custom row", muscle: "Back")
        store.saveToLibrary(move)
        let custom = try #require(store.library.first)
        var draft = TrainingDraft(); draft.name = "Rows"; draft.moves = [move]
        let workout = try #require(store.save(draft, start: true))
        let exercise = try #require(workout.sortedExercises.first)
        #expect(store.logSet(exercise: exercise, weight: 25, reps: 8))
        #expect(store.finish(workout))
        #expect(store.updateLibraryExercise(custom, name: "Cable row", muscle: "Back"))
        #expect(exercise.name == "Custom row")
        #expect(exercise.sortedSets.first?.weight == 25)
        let names = ExerciseCatalog.moves(custom: store.library, workouts: store.workouts).map(\.name)
        #expect(names.contains("Custom row") && names.contains("Cable row"))
    }

    @Test func startingAnEmptyLegacyPlanExplainsHowToRepairIt() {
        let store = makeStore()
        let plan = WorkoutEntity.insert(in: store.context)
        plan.id = UUID()
        plan.name = "Old empty plan"
        plan.date = Date()
        plan.workoutStatus = .scheduled
        #expect(store.persist())
        #expect(!store.begin(plan))
        #expect(store.error == "Add an exercise to this workout in Plan before starting it.")
        #expect(plan.workoutStatus == .scheduled)
        #expect(store.active == nil)
    }
}
