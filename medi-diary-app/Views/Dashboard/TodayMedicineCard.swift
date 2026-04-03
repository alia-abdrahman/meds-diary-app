import SwiftUI
import SwiftData

struct TodayMedicineCard: View {
    let medicine: Medicine
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack(spacing: 8) {
            Button {
                medicine.toggleTakenToday()
            } label: {
                Image(systemName: medicine.isTakenToday ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(medicine.isTakenToday ? PastelTheme.green : PastelTheme.pinkAccent)
            }
            .buttonStyle(.plain)

            Text(medicine.name)
                .font(.poppins(.semiBold, size: 17))

            Spacer()

            if !medicine.dosage.isEmpty {
                pill(medicine.displayDosage)
            }
            pill(medicine.frequency)

            if !medicine.reminderTimes.isEmpty {
                Label("\(medicine.reminderTimes.count)", systemImage: "bell.fill")
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
