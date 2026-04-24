import SwiftUI
import SwiftData

struct MedicinesListView: View {
    @Query(sort: \Medicine.name) private var medicines: [Medicine]
    @Environment(\.modelContext) private var modelContext
    @Environment(NotificationManager.self) private var notificationManager
    @Environment(SubscriptionManager.self) private var subscriptionManager

    @Query(sort: \Supplement.name) private var allSupplements: [Supplement]

    @State private var showPaywall = false
    @State private var showAddForm = false
    @State private var showMilestone = false
    @State private var milestoneValue = 0
    @State private var showAllMedicines = false

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
                        .buttonStyle(.plain)
                        .pressable()
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // MARK: - Header
                            HStack {
                                Text("Medicines")
                                    .font(.poppins(.bold, size: 28))
                                    .foregroundStyle(.primary)

                                Spacer()

                                Button {
                                    if subscriptionManager.canAddItem(currentCount: medicines.count) {
                                        showAddForm = true
                                    } else {
                                        showPaywall = true
                                    }
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(PastelTheme.dark)
                                        .frame(width: 46, height: 46)
                                        .background(PastelTheme.light.opacity(0.6))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.top, 8)

                            // MARK: - Streak Card
                            if !activeMedicines.isEmpty {
                                StreakCard(
                                    streak: StreakManager.overallStreak(medicines: medicines, supplements: allSupplements),
                                    weeklyPercentage: StreakManager.weeklyAdherence(medicines: medicines, supplements: allSupplements).percentage
                                )
                            }

                            // MARK: - Active Medicines
                            if !activeMedicines.isEmpty {
                                Text("Active Medicines")
                                    .font(.poppins(.bold, size: 18))
                                    .foregroundStyle(PastelTheme.dark)
                                    .padding(.top, 4)

                                VStack(spacing: 0) {
                                    ForEach(Array(activeMedicines.enumerated()), id: \.element.id) { index, medicine in
                                        NavigationLink {
                                            MedicineDetailView(medicine: medicine)
                                        } label: {
                                            medicineRow(medicine: medicine)
                                        }
                                        .buttonStyle(.plain)
                                        .pressable()

                                        if index < activeMedicines.count - 1 {
                                            Divider()
                                                .padding(.horizontal, 16)
                                        }
                                    }
                                }
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                            }

                            // MARK: - Past Medicines
                            if !pastMedicines.isEmpty {
                                Text("Past Medicines")
                                    .font(.poppins(.bold, size: 18))
                                    .foregroundStyle(PastelTheme.dark)
                                    .padding(.top, 4)

                                VStack(spacing: 0) {
                                    ForEach(Array(pastMedicines.enumerated()), id: \.element.id) { index, medicine in
                                        NavigationLink {
                                            MedicineDetailView(medicine: medicine)
                                        } label: {
                                            medicineRow(medicine: medicine)
                                        }
                                        .buttonStyle(.plain)
                                        .pressable()

                                        if index < pastMedicines.count - 1 {
                                            Divider()
                                                .padding(.horizontal, 16)
                                        }
                                    }
                                }
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                            }

                            // MARK: - View All Link
                            NavigationLink {
                                AllMedicinesView(medicines: medicines)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "list.bullet")
                                        .font(.system(size: 14))
                                        .foregroundStyle(PastelTheme.dark)
                                    Text("View All Medicines")
                                        .font(.poppins(.medium, size: 14))
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(.tertiary)
                                }
                                .padding()
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding()
                        .padding(.bottom, 10)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .background(PastelTheme.gradient.ignoresSafeArea())
            .navigationDestination(isPresented: $showAddForm) {
                MedicineFormView()
            }
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallView()
            }
            .onAppear {
                let streak = StreakManager.overallStreak(medicines: medicines, supplements: allSupplements)
                if let milestone = MilestoneTracker.shouldCelebrate(streak: streak) {
                    milestoneValue = milestone
                    MilestoneTracker.markCelebrated(milestone)
                    showMilestone = true
                }
            }
            .overlay {
                if showMilestone {
                    MilestoneOverlay(milestone: milestoneValue) {
                        showMilestone = false
                    }
                }
            }
        }
    }

    // MARK: - Medicine Row

    private func medicineRow(medicine: Medicine) -> some View {
        HStack(spacing: 12) {
            // Pill icon in light blue circle
            Circle()
                .fill(PastelTheme.primary.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "pill.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(PastelTheme.dark)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(medicine.name)
                    .font(.poppins(.semiBold, size: 15))
                    .foregroundStyle(.primary)

                Text("Take \(medicine.frequency.lowercased())")
                    .font(.poppins(.regular, size: 13))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(medicine.frequency)
                .font(.poppins(.medium, size: 12))
                .foregroundStyle(PastelTheme.dark)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(PastelTheme.light.opacity(0.5))
                .clipShape(Capsule())

            Image(systemName: medicine.isTakenToday ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22))
                .foregroundStyle(medicine.isTakenToday ? PastelTheme.green : PastelTheme.pinkAccent)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - All Medicines View

private struct AllMedicinesView: View {
    let medicines: [Medicine]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(PastelTheme.dark)
                            .frame(width: 40, height: 40)
                            .background(PastelTheme.light.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    Text("All Medicines")
                        .font(.poppins(.bold, size: 24))
                        .foregroundStyle(.primary)

                    Spacer()
                }
                .padding(.top, 8)

                VStack(spacing: 0) {
                    ForEach(Array(medicines.enumerated()), id: \.element.id) { index, medicine in
                        NavigationLink {
                            MedicineDetailView(medicine: medicine)
                        } label: {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(PastelTheme.primary.opacity(0.2))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Image(systemName: "pill.fill")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundStyle(PastelTheme.dark)
                                    )

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(medicine.name)
                                        .font(.poppins(.semiBold, size: 15))
                                        .foregroundStyle(.primary)

                                    Text(medicine.isActive ? "Active" : "Past")
                                        .font(.poppins(.regular, size: 13))
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Text(medicine.frequency)
                                    .font(.poppins(.medium, size: 12))
                                    .foregroundStyle(PastelTheme.dark)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(PastelTheme.light.opacity(0.5))
                                    .clipShape(Capsule())

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                        .pressable()

                        if index < medicines.count - 1 {
                            Divider()
                                .padding(.horizontal, 16)
                        }
                    }
                }
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            }
            .padding()
            .padding(.bottom, 10)
        }
        .scrollContentBackground(.hidden)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .background(PastelTheme.gradient.ignoresSafeArea())
    }
}

#Preview {
    MedicinesListView()
        .modelContainer(for: Medicine.self, inMemory: true)
        .environment(NotificationManager())
        .environment(SubscriptionManager())
}
