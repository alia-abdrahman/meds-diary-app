import SwiftUI
import SwiftData

enum AppTab: Hashable {
    case home, appointments, medicines, supplements, settings

    var title: String {
        switch self {
        case .home: "Home"
        case .appointments: "Appointments"
        case .medicines: "Medicines"
        case .supplements: "Supplements"
        case .settings: "Settings"
        }
    }

    var icon: String {
        switch self {
        case .home: "house.fill"
        case .appointments: "calendar"
        case .medicines: "pill.fill"
        case .supplements: "leaf.fill"
        case .settings: "gearshape"
        }
    }

    static let allTabs: [AppTab] = [.home, .appointments, .medicines, .supplements, .settings]
}

struct MainTabView: View {
    @State private var selectedTab: AppTab = .home
    @Environment(SubscriptionManager.self) private var subscriptionManager

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Group {
                    switch selectedTab {
                    case .home:
                        DashboardView(selectedTab: $selectedTab)
                    case .appointments:
                        AppointmentsListView()
                    case .medicines:
                        MedicinesListView()
                    case .supplements:
                        SupplementsListView()
                    case .settings:
                        NavigationStack {
                            SettingsView()
                        }
                    }
                }
                .transition(.opacity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            HStack {
                ForEach(AppTab.allTabs, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20))
                            Text(tab.title)
                                .font(.caption2)
                        }
                        .foregroundStyle(selectedTab == tab ? PastelTheme.dark : .secondary)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 4)
            .background(.bar)
        }
        .ignoresSafeArea(.keyboard)
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
