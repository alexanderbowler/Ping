import SwiftUI
import SwiftData

@main
struct PingApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            PingContact.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    NotificationManager.shared.requestPermission()
                }
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                rescheduleNotifications()
            } else if newPhase == .background {
                scheduleImmediateOverdueNotifications()
            }
        }
    }

    private func rescheduleNotifications() {
        let context = sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<PingContact>()
        guard let contacts = try? context.fetch(descriptor) else { return }
        NotificationManager.shared.rescheduleAll(contacts: contacts)
    }

    private func scheduleImmediateOverdueNotifications() {
        let context = sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<PingContact>()
        guard let contacts = try? context.fetch(descriptor) else { return }
        NotificationManager.shared.scheduleImmediateNotifications(for: contacts)
    }
}
