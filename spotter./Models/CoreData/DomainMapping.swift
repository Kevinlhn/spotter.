//
//  DomainMapping.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 10/29/25.
//


import Foundation
import CoreData

// MARK: - UserEntity ⇄ User
extension UserEntity {
    func toDomain() -> User {
        User(
            id: id,
            email: email,
            name: name,
            gender: Gender(rawValue: gender) ?? .unspecified,
            dob: dob,
            heightCM: heightCM,
            weightKG: weightKG,
            experienceLevel: ExperienceLevel(rawValue: experienceLevel) ?? .novice,
            trainingMode: TrainingModeType(rawValue: trainingMode) ?? .mixed,
            timezone: timezone,
            streakDays: Int(streakDays),
            appleHealthConnected: appleHealthConnected,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    func update(from domain: User) {
        id = domain.id
        email = domain.email
        name = domain.name
        gender = domain.gender.rawValue
        dob = domain.dob
        heightCM = domain.heightCM ?? 0
        weightKG = domain.weightKG ?? 0
        experienceLevel = domain.experienceLevel.rawValue
        trainingMode = domain.trainingMode.rawValue
        timezone = domain.timezone
        streakDays = Int32(domain.streakDays)
        appleHealthConnected = domain.appleHealthConnected
        createdAt = domain.createdAt
        updatedAt = Date()
    }
}
// MARK: - Conversion Helpers
extension WorkoutEntity {
    func toDomain() -> Workout {
        Workout(
            id: id,
            programID: program?.id,
            userID: user?.id ?? UUID(),
            title: title,
            type: WorkoutType(rawValue: type) ?? .strength,
            date: date,
            status: WorkoutStatus(rawValue: status) ?? .planned,
            perceivedFatigue: Int(perceivedFatigue),
            energyLevel: Int(energyLevel),
            durationSec: Int(durationSec),
            totalVolume: totalVolume,
            adherenceScore: adherenceScore,
            notes: notes,
            sets: sets?.map { $0.toDomain() } ?? []
        )
    }

    func update(from domain: Workout, context: NSManagedObjectContext) {
        id = domain.id
        title = domain.title
        type = domain.type.rawValue
        date = domain.date
        status = domain.status.rawValue
        perceivedFatigue = Int16(domain.perceivedFatigue ?? 0)
        energyLevel = Int16(domain.energyLevel ?? 0)
        durationSec = Int32(domain.durationSec ?? 0)
        totalVolume = domain.totalVolume ?? 0
        adherenceScore = domain.adherenceScore ?? 0
        notes = domain.notes
        createdAt = domain.createdAt // <- remove ??
        updatedAt = Date()

        // Update child sets
        var newSets: [WorkoutSetEntity] = []
        for domainSet in domain.sets {
            let setEntity = WorkoutSetEntity(context: context)
            setEntity.update(from: domainSet)
            setEntity.workout = self
            newSets.append(setEntity)
        }
        self.sets = Set(newSets)
    }
}

extension WorkoutSetEntity {
    func toDomain() -> WorkoutSet {
        WorkoutSet(
            id: id,
            workoutID: workout?.id ?? UUID(),
            exerciseID: exercise?.id ?? UUID(),
            setNumber: Int(exactly: setNumber) ?? Int(setNumber),
            reps: reps == 0 ? nil : (Int(exactly: reps) ?? Int(reps)),
            weightKG: weightKG == 0 ? nil : weightKG,
            distanceM: distanceM == 0 ? nil : Int(distanceM),
            durationSec: durationSec == 0 ? nil : Int(durationSec),
            rir: rir == 0 ? nil : rir,
            rpe: rpe == 0 ? nil : rpe,
            isSuperset: isSuperset,
            completed: completed
        )
    }

    func update(from domain: WorkoutSet) {
        id = domain.id
        setNumber = Int16(domain.setNumber)
        reps = Int16(domain.reps ?? 0)
        weightKG = domain.weightKG ?? 0
        distanceM = Int32(domain.distanceM.map { Int32($0) } ?? 0)
        durationSec = Int32(domain.durationSec.map { Int32($0) } ?? 0)
        rir = domain.rir ?? 0
        rpe = domain.rpe ?? 0
        isSuperset = domain.isSuperset
        completed = domain.completed
        isWarmup = false
        createdAt = domain.createdAt
    }
}

// MARK: - ProgramEntity ⇄ Program
extension ProgramEntity {
    func toDomain() -> Program {
        Program(
            id: id,
            userID: user?.id ?? UUID(),
            title: title,
            trainingMode: TrainingModeType(rawValue: trainingMode) ?? .mixed,
            durationWeeks: Int(durationWeeks),
            startDate: startDate,
            endDate: endDate,
            isActive: isActive,
            metadata: (metadata != nil ? (try? JSONDecoder().decode([String:String].self, from: metadata!)) : nil),
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    func update(from domain: Program) {
        id = domain.id
        title = domain.title
        trainingMode = domain.trainingMode.rawValue
        durationWeeks = Int16(domain.durationWeeks)
        startDate = domain.startDate
        endDate = domain.endDate
        isActive = domain.isActive
        metadata = try? JSONEncoder().encode(domain.metadata)
        createdAt = domain.createdAt
        updatedAt = Date()
    }
}


// MARK: - ExerciseEntity ⇄ Exercise
extension ExerciseEntity {
    func toDomain() -> Exercise {
        Exercise(
            id: id,
            name: name,
            category: ExerciseCategory(rawValue: category) ?? .barbell,
            modality: ExerciseModality(rawValue: modality) ?? .compound,
            primaryMuscles: decodeArray(primaryMuscles),
            secondaryMuscles: decodeArray(secondaryMuscles),
            equipmentNeeded: decodeArray(equipmentNeeded),
            difficulty: Difficulty(rawValue: difficulty) ?? .beginner,
            videoURL: videoURL,
            coachingCues: decodeArray(coachingCues),
            isPublic: isPublic,
            createdAt: createdAt
        )
    }

    func update(from domain: Exercise) {
        id = domain.id
        name = domain.name
        category = domain.category.rawValue
        modality = domain.modality.rawValue
        primaryMuscles = encodeArray(domain.primaryMuscles)
        secondaryMuscles = encodeArray(domain.secondaryMuscles)
        equipmentNeeded = encodeArray(domain.equipmentNeeded)
        difficulty = domain.difficulty.rawValue
        videoURL = domain.videoURL
        coachingCues = encodeArray(domain.coachingCues)
        isPublic = domain.isPublic
        createdAt = domain.createdAt
    }

    private func encodeArray(_ arr: [String]) -> Data? {
        try? JSONEncoder().encode(arr)
    }

    private func decodeArray(_ data: Data?) -> [String] {
        guard let data = data else { return [] }
        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }
}

// MARK: - GoalEntity ⇄ Goal
extension GoalEntity {
    func toDomain() -> Goal {
        Goal(
            id: id,
            userID: user?.id ?? UUID(),
            type: GoalType(rawValue: type) ?? .custom,
            targetValue: targetValue,
            currentValue: currentValue,
            unit: unit,
            targetDate: targetDate,
            status: GoalStatus(rawValue: status) ?? .active,
            progressPercent: progressPercent,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    func update(from domain: Goal) {
        id = domain.id
        type = domain.type.rawValue
        targetValue = domain.targetValue
        currentValue = domain.currentValue
        unit = domain.unit
        targetDate = domain.targetDate
        status = domain.status.rawValue
        progressPercent = domain.progressPercent
        createdAt = domain.createdAt
        updatedAt = Date()
    }
}

// MARK: - PersonalRecordEntity ⇄ PersonalRecord
extension PersonalRecordEntity {
    func toDomain() -> PersonalRecord {
        PersonalRecord(
            id: id,
            userID: user?.id ?? UUID(),
            exerciseID: exercise?.id ?? UUID(),
            type: PRType(rawValue: type) ?? .weight,
            value: value,
            date: date,
            context: decodeDict(context),
            createdAt: createdAt
        )
    }

    func update(from domain: PersonalRecord) {
        id = domain.id
        type = domain.type.rawValue
        value = domain.value
        date = domain.date
        context = encodeDict(domain.context)
        createdAt = domain.createdAt
    }

    private func encodeDict(_ dict: [String: String]?) -> Data? {
        guard let dict = dict else { return nil }
        return try? JSONEncoder().encode(dict)
    }

    private func decodeDict(_ data: Data?) -> [String: String]? {
        guard let data = data else { return nil }
        return try? JSONDecoder().decode([String: String].self, from: data)
    }
}

// MARK: - MediaShareEntity ⇄ MediaShare
extension MediaShareEntity {
    func toDomain() -> MediaShare {
        MediaShare(
            id: id,
            userID: user?.id ?? UUID(),
            workoutID: workout?.id,
            prID: pr?.id,
            type: MediaShareType(rawValue: type) ?? .workoutSummary,
            imageURL: imageURL,
            caption: caption,
            platform: platform.flatMap { SharePlatform(rawValue: $0) },
            sharedAt: sharedAt,
            createdAt: createdAt
        )
    }

    func update(from domain: MediaShare) {
        id = domain.id
        type = domain.type.rawValue
        imageURL = domain.imageURL
        caption = domain.caption
        platform = domain.platform?.rawValue
        sharedAt = domain.sharedAt
        createdAt = domain.createdAt
    }
}

// MARK: - HealthSyncEntity ⇄ AppleHealthSync
extension HealthSyncEntity {
    func toDomain() -> AppleHealthSync {
        AppleHealthSync(
            id: id,
            userID: user?.id ?? UUID(),
            source: source,
            dailySteps: Int(dailySteps),
            activeEnergy: activeEnergy,
            restingHeartRate: restingHeartRate,
            vo2max: vo2max == 0 ? nil : vo2max,
            syncedAt: syncedAt
        )
    }

    func update(from domain: AppleHealthSync) {
        id = domain.id
        source = domain.source
        dailySteps = Int32(domain.dailySteps)
        activeEnergy = domain.activeEnergy
        restingHeartRate = domain.restingHeartRate
        vo2max = domain.vo2max ?? 0
        syncedAt = domain.syncedAt
    }
}

// MARK: - CoachSessionEntity ⇄ CoachSession
extension CoachSessionEntity {
    func toDomain() -> CoachSession {
        CoachSession(
            id: id,
            userID: user?.id ?? UUID(),
            sessionState: decodeDict(sessionState),
            lastMessage: lastMessage,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    func update(from domain: CoachSession) {
        id = domain.id
        sessionState = encodeDict(domain.sessionState)
        lastMessage = domain.lastMessage
        createdAt = domain.createdAt
        updatedAt = Date()
    }

    private func encodeDict(_ dict: [String: AnyCodable]) -> Data? {
        try? JSONEncoder().encode(dict)
    }

    private func decodeDict(_ data: Data?) -> [String: AnyCodable] {
        guard let data = data else { return [:] }
        return (try? JSONDecoder().decode([String: AnyCodable].self, from: data)) ?? [:]
    }
}

// MARK: - AIPlanHistoryEntity ⇄ AIPlanHistory
extension AIPlanHistoryEntity {
    func toDomain() -> AIPlanHistory {
        AIPlanHistory(
            id: id,
            userID: user?.id ?? UUID(),
            planID: program?.id ?? UUID(),
            aiModelVersion: aiModelVersion,
            parameters: decodeDict(parameters),
            generatedAt: generatedAt
        )
    }

    func update(from domain: AIPlanHistory) {
        id = domain.id
        aiModelVersion = domain.aiModelVersion
        parameters = encodeDict(domain.parameters)
        generatedAt = domain.generatedAt
    }

    private func encodeDict(_ dict: [String: AnyCodable]) -> Data? {
        try? JSONEncoder().encode(dict)
    }

    private func decodeDict(_ data: Data?) -> [String: AnyCodable] {
        guard let data = data else { return [:] }
        return (try? JSONDecoder().decode([String: AnyCodable].self, from: data)) ?? [:]
    }
}

// MARK: - UserEventEntity ⇄ UserEvent
extension UserEventEntity {
    func toDomain() -> UserEvent {
        UserEvent(
            id: id,
            userID: user?.id ?? UUID(),
            name: name,
            properties: decodeDict(properties),
            timestamp: timestamp
        )
    }

    func update(from domain: UserEvent) {
        id = domain.id
        name = domain.name
        properties = encodeDict(domain.properties)
        timestamp = domain.timestamp
    }

    private func encodeDict(_ dict: [String: AnyCodable]) -> Data? {
        try? JSONEncoder().encode(dict)
    }

    private func decodeDict(_ data: Data?) -> [String: AnyCodable] {
        guard let data = data else { return [:] }
        return (try? JSONDecoder().decode([String: AnyCodable].self, from: data)) ?? [:]
    }
}

