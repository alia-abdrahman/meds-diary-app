import SwiftUI
import SwiftData

struct MoodHistoryView: View {
    let personId: UUID?

    @Environment(\.dismiss) private var dismiss
    @Query(sort: \MoodEntry.date, order: .reverse) private var allMoodEntriesRaw: [MoodEntry]
    @Query(sort: \Medicine.name) private var allMedicinesRaw: [Medicine]
    @Query(sort: \Supplement.name) private var allSupplementsRaw: [Supplement]

    private var allMoodEntries: [MoodEntry] {
        guard let id = personId else { return allMoodEntriesRaw }
        return allMoodEntriesRaw.filter { $0.personId == id }
    }

    private var allMedicines: [Medicine] {
        guard let id = personId else { return allMedicinesRaw }
        return allMedicinesRaw.filter { $0.personId == id }
    }

    private var allSupplements: [Supplement] {
        guard let id = personId else { return allSupplementsRaw }
        return allSupplementsRaw.filter { $0.personId == id }
    }

    private var last7Days: [(date: Date, mood: MoodEntry?)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today)!
            let entry = allMoodEntries.first { calendar.startOfDay(for: $0.date) == day }
            return (day, entry)
        }
    }

    private var last30DaysEntries: [MoodEntry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        return allMoodEntries.filter { $0.date >= Calendar.current.startOfDay(for: cutoff) }
    }

    private var weeklyAverage: Double? {
        let moods = last7Days.compactMap { $0.mood?.mood }
        guard !moods.isEmpty else { return nil }
        return Double(moods.reduce(0, +)) / Double(moods.count)
    }

    private var monthlyAverage: Double? {
        let moods = last30DaysEntries.map(\.mood)
        guard !moods.isEmpty else { return nil }
        return Double(moods.reduce(0, +)) / Double(moods.count)
    }

    private var happiestDay: (day: String, avg: Double)? {
        dayOfWeekAverages.max(by: { $0.value < $1.value }).map { ($0.key, $0.value) }
    }

    private var lowestDay: (day: String, avg: Double)? {
        dayOfWeekAverages.min(by: { $0.value < $1.value }).map { ($0.key, $0.value) }
    }

    private var dayOfWeekAverages: [String: Double] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"

        var grouped: [String: [Int]] = [:]
        for entry in last30DaysEntries {
            let dayName = formatter.string(from: entry.date)
            grouped[dayName, default: []].append(entry.mood)
        }

        var averages: [String: Double] = [:]
        for (day, moods) in grouped {
            averages[day] = Double(moods.reduce(0, +)) / Double(moods.count)
        }
        return averages
    }

    private var highAdherenceMoodAvg: Double? {
        moodByAdherence(highAdherence: true)
    }

    private var lowAdherenceMoodAvg: Double? {
        moodByAdherence(highAdherence: false)
    }

    private func moodByAdherence(highAdherence: Bool) -> Double? {
        let calendar = Calendar.current
        let activeMeds = allMedicines.filter(\.isActive)
        let activeSupps = allSupplements.filter(\.isActive)
        let itemCount = activeMeds.count + activeSupps.count
        guard itemCount > 0 else { return nil }

        var matchingMoods: [Int] = []

        for entry in last30DaysEntries {
            let day = calendar.startOfDay(for: entry.date)
            var takenCount = 0
            for med in activeMeds {
                if med.takenDates.contains(where: { calendar.startOfDay(for: $0) == day }) {
                    takenCount += 1
                }
            }
            for supp in activeSupps {
                if supp.takenDates.contains(where: { calendar.startOfDay(for: $0) == day }) {
                    takenCount += 1
                }
            }

            let adherenceRate = Double(takenCount) / Double(itemCount)
            if highAdherence && adherenceRate >= 0.8 {
                matchingMoods.append(entry.mood)
            } else if !highAdherence && adherenceRate < 0.8 {
                matchingMoods.append(entry.mood)
            }
        }

        guard !matchingMoods.isEmpty else { return nil }
        return Double(matchingMoods.reduce(0, +)) / Double(matchingMoods.count)
    }

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

                    Text("Mood Tracker")
                        .font(.poppins(.bold, size: 20))
                        .foregroundStyle(.primary)

                    Spacer()

                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.top, 8)

                if last30DaysEntries.isEmpty {
                    emptyState
                } else {
                    thisWeekCard
                    monthlyTrendCard
                    patternsCard
                    moodVsAdherenceCard
                }
            }
            .padding()
            .padding(.bottom, 10)
        }
        .scrollContentBackground(.hidden)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .background(PastelTheme.gradient.ignoresSafeArea())
    }

    // MARK: - This Week

    private var thisWeekCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.poppins(.semiBold, size: 15))
                .foregroundStyle(PastelTheme.dark)

            HStack(spacing: 0) {
                ForEach(last7Days, id: \.date) { day in
                    VStack(spacing: 4) {
                        Text(day.mood?.emoji ?? "—")
                            .font(.system(size: 22))
                        Text(shortDayLabel(day.date))
                            .font(.poppins(.regular, size: 10))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            if let avg = weeklyAverage {
                Divider()
                HStack(spacing: 4) {
                    Text("Avg:")
                        .font(.poppins(.medium, size: 13))
                        .foregroundStyle(.secondary)
                    Text(emojiForAverage(avg))
                        .font(.system(size: 16))
                    Text(String(format: "(%.1f/5)", avg))
                        .font(.poppins(.regular, size: 12))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
    }

    // MARK: - 30-Day Trend

    private var monthlyTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("30-Day Trend")
                .font(.poppins(.semiBold, size: 15))
                .foregroundStyle(PastelTheme.dark)

            MoodLineGraph(entries: last30DaysEntries)
                .frame(height: 100)

            if let avg = monthlyAverage {
                HStack(spacing: 4) {
                    Text("Avg this month:")
                        .font(.poppins(.medium, size: 13))
                        .foregroundStyle(.secondary)
                    Text(emojiForAverage(avg))
                        .font(.system(size: 16))
                    Text(String(format: "(%.1f/5)", avg))
                        .font(.poppins(.regular, size: 12))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
    }

    // MARK: - Patterns

    private var patternsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Patterns")
                .font(.poppins(.semiBold, size: 15))
                .foregroundStyle(PastelTheme.dark)

            if let happiest = happiestDay {
                HStack(spacing: 8) {
                    Text("Happiest day:")
                        .font(.poppins(.medium, size: 13))
                        .foregroundStyle(.secondary)
                    Text("\(happiest.day) \(emojiForAverage(happiest.avg))")
                        .font(.poppins(.regular, size: 14))
                        .foregroundStyle(PastelTheme.dark)
                }
            }

            if let lowest = lowestDay, lowest.day != happiestDay?.day {
                HStack(spacing: 8) {
                    Text("Lowest day:")
                        .font(.poppins(.medium, size: 13))
                        .foregroundStyle(.secondary)
                    Text("\(lowest.day) \(emojiForAverage(lowest.avg))")
                        .font(.poppins(.regular, size: 14))
                        .foregroundStyle(PastelTheme.dark)
                }
            }
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
    }

    // MARK: - Mood vs Adherence

    private var moodVsAdherenceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mood vs Adherence")
                .font(.poppins(.semiBold, size: 15))
                .foregroundStyle(PastelTheme.dark)

            if let highAvg = highAdherenceMoodAvg {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("High adherence")
                        .font(.poppins(.medium, size: 13))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Avg mood \(emojiForAverage(highAvg))")
                        .font(.poppins(.regular, size: 13))
                        .foregroundStyle(PastelTheme.dark)
                    Text(String(format: "%.1f", highAvg))
                        .font(.poppins(.semiBold, size: 13))
                        .foregroundStyle(.green)
                }
            }

            if let lowAvg = lowAdherenceMoodAvg {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.orange)
                    Text("Low adherence")
                        .font(.poppins(.medium, size: 13))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Avg mood \(emojiForAverage(lowAvg))")
                        .font(.poppins(.regular, size: 13))
                        .foregroundStyle(PastelTheme.dark)
                    Text(String(format: "%.1f", lowAvg))
                        .font(.poppins(.semiBold, size: 13))
                        .foregroundStyle(.orange)
                }
            }

            if highAdherenceMoodAvg == nil && lowAdherenceMoodAvg == nil {
                Text("Not enough data yet to show correlation.")
                    .font(.poppins(.regular, size: 13))
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "face.smiling")
                .font(.system(size: 40))
                .foregroundStyle(PastelTheme.primary)
            Text("No mood entries yet")
                .font(.poppins(.semiBold, size: 16))
                .foregroundStyle(PastelTheme.dark)
            Text("Your mood will be tracked after\nyou mark all items as taken.")
                .font(.poppins(.regular, size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Helpers

    private func shortDayLabel(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return String(formatter.string(from: date).prefix(3))
    }

    private func emojiForAverage(_ avg: Double) -> String {
        let index = max(0, min(Int(avg.rounded()) - 1, MoodEntry.emojis.count - 1))
        return MoodEntry.emojis[index]
    }
}

// MARK: - Mood Line Graph

private struct MoodLineGraph: View {
    let entries: [MoodEntry]

    private var sortedEntries: [MoodEntry] {
        entries.sorted { $0.date < $1.date }
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let count = sortedEntries.count

            if count > 1 {
                // Draw line
                Path { path in
                    for (index, entry) in sortedEntries.enumerated() {
                        let x = width * CGFloat(index) / CGFloat(count - 1)
                        let y = height - (height * CGFloat(entry.mood - 1) / 4.0)

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(PastelTheme.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                // Draw dots
                ForEach(Array(sortedEntries.enumerated()), id: \.element.id) { index, entry in
                    let x = width * CGFloat(index) / CGFloat(count - 1)
                    let y = height - (height * CGFloat(entry.mood - 1) / 4.0)

                    Circle()
                        .fill(moodColor(entry.mood))
                        .frame(width: 8, height: 8)
                        .position(x: x, y: y)
                }

                // Y-axis labels
                VStack {
                    Text("😄").font(.system(size: 10))
                    Spacer()
                    Text("😢").font(.system(size: 10))
                }
                .frame(height: height)
                .offset(x: -12)
            } else if count == 1 {
                let entry = sortedEntries[0]
                Circle()
                    .fill(moodColor(entry.mood))
                    .frame(width: 10, height: 10)
                    .position(x: width / 2, y: height - (height * CGFloat(entry.mood - 1) / 4.0))
            }
        }
        .padding(.leading, 16)
    }

    private func moodColor(_ mood: Int) -> Color {
        switch mood {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .mint
        case 5: return .green
        default: return .gray
        }
    }
}

#Preview {
    NavigationStack {
        MoodHistoryView(personId: nil)
    }
    .modelContainer(for: [MoodEntry.self, Medicine.self, Supplement.self], inMemory: true)
}
