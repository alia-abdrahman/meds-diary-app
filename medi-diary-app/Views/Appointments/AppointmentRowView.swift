import SwiftUI

struct AppointmentRowView: View {
    let appointment: Appointment

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            Circle()
                .fill(PastelTheme.light)
                .frame(width: 42, height: 42)
                .overlay(
                    Image(systemName: disciplineIcon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(PastelTheme.dark)
                )

            // Title & subtitle
            VStack(alignment: .leading, spacing: 3) {
                Text(appointment.discipline)
                    .font(.poppins(.semiBold, size: 15))
                    .foregroundStyle(.primary)

                HStack(spacing: 4) {
                    Text(appointment.date.formatted(.dateTime.day().month(.abbreviated)))
                    Text("•")
                    Text(appointment.time.formatted(date: .omitted, time: .shortened))
                    if !appointment.notes.isEmpty {
                        Text("•")
                        Text(appointment.notes)
                            .lineLimit(1)
                    }
                }
                .font(.poppins(.regular, size: 14))
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Status
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
        }
        .padding(.vertical, 6)
    }

    private var disciplineIcon: String {
        switch appointment.discipline.lowercased() {
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

    private var statusColor: Color {
        switch appointment.status {
        case "attended": PastelTheme.green
        case "missed", "not attended": PastelTheme.orange
        case "cancelled": PastelTheme.gray
        default: PastelTheme.primary
        }
    }
}
