import SwiftUI

struct UpcomingAppointmentCard: View {
    let appointment: Appointment
    @State private var isBouncing = false

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 4) {
                Text(appointment.date.formatted(.dateTime.day()))
                    .font(.poppins(.bold, size: 22))
                    .foregroundStyle(PastelTheme.dark)
                Text(appointment.date.formatted(.dateTime.month(.abbreviated)))
                    .font(.poppins(.regular, size: 12))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 48)

            Divider()
                .frame(height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(appointment.discipline)
                    .font(.poppins(.semiBold, size: 17))
                Text(appointment.time.formatted(date: .omitted, time: .shortened))
                    .font(.poppins(.regular, size: 15))
                    .foregroundStyle(.secondary)
                if !appointment.hospitalName.isEmpty {
                    Text(appointment.hospitalName)
                        .font(.poppins(.regular, size: 12))
                        .foregroundStyle(PastelTheme.dark)
                }
            }

            Spacer()

            Text(countdownText)
                .font(.poppins(.bold, size: 12))
                .foregroundStyle(countdownColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(countdownColor.opacity(0.15))
                .clipShape(Capsule())
                .scaleEffect(isBouncing && isUpcoming ? 1.15 : 1.0)
                .animation(
                    isUpcoming ? .easeInOut(duration: 1.2).repeatForever(autoreverses: true) : .default,
                    value: isBouncing
                )
                .onAppear { isBouncing = true }
        }
        .cardStyle()
    }

    private var isUpcoming: Bool {
        appointment.date >= Calendar.current.startOfDay(for: Date())
    }

    private var statusColor: Color {
        switch appointment.status {
        case "attended": PastelTheme.green
        case "missed": PastelTheme.orange
        case "cancelled": PastelTheme.gray
        default: PastelTheme.primary
        }
    }

    private var countdownText: String {
        let calendar = Calendar.current
        let now = Date()

        // Combine appointment date + time
        let timeComponents = calendar.dateComponents([.hour, .minute], from: appointment.time)
        guard let appointmentDateTime = calendar.date(
            bySettingHour: timeComponents.hour ?? 0,
            minute: timeComponents.minute ?? 0,
            second: 0,
            of: appointment.date
        ) else { return "" }

        if calendar.isDateInToday(appointment.date) {
            return "Today"
        }
        if calendar.isDateInTomorrow(appointment.date) {
            return "Tomorrow"
        }

        let components = calendar.dateComponents([.day, .hour], from: now, to: appointmentDateTime)
        let days = components.day ?? 0
        let hours = components.hour ?? 0

        if days <= 0 && hours <= 0 {
            return "Past"
        }
        if days == 0 {
            return "\(hours)h remaining"
        }
        return "\(days)d \(hours)h remaining"
    }

    private var countdownColor: Color {
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: appointment.date)).day ?? 0
        if days <= 1 { return .red }
        if days <= 7 { return PastelTheme.orange }
        return PastelTheme.dark
    }
}
