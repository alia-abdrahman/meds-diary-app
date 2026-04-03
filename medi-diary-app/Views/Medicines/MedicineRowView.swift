import SwiftUI

struct MedicineRowView: View {
    let medicine: Medicine

    var body: some View {
        HStack(spacing: 8) {
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

            if medicine.isTakenToday {
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
