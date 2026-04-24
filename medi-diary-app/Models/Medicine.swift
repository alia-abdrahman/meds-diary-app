import Foundation
import SwiftData

@Model
final class Medicine {
    var id: UUID = UUID()
    var name: String = ""
    var dosage: String = ""
    var frequency: String = "Daily"
    var reminderTimesData: Data = Data()
    var notes: String = ""
    var isActive: Bool = true
    var stock: Int = 0
    @Attribute(.externalStorage) var imageData: Data?
    var takenDatesData: Data = Data()
    var createdAt: Date = Date()

    @Transient var reminderTimes: [Date] {
        get { (try? JSONDecoder().decode([Date].self, from: reminderTimesData)) ?? [] }
        set { reminderTimesData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    @Transient var takenDates: [Date] {
        get { (try? JSONDecoder().decode([Date].self, from: takenDatesData)) ?? [] }
        set { takenDatesData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    init(name: String, dosage: String, frequency: String = "Daily", reminderTimes: [Date] = [], notes: String = "", isActive: Bool = true, stock: Int = 0) {
        self.id = UUID()
        self.name = name
        self.dosage = dosage
        self.frequency = frequency
        self.reminderTimesData = (try? JSONEncoder().encode(reminderTimes)) ?? Data()
        self.notes = notes
        self.isActive = isActive
        self.stock = stock
        self.createdAt = Date()
    }

    var displayDosage: String {
        guard !dosage.isEmpty else { return "" }
        let lower = dosage.lowercased()
        if lower.contains("mg") || lower.contains("ml") || lower.contains("g") || lower.contains("%") || lower.contains("iu") {
            return dosage
        }
        return "\(dosage) mg"
    }

    var isTakenToday: Bool {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        return takenDates.contains { Calendar.current.startOfDay(for: $0) == startOfToday }
    }

    func toggleTakenToday() {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        if let index = takenDates.firstIndex(where: { Calendar.current.startOfDay(for: $0) == startOfToday }) {
            takenDates.remove(at: index)
            if stock >= 0 { stock += 1 }
        } else {
            takenDates.append(startOfToday)
            if stock > 0 { stock -= 1 }
        }
    }
}
