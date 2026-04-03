import SwiftUI
import SwiftData

struct AppointmentsListView: View {
    @Query(sort: \Appointment.date, order: .reverse) private var appointments: [Appointment]
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionManager.self) private var subscriptionManager

    @State private var showPaywall = false
    @State private var showAddForm = false
    @State private var selectedAppointment: Appointment?

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
                        VStack(spacing: 0) {
                            ForEach(groupedByMonth, id: \.key) { month, items in
                                // Month section header
                                HStack {
                                    Text(month)
                                        .font(.poppins(.semiBold, size: 16))
                                        .foregroundStyle(PastelTheme.dark)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 20)
                                .padding(.bottom, 8)

                                // Table card
                                VStack(spacing: 0) {
                                    // Column headers
                                    tableHeader

                                    Divider()
                                        .background(PastelTheme.light)

                                    // Data rows
                                    ForEach(Array(items.enumerated()), id: \.element.id) { index, appointment in
                                        PressableTableRow {
                                            tableRow(index: index + 1, appointment: appointment, isEven: index % 2 == 0)
                                        } onTap: {
                                            selectedAppointment = appointment
                                        }

                                        if index < items.count - 1 {
                                            Divider()
                                                .background(PastelTheme.light.opacity(0.5))
                                                .padding(.horizontal, 12)
                                        }
                                    }
                                }
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Appointments")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(PastelTheme.gradient.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if subscriptionManager.canAddItem(currentCount: appointments.count) {
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

    // MARK: - Table Header

    private var tableHeader: some View {
        HStack(spacing: 8) {
            Text("Date")
                .frame(width: 50, alignment: .leading)

            Text("Time")
                .frame(width: 58, alignment: .leading)

            Text("Category")
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Notes")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.poppins(.semiBold, size: 15))
        .foregroundStyle(PastelTheme.dark)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(PastelTheme.light.opacity(0.3))
    }

    // MARK: - Table Row

    private func tableRow(index: Int, appointment: Appointment, isEven: Bool) -> some View {
        HStack(spacing: 8) {
            // Date
            Text(appointment.date.formatted(.dateTime.day().month(.abbreviated)))
                .font(.poppins(.regular, size: 15))
                .foregroundStyle(.primary)
                .frame(width: 50, alignment: .leading)

            // Time
            Text(appointment.time.formatted(date: .omitted, time: .shortened))
                .font(.poppins(.regular, size: 15))
                .foregroundStyle(.primary)
                .frame(width: 58, alignment: .leading)

            // Category badge
            Text(abbreviation(for: appointment.discipline))
                .font(.poppins(.medium, size: 13))
                .foregroundStyle(PastelTheme.dark)
                .lineLimit(1)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(PastelTheme.light)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .frame(maxWidth: .infinity, alignment: .leading)

            // Notes
            Text(appointment.notes.isEmpty ? "—" : appointment.notes)
                .font(.poppins(.regular, size: 15))
                .foregroundStyle(appointment.notes.isEmpty ? .tertiary : .primary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(isEven ? Color.clear : PastelTheme.light.opacity(0.15))
        .contentShape(Rectangle())
    }

    // MARK: - Helpers

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

    private var groupedByMonth: [(key: String, value: [Appointment])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let grouped = Dictionary(grouping: appointments) { formatter.string(from: $0.date) }
        return grouped.sorted { $0.value.first?.date ?? .distantPast > $1.value.first?.date ?? .distantPast }
    }
}

private struct PressableTableRow<Content: View>: View {
    let content: Content
    let onTap: () -> Void
    @State private var isPressed = false

    init(@ViewBuilder content: () -> Content, onTap: @escaping () -> Void) {
        self.content = content()
        self.onTap = onTap
    }

    var body: some View {
        content
            .overlay(isPressed ? PastelTheme.light.opacity(0.5) : Color.clear)
            .opacity(isPressed ? 0.85 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in
                        isPressed = false
                        onTap()
                    }
            )
    }
}

#Preview {
    AppointmentsListView()
        .modelContainer(for: Appointment.self, inMemory: true)
        .environment(SubscriptionManager())
}
