import SwiftUI
import SwiftData

struct SupplementsListView: View {
    @Query(sort: \Supplement.name) private var supplements: [Supplement]
    @Environment(\.modelContext) private var modelContext
    @Environment(NotificationManager.self) private var notificationManager
    @Environment(SubscriptionManager.self) private var subscriptionManager

    @State private var showPaywall = false
    @State private var showAddForm = false

    private var activeSupplements: [Supplement] { supplements.filter(\.isActive) }
    private var pastSupplements: [Supplement] { supplements.filter { !$0.isActive } }

    var body: some View {
        NavigationStack {
            Group {
                if supplements.isEmpty {
                    ContentUnavailableView {
                        Label("No Supplements", systemImage: "leaf")
                    } description: {
                        Text("Track your supplements")
                    } actions: {
                        Button {
                            if subscriptionManager.canAddItem(currentCount: supplements.count) {
                                showAddForm = true
                            } else {
                                showPaywall = true
                            }
                        } label: {
                            Text("Add")
                                .font(.poppins(.semiBold, size: 15))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 28)
                                .padding(.vertical, 10)
                                .background(PastelTheme.dark)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(PressDownButtonStyle())
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            if !activeSupplements.isEmpty {
                                sectionLabel("Active")
                                ForEach(activeSupplements) { supplement in
                                    NavigationLink {
                                        SupplementDetailView(supplement: supplement)
                                    } label: {
                                        SupplementRowView(supplement: supplement)
                                            .cardStyle()
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            if !pastSupplements.isEmpty {
                                sectionLabel("Past")
                                ForEach(pastSupplements) { supplement in
                                    NavigationLink {
                                        SupplementDetailView(supplement: supplement)
                                    } label: {
                                        SupplementRowView(supplement: supplement)
                                            .cardStyle()
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Supplements")
            .navigationBarTitleDisplayMode(.inline)
            .background(PastelTheme.gradient.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if subscriptionManager.canAddItem(currentCount: supplements.count) {
                            showAddForm = true
                        } else {
                            showPaywall = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationDestination(isPresented: $showAddForm) {
                SupplementFormView()
            }
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.poppins(.semiBold, size: 15))
            .foregroundStyle(PastelTheme.dark)
            .padding(.top, 4)
    }
}

#Preview {
    SupplementsListView()
        .modelContainer(for: Supplement.self, inMemory: true)
        .environment(NotificationManager())
        .environment(SubscriptionManager())
}
