import SwiftUI
import SwiftData

struct TodaySupplementCard: View {
    let supplement: Supplement
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack(spacing: 8) {
            Button {
                supplement.toggleTakenToday()
            } label: {
                Image(systemName: supplement.isTakenToday ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(supplement.isTakenToday ? PastelTheme.green : PastelTheme.pinkAccent)
            }
            .buttonStyle(.plain)

            Text(supplement.name)
                .font(.poppins(.semiBold, size: 17))

            Spacer()

            if !supplement.dosage.isEmpty {
                pill(supplement.displayDosage)
            }
            pill(supplement.frequency)

            if !supplement.reminderTimes.isEmpty {
                Label("\(supplement.reminderTimes.count)", systemImage: "bell.fill")
                    .font(.poppins(.regular, size: 12))
                    .foregroundStyle(PastelTheme.dark)
            }
        }
        .cardStyle()
    }

    private func pill(_ text: String) -> some View {
        Text(text)
            .font(.poppins(.regular, size: 12))
            .foregroundStyle(PastelTheme.dark)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(PastelTheme.light)
            .clipShape(Capsule())
    }
}
