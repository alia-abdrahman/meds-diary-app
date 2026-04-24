import SwiftUI
import SwiftData

struct AppointmentsListView: View {
    @Query(sort: \Appointment.date) private var appointments: [Appointment]
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionManager.self) private var subscriptionManager

    @State private var showPaywall = false
    @State private var showAddForm = false
    @State private var selectedAppointment: Appointment?
    @State private var displayedMonth = Date()
    @State private var selectedDate: Date?
    @State private var showAllAppointments = false

    private var appointmentDateComponents: Set<DateComponents> {
        let calendar = Calendar.current
        return Set(appointments.map { calendar.dateComponents([.year, .month, .day], from: $0.date) })
    }

    private var upcomingAppointments: [Appointment] {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        if let selected = selectedDate {
            return appointments.filter { Calendar.current.isDate($0.date, inSameDayAs: selected) }
        }
        return appointments.filter { $0.date >= startOfToday }
    }

    var body: some View {
        NavigationStack {
            Group {
                if appointments.isEmpty {
                    ContentUnavailableView {
                        Label("No Appointments", systemImage: "calendar.badge.plus")
                    } description: {
                        Text("Track your upcoming visits")
                    } actions: {
                        Button {
                            if subscriptionManager.canAddItem(currentCount: appointments.count) {
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
                        VStack(alignment: .leading, spacing: 16) {
                            // MARK: - Header
                            HStack {
                                Text("Appointments")
                                    .font(.poppins(.bold, size: 28))
                                    .foregroundStyle(.primary)

                                Spacer()

                                Button {
                                    if subscriptionManager.canAddItem(currentCount: appointments.count) {
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

                            // MARK: - Calendar
                            MonthlyCalendarView(
                                displayedMonth: $displayedMonth,
                                selectedDate: $selectedDate,
                                appointmentDates: appointmentDateComponents
                            )

                            // MARK: - Upcoming Section
                            Text(selectedDate != nil ? "Appointments" : "Upcoming")
                                .font(.poppins(.bold, size: 18))
                                .foregroundStyle(PastelTheme.dark)
                                .padding(.top, 4)

                            if upcomingAppointments.isEmpty {
                                Text(selectedDate != nil ? "No appointments on this day" : "No upcoming appointments")
                                    .font(.poppins(.regular, size: 14))
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                            } else {
                                // Grouped appointment rows
                                VStack(spacing: 0) {
                                    ForEach(Array(upcomingAppointments.enumerated()), id: \.element.id) { index, appointment in
                                        Button {
                                            selectedAppointment = appointment
                                        } label: {
                                            appointmentRow(appointment: appointment)
                                        }
                                        .buttonStyle(.plain)
                                        .pressable()

                                        if index < upcomingAppointments.count - 1 {
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
                            if selectedDate != nil {
                                Button {
                                    withAnimation { selectedDate = nil }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "calendar")
                                            .font(.system(size: 14))
                                            .foregroundStyle(PastelTheme.dark)
                                        Text("View All Appointments")
                                            .font(.poppins(.medium, size: 14))
                                            .foregroundStyle(PastelTheme.dark)
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
                        }
                        .padding()
                        .padding(.bottom, 10)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .scrollContentBackground(.hidden)
            .background(PastelTheme.gradient.ignoresSafeArea())
            .navigationDestination(isPresented: $showAddForm) {
                AppointmentFormView()
            }
            .navigationDestination(isPresented: Binding(
                get: { selectedAppointment != nil },
                set: { if !$0 { selectedAppointment = nil } }
            )) {
                if let appointment = selectedAppointment {
                    AppointmentDetailView(appointment: appointment)
                }
            }
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Appointment Row

    private func appointmentRow(appointment: Appointment) -> some View {
        HStack(spacing: 12) {
            // Icon circle with discipline-based color
            Circle()
                .fill(iconColor(for: appointment.discipline).opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: disciplineIcon(for: appointment.discipline))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(iconColor(for: appointment.discipline))
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(appointment.discipline)
                    .font(.poppins(.semiBold, size: 15))
                    .foregroundStyle(.primary)

                Text("\(appointment.date.formatted(.dateTime.day().month(.abbreviated).year())) · \(appointment.time.formatted(date: .omitted, time: .shortened))")
                    .font(.poppins(.regular, size: 13))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(abbreviation(for: appointment.discipline))
                .font(.poppins(.medium, size: 12))
                .foregroundStyle(iconColor(for: appointment.discipline))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(iconColor(for: appointment.discipline).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helpers

    private func iconColor(for discipline: String) -> Color {
        switch discipline.lowercased() {
        case let d where d.contains("pulmo"): return PastelTheme.dark
        case let d where d.contains("medical") || d.contains("med"): return PastelTheme.pinkAccent
        case let d where d.contains("psych"): return PastelTheme.primary
        case let d where d.contains("cardio"): return .red.opacity(0.8)
        case let d where d.contains("dent"): return PastelTheme.green
        case let d where d.contains("ortho"): return PastelTheme.orange
        case let d where d.contains("neur"): return .purple.opacity(0.7)
        default: return PastelTheme.dark
        }
    }

    private func disciplineIcon(for discipline: String) -> String {
        switch discipline.lowercased() {
        case let d where d.contains("psych"): return "brain.head.profile"
        case let d where d.contains("cardio") || d.contains("heart"): return "heart.fill"
        case let d where d.contains("dent"): return "mouth.fill"
        case let d where d.contains("eye") || d.contains("ophthal"): return "eye.fill"
        case let d where d.contains("ortho") || d.contains("bone"): return "figure.walk"
        case let d where d.contains("derma") || d.contains("skin"): return "hand.raised.fill"
        case let d where d.contains("neur"): return "brain"
        case let d where d.contains("pediatr") || d.contains("child"): return "figure.and.child.holdinghands"
        default: return "stethoscope"
        }
    }

    private func abbreviation(for discipline: String) -> String {
        switch discipline {
        case "Psychiatry": return "PSY"
        case "Pulmonology": return "PUL"
        case "D&G": return "D&G"
        case "Medical": return "MED"
        case "Surgery": return "SRG"
        case "Orthopaedics": return "ORT"
        case "ENT": return "ENT"
        case "Ophthalmology": return "OPH"
        case "Dermatology": return "DRM"
        case "Paediatrics": return "PED"
        case "Cardiology": return "CAR"
        case "Neurology": return "NEU"
        case "Endocrinology": return "END"
        default: return String(discipline.prefix(3)).uppercased()
        }
    }
}

#Preview {
    AppointmentsListView()
        .modelContainer(for: Appointment.self, inMemory: true)
        .environment(SubscriptionManager())
}
