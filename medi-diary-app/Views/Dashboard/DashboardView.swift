import SwiftUI
import SwiftData

struct DashboardView: View {
    @Binding var selectedTab: AppTab

    @Query(sort: \Appointment.date) private var allAppointments: [Appointment]

    @Query(sort: \Medicine.name) private var allMedicines: [Medicine]

    @Query(sort: \Supplement.name) private var allSupplements: [Supplement]

    @State private var showNewAppointment = false
    @State private var showNewMedicine = false
    @State private var showNewSupplement = false

    private var activeMedicines: [Medicine] {
        allMedicines.filter(\.isActive)
    }

    private var activeSupplements: [Supplement] {
        allSupplements.filter(\.isActive)
    }

    private var recentAppointments: [Appointment] {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        return allAppointments
            .filter { $0.date >= startOfToday }
            .prefix(3)
            .map { $0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    sectionHeader("Appointments", icon: "calendar")

                    if recentAppointments.isEmpty {
                        emptyCard(message: "Add your first appointment") {
                            showNewAppointment = true
                        }
                    } else {
                        recentAppointmentsTable
                    }

                    sectionHeader("Today's Medicines", icon: "pill.fill")

                    if activeMedicines.isEmpty {
                        emptyCard(message: "Add your first medicine") {
                            showNewMedicine = true
                        }
                    } else {
                        ForEach(activeMedicines) { medicine in
                            NavigationLink {
                                MedicineDetailView(medicine: medicine)
                            } label: {
                                TodayMedicineCard(medicine: medicine)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    sectionHeader("Today's Supplements", icon: "leaf.fill")

                    if activeSupplements.isEmpty {
                        emptyCard(message: "Add your first supplement") {
                            showNewSupplement = true
                        }
                    } else {
                        ForEach(activeSupplements) { supplement in
                            NavigationLink {
                                SupplementDetailView(supplement: supplement)
                            } label: {
                                TodaySupplementCard(supplement: supplement)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Meds Diary")
            .navigationBarTitleDisplayMode(.inline)
.pastelGradientBackground()
            .navigationDestination(isPresented: $showNewAppointment) {
                AppointmentFormView()
            }
            .navigationDestination(isPresented: $showNewMedicine) {
                MedicineFormView()
            }
            .navigationDestination(isPresented: $showNewSupplement) {
                SupplementFormView()
            }
        }
    }

    private var recentAppointmentsTable: some View {
        VStack(spacing: 10) {
            ForEach(recentAppointments) { appointment in
                AppointmentDashboardCard(appointment: appointment) {
                    selectedTab = .appointments
                }
            }
        }
    }

    private func sectionHeader(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.poppins(.bold, size: 20))
            .foregroundStyle(PastelTheme.dark)
    }

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

private struct AppointmentDashboardCard: View {
    let appointment: Appointment
    var onTap: () -> Void
    @State private var isBouncing = false
    @State private var isPressed = false

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(PastelTheme.light)
                .frame(width: 42, height: 42)
                .overlay(
                    Image(systemName: disciplineIcon(for: appointment.discipline))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(PastelTheme.dark)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(appointment.discipline)
                    .font(.poppins(.semiBold, size: 15))
                    .foregroundStyle(.primary)

                HStack(spacing: 4) {
                    Text(appointment.date.formatted(.dateTime.day().month(.abbreviated)))
                    Text("•")
                    Text(appointment.time.formatted(date: .omitted, time: .shortened))
                }
                .font(.poppins(.regular, size: 13))
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text(dayCountdown(for: appointment.date))
                .font(.poppins(.semiBold, size: 14))
                .foregroundStyle(countdownColor)
                .scaleEffect(isBouncing && isUpcoming ? 1.15 : 1.0)
                .animation(
                    isUpcoming ? .easeInOut(duration: 1.2).repeatForever(autoreverses: true) : .default,
                    value: isBouncing
                )
                .onAppear { isBouncing = true }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .opacity(isPressed ? 0.8 : 1.0)
        .animation(.easeInOut(duration: 0.12), value: isPressed)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in
                    isPressed = false
                    onTap()
                }
        )
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
        .modelContainer(for: [Appointment.self, Medicine.self, Supplement.self], inMemory: true)
}
