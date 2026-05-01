import SwiftUI
import SwiftData

struct SupplementsListView: View {
    @Query(sort: \Supplement.name) private var supplementsRaw: [Supplement]
    @Environment(\.modelContext) private var modelContext
    @Environment(NotificationManager.self) private var notificationManager
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(PersonContext.self) private var personContext

    @Query(sort: \Medicine.name) private var allMedicinesRaw: [Medicine]

    @State private var showPaywall = false
    @State private var showAddForm = false
    @State private var showMilestone = false
    @State private var milestoneValue = 0

    private var supplements: [Supplement] {
        guard let id = personContext.activePersonID else { return supplementsRaw }
        return supplementsRaw.filter { $0.personId == id }
    }

    private var allMedicines: [Medicine] {
        guard let id = personContext.activePersonID else { return allMedicinesRaw }
        return allMedicinesRaw.filter { $0.personId == id }
    }

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
                        .buttonStyle(.plain)
                        .pressable()
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // MARK: - Header
                            HStack {
                                Text("Supplements")
                                    .font(.poppins(.bold, size: 28))
                                    .foregroundStyle(.primary)

                                Spacer()

                                Button {
                                    if subscriptionManager.canAddItem(currentCount: supplements.count) {
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
                            if !activeSupplements.isEmpty {
                                StreakCard(
                                    streak: StreakManager.overallStreak(medicines: allMedicines, supplements: supplements),
                                    weeklyPercentage: StreakManager.weeklyAdherence(medicines: allMedicines, supplements: supplements).percentage
                                )
                            }

                            // MARK: - Active Supplements
                            if !activeSupplements.isEmpty {
                                Text("Active Supplements")
                                    .font(.poppins(.bold, size: 18))
                                    .foregroundStyle(PastelTheme.dark)
                                    .padding(.top, 4)

                                VStack(spacing: 0) {
                                    ForEach(Array(activeSupplements.enumerated()), id: \.element.id) { index, supplement in
                                        NavigationLink {
                                            SupplementDetailView(supplement: supplement)
                                        } label: {
                                            supplementRow(supplement: supplement)
                                        }
                                        .buttonStyle(.plain)
                                        .pressable()

                                        if index < activeSupplements.count - 1 {
                                            Divider()
                                                .padding(.horizontal, 16)
                                        }
                                    }
                                }
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                            }

                            // MARK: - Past Supplements
                            if !pastSupplements.isEmpty {
                                Text("Past Supplements")
                                    .font(.poppins(.bold, size: 18))
                                    .foregroundStyle(PastelTheme.dark)
                                    .padding(.top, 4)

                                VStack(spacing: 0) {
                                    ForEach(Array(pastSupplements.enumerated()), id: \.element.id) { index, supplement in
                                        NavigationLink {
                                            SupplementDetailView(supplement: supplement)
                                        } label: {
                                            supplementRow(supplement: supplement)
                                        }
                                        .buttonStyle(.plain)
                                        .pressable()

                                        if index < pastSupplements.count - 1 {
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
                                AllSupplementsView(supplements: supplements)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "list.bullet")
                                        .font(.system(size: 14))
                                        .foregroundStyle(PastelTheme.dark)
                                    Text("View All Supplements")
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
                SupplementFormView()
            }
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallView()
            }
            .onAppear {
                let streak = StreakManager.overallStreak(medicines: allMedicines, supplements: supplements)
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

    // MARK: - Supplement Row

    private func supplementRow(supplement: Supplement) -> some View {
        HStack(spacing: 12) {
            // Leaf icon in light green circle
            Circle()
                .fill(PastelTheme.green.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(PastelTheme.green)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(supplement.name)
                    .font(.poppins(.semiBold, size: 15))
                    .foregroundStyle(.primary)

                Text("Take \(supplement.frequency.lowercased())")
                    .font(.poppins(.regular, size: 13))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(supplement.frequency)
                .font(.poppins(.medium, size: 12))
                .foregroundStyle(PastelTheme.dark)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(PastelTheme.light.opacity(0.5))
                .clipShape(Capsule())

            Image(systemName: supplement.isTakenToday ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22))
                .foregroundStyle(supplement.isTakenToday ? PastelTheme.green : PastelTheme.pinkAccent)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - All Supplements View

private struct AllSupplementsView: View {
    let supplements: [Supplement]
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

                    Text("All Supplements")
                        .font(.poppins(.bold, size: 24))
                        .foregroundStyle(.primary)

                    Spacer()
                }
                .padding(.top, 8)

                VStack(spacing: 0) {
                    ForEach(Array(supplements.enumerated()), id: \.element.id) { index, supplement in
                        NavigationLink {
                            SupplementDetailView(supplement: supplement)
                        } label: {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(PastelTheme.green.opacity(0.2))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Image(systemName: "leaf.fill")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundStyle(PastelTheme.green)
                                    )

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(supplement.name)
                                        .font(.poppins(.semiBold, size: 15))
                                        .foregroundStyle(.primary)

                                    Text(supplement.isActive ? "Active" : "Past")
                                        .font(.poppins(.regular, size: 13))
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Text(supplement.frequency)
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

                        if index < supplements.count - 1 {
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
    SupplementsListView()
        .modelContainer(for: [Supplement.self, Medicine.self, Person.self], inMemory: true)
        .environment(NotificationManager())
        .environment(SubscriptionManager())
        .environment(PersonContext())
}
