import SwiftUI
import SwiftData

struct DashboardView: View {
    @Binding var selectedTab: AppTab

    @Query(sort: \Appointment.date) private var allAppointments: [Appointment]

    @Query(sort: \Medicine.name) private var allMedicines: [Medicine]

    @Query(sort: \Supplement.name) private var allSupplements: [Supplement]

    @Query(sort: \MoodEntry.date) private var moodEntries: [MoodEntry]

    @State private var showNewAppointment = false
    @State private var showNewMedicine = false
    @State private var showNewSupplement = false
    @State private var showMoodCheckIn = false
    @State private var showConfetti = false
    @State private var confettiID = UUID()
    @State private var lastSeenTakenCount = -1
    @State private var hasCelebratedThisSession = false

    private var activeMedicines: [Medicine] {
        allMedicines.filter(\.isActive)
    }

    private var activeSupplements: [Supplement] {
        allSupplements.filter(\.isActive)
    }

    private var hasMoodToday: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return moodEntries.contains { calendar.startOfDay(for: $0.date) == today }
    }

    private var allTakenToday: Bool {
        let medicines = activeMedicines
        let supplements = activeSupplements
        guard !medicines.isEmpty || !supplements.isEmpty else { return false }
        return medicines.allSatisfy(\.isTakenToday) && supplements.allSatisfy(\.isTakenToday)
    }

    private var takenCount: Int {
        activeMedicines.filter(\.isTakenToday).count + activeSupplements.filter(\.isTakenToday).count
    }

    private var totalActiveCount: Int {
        activeMedicines.count + activeSupplements.count
    }

    private func checkAndCelebrate() {
        let current = takenCount
        let total = totalActiveCount
        guard total > 0 else { return }

        if current == total && !hasCelebratedThisSession {
            hasCelebratedThisSession = true
            confettiID = UUID()
            showConfetti = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                showConfetti = false
            }
            if !hasMoodToday {
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                    showMoodCheckIn = true
                }
            }
        }

        if current < total {
            hasCelebratedThisSession = false
        }

        lastSeenTakenCount = current
    }

    private var recentAppointments: [Appointment] {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        return allAppointments
            .filter { $0.date >= startOfToday }
            .prefix(3)
            .map { $0 }
    }

    var body: some View {
        ZStack {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // MARK: - Header
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Meds Diary")
                                    .font(.poppins(.bold, size: 28))
                                    .foregroundStyle(.primary)
                                Text("Your health, organized.")
                                    .font(.poppins(.regular, size: 15))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            NavigationLink {
                                MoodHistoryView()
                            } label: {
                                Image(systemName: "face.smiling")
                                    .font(.system(size: 22))
                                    .foregroundStyle(PastelTheme.dark)
                                    .frame(width: 46, height: 46)
                                    .background(PastelTheme.light.opacity(0.6))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.top, 8)

                        // MARK: - Upcoming Appointments
                        sectionHeader("Upcoming Appointments", icon: "calendar", actionLabel: "View all", tab: .appointments)

                        if recentAppointments.isEmpty {
                            emptyCard(message: "Add your first appointment") {
                                showNewAppointment = true
                            }
                        } else {
                            VStack(spacing: 10) {
                                ForEach(recentAppointments) { appointment in
                                    NavigationLink {
                                        AppointmentDetailView(appointment: appointment)
                                    } label: {
                                        AppointmentDashboardCard(appointment: appointment)
                                    }
                                    .buttonStyle(.plain)
                                    .pressable()
                                }
                            }
                        }

                        // MARK: - Today's Medicines
                        sectionHeader("Today's Medicines", icon: "pill.fill", actionLabel: "Manage", tab: .medicines)

                        if activeMedicines.isEmpty {
                            emptyCard(message: "Add your first medicine") {
                                showNewMedicine = true
                            }
                        } else {
                            VStack(spacing: 0) {
                                ForEach(Array(activeMedicines.enumerated()), id: \.element.id) { index, medicine in
                                    NavigationLink {
                                        MedicineDetailView(medicine: medicine)
                                    } label: {
                                        TodayMedicineCard(medicine: medicine)
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

                        // MARK: - Today's Supplements
                        sectionHeader("Today's Supplements", icon: "leaf.fill", actionLabel: "Manage", tab: .supplements)

                        if activeSupplements.isEmpty {
                            emptyCard(message: "Add your first supplement") {
                                showNewSupplement = true
                            }
                        } else {
                            VStack(spacing: 0) {
                                ForEach(Array(activeSupplements.enumerated()), id: \.element.id) { index, supplement in
                                    NavigationLink {
                                        SupplementDetailView(supplement: supplement)
                                    } label: {
                                        TodaySupplementCard(supplement: supplement)
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

                    }
                    .padding()
                }
                .scrollContentBackground(.hidden)
                .toolbar(.hidden, for: .navigationBar)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(PastelTheme.gradient.ignoresSafeArea())
                .onAppear {
                    if lastSeenTakenCount == -1 {
                        lastSeenTakenCount = takenCount
                        if allTakenToday { hasCelebratedThisSession = true }
                    }
                }
                .onChange(of: takenCount) { _, _ in
                    checkAndCelebrate()
                }
                .navigationDestination(isPresented: $showNewAppointment) {
                    AppointmentFormView()
                }
                .navigationDestination(isPresented: $showNewMedicine) {
                    MedicineFormView()
                }
                .navigationDestination(isPresented: $showNewSupplement) {
                    SupplementFormView()
                }
                .sheet(isPresented: $showMoodCheckIn) {
                    MoodCheckInView()
                        .presentationDetents([.medium])
                        .presentationDragIndicator(.visible)
                }
            }

            if showConfetti {
                SparkleOverlay()
                    .id(confettiID)
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
            }
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String, icon: String, actionLabel: String, tab: AppTab) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.poppins(.bold, size: 18))
                .foregroundStyle(PastelTheme.dark)

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    selectedTab = tab
                }
            } label: {
                HStack(spacing: 2) {
                    Text(actionLabel)
                        .font(.poppins(.medium, size: 13))
                        .foregroundStyle(PastelTheme.dark)
                    if actionLabel == "View all" {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(PastelTheme.dark)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Empty Card

    private func emptyCard(message: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(PastelTheme.primary)
                Text(message)
                    .font(.poppins(.regular, size: 15))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .padding()
            .background(Color.white.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(PastelTheme.light, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Appointment Dashboard Card

private struct AppointmentDashboardCard: View {
    let appointment: Appointment
    @State private var isBouncing = false

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(PastelTheme.light)
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: disciplineIcon(for: appointment.discipline))
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(PastelTheme.dark)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(appointment.discipline)
                    .font(.poppins(.semiBold, size: 16))
                    .foregroundStyle(.primary)

                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Text(appointment.date.formatted(.dateTime.day().month(.abbreviated).year()))
                        .font(.poppins(.regular, size: 13))
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Text(appointment.time.formatted(date: .omitted, time: .shortened))
                        .font(.poppins(.regular, size: 13))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.system(size: 11))
                Text(dayCountdown(for: appointment.date))
                    .font(.poppins(.semiBold, size: 13))
            }
            .foregroundStyle(countdownColor)
            .scaleEffect(isBouncing && isUpcoming ? 1.1 : 1.0)
            .onAppear {
                guard isUpcoming else { return }
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    isBouncing = true
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: 12))
    }

    private var isUpcoming: Bool {
        appointment.date >= Calendar.current.startOfDay(for: Date())
    }

    private var countdownColor: Color {
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: appointment.date)).day ?? 0
        if days <= 1 { return .red }
        if days <= 7 { return PastelTheme.orange }
        return PastelTheme.dark
    }

    private func dayCountdown(for date: Date) -> String {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfTarget = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: startOfToday, to: startOfTarget).day ?? 0

        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Tomorrow"
        } else if days == -1 {
            return "Yesterday"
        } else if days > 1 {
            return "In \(days) days"
        } else {
            return "\(abs(days))d ago"
        }
    }

    private func disciplineIcon(for discipline: String) -> String {
        switch discipline.lowercased() {
        case let d where d.contains("psych"): "brain.head.profile"
        case let d where d.contains("cardio") || d.contains("heart"): "heart.fill"
        case let d where d.contains("dent"): "mouth.fill"
        case let d where d.contains("eye") || d.contains("ophthal"): "eye.fill"
        case let d where d.contains("ortho") || d.contains("bone"): "figure.walk"
        case let d where d.contains("derma") || d.contains("skin"): "hand.raised.fill"
        case let d where d.contains("neur"): "brain"
        case let d where d.contains("pediatr") || d.contains("child"): "figure.and.child.holdinghands"
        default: "stethoscope"
        }
    }
}

#Preview {
    DashboardView(selectedTab: .constant(.home))
        .modelContainer(for: [Appointment.self, Medicine.self, Supplement.self, MoodEntry.self], inMemory: true)
        .environment(NotificationManager())
        .environment(SubscriptionManager())
}
