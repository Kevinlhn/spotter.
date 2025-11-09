//
//  ProfileView.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 10/29/25.
//
import SwiftUI
import CoreData

struct ProfileView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: [], animation: .easeInOut)
    private var users: FetchedResults<UserEntity>
    @State private var showDeleteAlert = false
    @State private var deletionSuccess = false


    var currentUser: UserEntity {
        if let existing = users.first {
            return existing
        } else {
            // Create a new real user in Core Data (not mock)
            let newUser = UserEntity(context: context)
            newUser.id = UUID()
            newUser.name = "Kevin Hernandez"        // default or from signup
            newUser.email = "kevin@example.com"     // can be loaded from login later
            newUser.trainingMode = "strength"
            newUser.experienceLevel = "intermediate"
            newUser.streakDays = 0
            newUser.createdAt = Date()
            newUser.updatedAt = Date()
            newUser.appleHealthConnected = false
            newUser.weightKG = 0
            newUser.heightCM = 0
            try? context.save()
            return newUser
        }
    }

    var body: some View {
        ZStack {
            SpotterBackground()

            VStack {
                // MARK: - Header
                Text("profile.")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(AppColors.bluePrimary.gradient)

                // MARK: - User Card
                VStack(spacing: 10) {
                    HStack {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(AppColors.bluePrimary)
                            .shadow(radius: 3)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(currentUser.name)
                                .font(.title2.bold())
                                .foregroundColor(AppColors.bluePrimary)
                            Text(currentUser.email)
                                .font(.caption)
                        }
                        Spacer()
                    }

                    HStack {
                        ProfileStat(label: "mode", value: currentUser.trainingMode.isEmpty ? "—" : currentUser.trainingMode)
                        ProfileStat(label: "level", value: currentUser.experienceLevel.isEmpty ? "—" : currentUser.experienceLevel)
                        ProfileStat(label: "streak", value: "\(currentUser.streakDays)")
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(.ultraThinMaterial, lineWidth: 3)
                        .background(.thinMaterial.opacity(0.2))
                        .cornerRadius(30)
                )
                .padding(.horizontal)
                .padding(.vertical, 40)

                // MARK: - Settings
                VStack(spacing: 14) {
                    ProfileRow(icon: "person.text.rectangle", title: "Account Settings")
                    ProfileRow(icon: "heart.fill", title: "Apple Health Integration")
                    ProfileRow(icon: "arrow.up.square.fill", title: "Share Achievements")
                    ProfileRow(icon: "gearshape.fill", title: "App Preferences")
                }
                .padding(30)
                .background(
                    RoundedRectangle(cornerRadius: 50)
                        .stroke(.ultraThinMaterial, lineWidth: 3)
                        .background(.thinMaterial.opacity(0.2))
                        .cornerRadius(50)
                )
                .padding(.horizontal)
                Spacer()
                // 🧨 Delete All Button
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Label("Delete All Data", systemImage: "trash.fill")
                        .font(.callout.bold())
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .foregroundColor(.red)
                }
                .padding(.top, 10)
                .alert("Delete All Data?",
                       isPresented: $showDeleteAlert) {
                    Button("Cancel", role: .cancel) {}
                    Button("Delete", role: .destructive) { deleteAllData() }
                } message: {
                    Text("This will permanently delete all workouts, sets, programs, and user data. This cannot be undone.")
                }.padding()
            }
        }
        .alert("All data deleted", isPresented: $deletionSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Spotter data has been fully reset.")
        }
    }

    // MARK: - Delete Everything
    private func deleteAllData() {
        let entityNames = ["UserEntity", "WorkoutEntity", "WorkoutSetEntity", "ExerciseEntity", "ProgramEntity"]

        for entityName in entityNames {
            let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let batchDelete = NSBatchDeleteRequest(fetchRequest: fetch)
            batchDelete.resultType = .resultTypeObjectIDs

            do {
                let result = try context.execute(batchDelete) as? NSBatchDeleteResult
                if let objectIDs = result?.result as? [NSManagedObjectID] {
                    let changes = [NSDeletedObjectsKey: objectIDs]
                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
                }
            } catch {
                print("❌ Failed to delete \(entityName): \(error.localizedDescription)")
            }
        }

        try? context.save()
        deletionSuccess = true
        HapticFeedback.success()
    }
}

// MARK: - Haptics
enum HapticFeedback {
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// MARK: - Components
struct ProfileRow: View {
    var icon: String
    var title: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(AppColors.bluePrimary)
            Text(title)
                .font(.body)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

struct ProfileStat: View {
    var label: String
    var value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .foregroundColor(AppColors.bluePrimary)
            Text(label)
                .font(.caption)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("ProfileView") {
    let context = PersistenceController.preview.container.viewContext
    return ProfileView()
        .environment(\.managedObjectContext, context)
}

