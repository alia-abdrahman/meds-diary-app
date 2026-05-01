import Foundation
import SwiftData

@Model
final class MoodEntry {
    var id: UUID = UUID()
    var date: Date = Date()
    var mood: Int = 3
    var createdAt: Date = Date()
    var personId: UUID?

    init(date: Date, mood: Int) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.mood = mood
        self.createdAt = Date()
    }

    static let emojis = ["😢", "😕", "😐", "🙂", "😄"]

    var emoji: String {
        let index = max(0, min(mood - 1, Self.emojis.count - 1))
        return Self.emojis[index]
    }
}
