import SwiftUI
import SwiftData

struct AppointmentDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(NotificationManager.self) private var notificationManager

    let appointment: Appointment

    @State private var showingDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // MARK: - Header
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

                    Spacer()

                    Text(appointment.discipline)
                        .font(.poppins(.bold, size: 20))
                        .foregroundStyle(.primary)

                    Spacer()

                    NavigationLink {
                        AppointmentFormView(appointment: appointment)
                    } label: {
                        Text("Edit")
                            .font(.poppins(.medium, size: 15))
                            .foregroundStyle(PastelTheme.dark)
                    }
                }
                .padding(.top, 8)

                // MARK: - Status Card
                HStack {
                    Label(displayStatus, systemImage: "calendar.badge.clock")
                        .font(.poppins(.semiBold, size: 15))
                        .foregroundStyle(statusColor)

                    Spacer()

                    Text(dayCountdown)
                        .font(.poppins(.medium, size: 13))
                        .foregroundStyle(PastelTheme.dark)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(PastelTheme.light.opacity(0.4))
                        .clipShape(Capsule())
                }
                .padding()
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

                // MARK: - Details Card
                VStack(spacing: 0) {
                    detailRow(icon: "calendar", label: "Date", value: appointment.date.formatted(.dateTime.day().month(.wide).year()))

                    Divider().padding(.horizontal, 16)

                    detailRow(icon: "clock", label: "Time", value: appointment.time.formatted(date: .omitted, time: .shortened))

                    Divider().padding(.horizontal, 16)

                    detailRow(icon: "stethoscope", label: "Department", value: appointment.discipline)

                    Divider().padding(.horizontal, 16)

                    detailRow(icon: "building.2", label: "Hospital", value: appointment.hospitalName)

                    if !appointment.doctorName.isEmpty {
                        Divider().padding(.horizontal, 16)

                        detailRow(icon: "person", label: "Doctor", value: appointment.doctorName)
                    }
                }
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

                // MARK: - Notes Card
                VStack(alignment: .leading, spacing: 8) {
                    Label("Notes", systemImage: "doc.text")
                        .font(.poppins(.semiBold, size: 15))
                        .foregroundStyle(.primary)

                    Text(appointment.notes.isEmpty ? "No notes added" : appointment.notes)
                        .font(.poppins(.regular, size: 14))
                        .foregroundStyle(appointment.notes.isEmpty ? .secondary : .primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

                // MARK: - Delete Button
                Button {
                    showingDeleteConfirmation = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                        Text("Delete Appointment")
                            .font(.poppins(.medium, size: 15))
                    }
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
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
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .background(PastelTheme.gradient.ignoresSafeArea())
        .alert("Delete Appointment", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                notificationManager.cancelAppointmentReminders(for: appointment)
                modelContext.delete(appointment)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this appointment?")
        }
    }

    // MARK: - Detail Row

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .frame(width: 24)

            Text(label)
                .font(.poppins(.medium, size: 14))
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.poppins(.semiBold, size: 15))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Helpers

    private var displayStatus: String {
        switch appointment.status {
        case "attended": "Attended"
        case "missed", "not attended": "Not Attended"
        case "cancelled": "Cancelled"
        default: "Upcoming"
        }
    }

    private var statusColor: Color {
        switch appointment.status {
        case "attended": PastelTheme.green
        case "missed", "not attended": PastelTheme.orange
        case "cancelled": PastelTheme.gray
        default: PastelTheme.dark
        }
    }

    private var dayCountdown: String {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfTarget = calendar.startOfDay(for: appointment.date)
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
}
