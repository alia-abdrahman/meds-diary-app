import SwiftUI

struct ReminderTimePicker: View {
    @Binding var reminderTimes: [Date]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(reminderTimes.indices, id: \.self) { index in
                HStack {
                    DatePicker(
                        "Reminder \(index + 1)",
                        selection: $reminderTimes[index],
                        displayedComponents: .hourAndMinute
                    )

                    Button(role: .destructive) {
                        reminderTimes.remove(at: index)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.red.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
            }

            Button {
                reminderTimes.append(Date())
            } label: {
                Label("Add Reminder Time", systemImage: "plus.circle.fill")
                    .font(.poppins(.regular, size: 15))
                    .foregroundStyle(PastelTheme.dark)
            }
        }
    }
}
