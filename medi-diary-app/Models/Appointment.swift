import Foundation
import SwiftData

@Model
final class Appointment {
    var id: UUID = UUID()
    var date: Date = Date()
    var time: Date = Date()
    var discipline: String = ""
    var notes: String = ""
    var hospitalName: String = "Hospital Shah Alam"
    var doctorName: String = ""
    var status: String = "upcoming"
    var createdAt: Date = Date()

    init(date: Date, time: Date, discipline: String, notes: String = "", hospitalName: String = "Hospital Shah Alam", doctorName: String = "", status: String = "upcoming") {
        self.id = UUID()
        self.date = date
        self.time = time
        self.discipline = discipline
        self.notes = notes
        self.hospitalName = hospitalName
        self.doctorName = doctorName
        self.status = status
        self.createdAt = Date()
    }
}
