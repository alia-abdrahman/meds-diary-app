import SwiftUI
import SwiftData
import UIKit

@main
struct medi_diary_appApp: App {
    @State private var notificationManager = NotificationManager()
    @State private var authManager = AuthenticationManager()
    @State private var subscriptionManager = SubscriptionManager()

    init() {
        let largeTitleFont = UIFont(name: "Poppins-Bold", size: 34) ?? .systemFont(ofSize: 34, weight: .bold)
        let inlineTitleFont = UIFont(name: "Poppins-SemiBold", size: 17) ?? .systemFont(ofSize: 17, weight: .semibold)

        // Unified appearance using primary light colour
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.773, green: 0.792, blue: 0.859, alpha: 1) // PastelTheme.light
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [.font: inlineTitleFont]
        appearance.largeTitleTextAttributes = [.font: largeTitleFont]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    let container: ModelContainer = {
        let schema = Schema([Appointment.self, Medicine.self, Supplement.self, MoodEntry.self])
        let isPremium = SubscriptionManager.cachedIsPremium
        let config = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: isPremium ? .automatic : .none
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            if !hasSeenOnboarding {
                OnboardingView()
            } else if !authManager.isSignedIn {
                SignInView()
                    .environment(authManager)
            } else {
                MainTabView()
                    .environment(notificationManager)
                    .environment(authManager)
                    .environment(subscriptionManager)
                    .task {
                        await authManager.recoverEmailIfNeeded()
                        await notificationManager.requestAuthorization()
                        await subscriptionManager.checkEntitlements()

                        // Rebuild all consolidated notifications on launch
                        let context = container.mainContext
                        let medicines = (try? context.fetch(FetchDescriptor<Medicine>())) ?? []
                        let supplements = (try? context.fetch(FetchDescriptor<Supplement>())) ?? []
                        await notificationManager.scheduleAllReminders(medicines: medicines, supplements: supplements)
                    }
            }
        }
        .modelContainer(container)
    }
}
