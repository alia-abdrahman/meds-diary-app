import SwiftUI

struct SupplementRowView: View {
    let supplement: Supplement

    var body: some View {
        HStack(spacing: 8) {
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

            if supplement.isTakenToday {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(PastelTheme.green)
            }
        }
        .padding(.vertical, 4)
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
