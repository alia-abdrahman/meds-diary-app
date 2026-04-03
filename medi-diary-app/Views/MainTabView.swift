import SwiftUI
import SwiftData

enum AppTab: Hashable {
    case home, appointments, medicines, supplements, settings
}

struct MainTabView: View {
    @State private var selectedTab: AppTab = .home
    @Environment(SubscriptionManager.self) private var subscriptionManager

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house.fill", value: .home) {
                DashboardView(selectedTab: $selectedTab)
            }
            Tab("Appointments", systemImage: "calendar", value: .appointments) {
                AppointmentsListView()
            }
            Tab("Medicines", systemImage: "pill.fill", value: .medicines) {
                MedicinesListView()
            }
            Tab("Supplements", systemImage: "leaf.fill", value: .supplements) {
                SupplementsListView()
            }
            Tab("Settings", systemImage: "gearshape", value: .settings) {
                NavigationStack {
                    SettingsView()
                }
            }
        }
        .tint(PastelTheme.dark)
        .overlay(alignment: .top) {
            if subscriptionManager.cloudKitStatusChanged {
                HStack {
                    Text("iCloud sync will activate on next app launch")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    Spacer()
                    Button {
                        subscriptionManager.acknowledgeCloudKitChange()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.semibold))
                    }
                }
                .padding()
                .background(PastelTheme.primary.opacity(0.25))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: subscriptionManager.cloudKitStatusChanged)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Appointment.self, Medicine.self, Supplement.self], inMemory: true)
        .environment(NotificationManager())
        .environment(SubscriptionManager())
}
