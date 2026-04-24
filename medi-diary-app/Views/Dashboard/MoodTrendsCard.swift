import SwiftUI
import SwiftData

struct MoodTrendsCard: View {
    let moodEntries: [MoodEntry]
    let weeklyAdherencePercentage: Double

    private var last7Days: [(date: Date, mood: MoodEntry?)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<7).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today)!
            let entry = moodEntries.first { calendar.startOfDay(for: $0.date) == day }
            return (day, entry)
        }
    }

    private var averageMood: Double? {
        let recentMoods = last7Days.compactMap { $0.mood?.mood }
        guard !recentMoods.isEmpty else { return nil }
        return Double(recentMoods.reduce(0, +)) / Double(recentMoods.count)
    }

    private var averageEmoji: String {
        guard let avg = averageMood else { return "—" }
        let index = max(0, min(Int(avg.rounded()) - 1, MoodEntry.emojis.count - 1))
        return MoodEntry.emojis[index]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mood This Week")
                .font(.poppins(.semiBold, size: 15))
                .foregroundStyle(PastelTheme.dark)

            // Emoji row for last 7 days
            HStack(spacing: 0) {
                ForEach(last7Days, id: \.date) { day in
                    VStack(spacing: 4) {
                        Text(day.mood?.emoji ?? "—")
                            .font(.system(size: 22))

                        Text(dayLabel(day.date))
                            .font(.poppins(.regular, size: 10))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            Divider()

            // Summary row
            HStack {
                HStack(spacing: 4) {
                    Text("Avg:")
                        .font(.poppins(.medium, size: 13))
                        .foregroundStyle(.secondary)
                    Text(averageEmoji)
                        .font(.system(size: 16))
                }

                Spacer()

                HStack(spacing: 4) {
                    Text("Adherence:")
                        .font(.poppins(.medium, size: 13))
                        .foregroundStyle(.secondary)
                    Text("\(Int(weeklyAdherencePercentage))%")
                        .font(.poppins(.semiBold, size: 13))
                        .foregroundStyle(weeklyAdherencePercentage >= 80 ? .green : weeklyAdherencePercentage >= 50 ? .orange : .red)
                }
            }
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
    }

    private func dayLabel(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return String(formatter.string(from: date).prefix(3))
    }
}

#Preview {
    VStack {
        MoodTrendsCard(
            moodEntries: [],
            weeklyAdherencePercentage: 85
        )
    }
    .padding()
    .background(PastelTheme.gradient)
}
