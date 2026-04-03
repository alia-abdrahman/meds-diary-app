import SwiftUI
import SwiftData

struct MedicinesListView: View {
    @Query(sort: \Medicine.name) private var medicines: [Medicine]
    @Environment(\.modelContext) private var modelContext
    @Environment(NotificationManager.self) private var notificationManager
    @Environment(SubscriptionManager.self) private var subscriptionManager

    @State private var showPaywall = false
    @State private var showAddForm = false

    private var activeMedicines: [Medicine] { medicines.filter(\.isActive) }
    private var pastMedicines: [Medicine] { medicines.filter { !$0.isActive } }

    var body: some View {
        NavigationStack {
            Group {
                if medicines.isEmpty {
                    ContentUnavailableView {
                        Label("No Medicines", systemImage: "pill")
                    } description: {
                        Text("Track your medications")
                    } actions: {
                        Button {
                            if subscriptionManager.canAddItem(currentCount: medicines.count) {
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
                            if !activeMedicines.isEmpty {
                                sectionLabel("Active")
                                ForEach(activeMedicines) { medicine in
                                    NavigationLink {
                                        MedicineDetailView(medicine: medicine)
                                    } label: {
                                        MedicineRowView(medicine: medicine)
                                            .cardStyle()
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            if !pastMedicines.isEmpty {
                                sectionLabel("Past")
                                ForEach(pastMedicines) { medicine in
                                    NavigationLink {
                                        MedicineDetailView(medicine: medicine)
                                    } label: {
                                        MedicineRowView(medicine: medicine)
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
            .navigationTitle("Medicines")
            .navigationBarTitleDisplayMode(.inline)
            .background(PastelTheme.gradient.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if subscriptionManager.canAddItem(currentCount: medicines.count) {
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
                MedicineFormView()
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
    MedicinesListView()
        .modelContainer(for: Medicine.self, inMemory: true)
        .environment(NotificationManager())
        .environment(SubscriptionManager())
}
