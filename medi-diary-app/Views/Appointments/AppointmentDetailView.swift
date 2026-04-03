import SwiftUI
import SwiftData

struct AppointmentDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let appointment: Appointment

    @State private var showingDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Status card
                HStack(spacing: 12) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 12, height: 12)

                    Text(appointment.status.capitalized)
                        .font(.poppins(.semiBold, size: 16))
                        .foregroundStyle(statusColor)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()

                // Details card
                VStack(alignment: .leading, spacing: 14) {
                    detailRow("Date", value: appointment.date.formatted(.dateTime.day().month(.wide).year()), icon: "calendar")

                    detailRow("Time", value: appointment.time.formatted(date: .omitted, time: .shortened), icon: "clock.fill")

                    detailRow("Department", value: appointment.discipline, icon: "stethoscope")

                    detailRow("Hospital", value: appointment.hospitalName, icon: "building.2.fill")

                    if !appointment.doctorName.isEmpty {
                        detailRow("Doctor", value: appointment.doctorName, icon: "person.fill")
                    }

                    if !appointment.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Notes", systemImage: "note.text")
                                .font(.poppins(.medium, size: 14))
                                .foregroundStyle(.secondary)

                            Text(appointment.notes)
                                .font(.poppins(.regular, size: 15))
                                .padding(.leading, 28)
                        }
                    }
                }
                .cardStyle()

                // Delete button
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete Appointment")
                    }
                    .font(.poppins(.medium, size: 15))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red)
            }
            .padding()
        }
        .background(PastelTheme.gradient.ignoresSafeArea())
        .navigationTitle(appointment.discipline)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    AppointmentFormView(appointment: appointment)
                } label: {
                    Text("Edit")
                }
            }
        }
        .alert("Delete Appointment", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                modelContext.delete(appointment)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this appointment?")
        }
    }

    private var statusColor: Color {
        switch appointment.status {
        case "attended": PastelTheme.green
        case "missed": PastelTheme.orange
        case "cancelled": PastelTheme.gray
        default: PastelTheme.primary
        }
    }

    private func detailRow(_ label: String, value: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Label(label, systemImage: icon)
                .font(.poppins(.medium, size: 14))
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.poppins(.regular, size: 15))
        }
    }
}
