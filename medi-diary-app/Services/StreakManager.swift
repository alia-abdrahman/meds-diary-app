import Foundation

enum StreakManager {

    /// Calculate consecutive days where ALL active medicines + supplements were taken
    static func overallStreak(medicines: [Medicine], supplements: [Supplement]) -> Int {
        let activeItems: [[Date]] = medicines.filter(\.isActive).map(\.takenDates)
            + supplements.filter(\.isActive).map(\.takenDates)

        guard !activeItems.isEmpty else { return 0 }

        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        while true {
            let allTaken = activeItems.allSatisfy { dates in
                dates.contains { calendar.startOfDay(for: $0) == checkDate }
            }

            if allTaken {
                streak += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = previousDay
            } else if streak == 0, checkDate == calendar.startOfDay(for: Date()) {
                // Today not yet completed — check from yesterday
                guard let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = yesterday
            } else {
                break
            }
        }

        return streak
    }

    /// Weekly adherence: how many item-days were taken out of total possible in last 7 days
    static func weeklyAdherence(medicines: [Medicine], supplements: [Supplement]) -> (taken: Int, total: Int, percentage: Double) {
        let activeMeds = medicines.filter(\.isActive)
        let activeSupps = supplements.filter(\.isActive)
        let itemCount = activeMeds.count + activeSupps.count

        guard itemCount > 0 else { return (0, 0, 0) }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var taken = 0
        let total = itemCount * 7

        for dayOffset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }

            for med in activeMeds {
                if med.takenDates.contains(where: { calendar.startOfDay(for: $0) == day }) {
                    taken += 1
                }
            }
            for supp in activeSupps {
                if supp.takenDates.contains(where: { calendar.startOfDay(for: $0) == day }) {
                    taken += 1
                }
            }
        }

        let percentage = total > 0 ? (Double(taken) / Double(total)) * 100 : 0
        return (taken, total, percentage)
    }

    /// Per-item streak from a single item's takenDates
    static func itemStreak(takenDates: [Date]) -> Int {
        guard !takenDates.isEmpty else { return 0 }

        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        while true {
            let takenOnDay = takenDates.contains { calendar.startOfDay(for: $0) == checkDate }

            if takenOnDay {
                streak += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = previousDay
            } else if streak == 0, checkDate == calendar.startOfDay(for: Date()) {
                guard let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = yesterday
            } else {
                break
            }
        }

        return streak
    }

    /// Returns the milestone value if the streak matches a milestone
    static func milestoneReached(streak: Int) -> Int? {
        let milestones = [7, 14, 30, 60, 100, 365]
        return milestones.contains(streak) ? streak : nil
    }

    static func encouragementMessage(for streak: Int) -> String {
        switch streak {
        case 0: return "Start your streak today!"
        case 1...6: return "Great start — keep going!"
        case 7...13: return "One week strong!"
        case 14...29: return "Two weeks — amazing!"
        case 30...59: return "One month — incredible dedication!"
        case 60...99: return "Two months — you're unstoppable!"
        case 100...364: return "100+ days — truly inspiring!"
        default: return "A whole year — legendary!"
        }
    }
}
