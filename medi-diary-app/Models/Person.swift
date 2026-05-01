import Foundation
import SwiftData

@Model
final class Person {
    var id: UUID = UUID()
    var name: String = ""
    var relation: String = ""
    var dateOfBirth: Date?
    var colorHex: String = "#6B9BF2"
    var avatarEmoji: String = "🙂"
    var isSelf: Bool = false
    var createdAt: Date = Date()
    var sortOrder: Int = 0

    init(name: String,
         relation: String = "",
         isSelf: Bool = false,
         colorHex: String = "#6B9BF2",
         avatarEmoji: String = "🙂",
         sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.relation = relation
        self.isSelf = isSelf
        self.colorHex = colorHex
        self.avatarEmoji = avatarEmoji
        self.createdAt = Date()
        self.sortOrder = sortOrder
    }

    var displayName: String {
        name.isEmpty ? (isSelf ? "Me" : "Untitled") : name
    }
}
