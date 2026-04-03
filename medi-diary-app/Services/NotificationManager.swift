import Foundation
import UserNotifications

@Observable
final class NotificationManager {
    var isAuthorized = false

    private func reminderMessage(for name: String) -> String {
        let messages = [
            "Time to take \(name)",
            "Don't forget your \(name)!",
            "Hey! It's \(name) time",
            "Reminder: take your \(name)",
            "\(name) is waiting for you",
            "Stay on track — take \(name)",
            "Your health matters — time for \(name)",
            "Quick reminder to take \(name)!",
        ]
        return messages.randomElement()!
    }

    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
        } catch {
            print("Notification authorization error: \(error)")
        }
    }

    func scheduleMedicineReminders(for medicine: Medicine) async {
        let center = UNUserNotificationCenter.current()

        // Remove existing notifications for this medicine
        let identifiers = medicine.reminderTimes.enumerated().map { index, _ in
            "medicine-\(medicine.id.uuidString)-\(index)"
        }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)

        guard medicine.isActive else { return }

        for (index, reminderTime) in medicine.reminderTimes.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "Medicine Reminder"
            content.body = reminderMessage(for: medicine.name)
            content.sound = .default

            let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

            let identifier = "medicine-\(medicine.id.uuidString)-\(index)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            do {
                try await center.add(request)
            } catch {
                print("Failed to schedule notification: \(error)")
            }
        }
    }

    func cancelReminders(for medicine: Medicine) {
        let center = UNUserNotificationCenter.current()
        let identifiers = medicine.reminderTimes.enumerated().map { index, _ in
            "medicine-\(medicine.id.uuidString)-\(index)"
        }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func scheduleSupplementReminders(for supplement: Supplement) async {
        let center = UNUserNotificationCenter.current()

        // Remove existing notifications for this supplement
        let identifiers = supplement.reminderTimes.enumerated().map { index, _ in
            "supplement-\(supplement.id.uuidString)-\(index)"
        }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)

        guard supplement.isActive else { return }

        for (index, reminderTime) in supplement.reminderTimes.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "Supplement Reminder"
            content.body = reminderMessage(for: supplement.name)
            content.sound = .default

            let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

            let identifier = "supplement-\(supplement.id.uuidString)-\(index)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            do {
                try await center.add(request)
            } catch {
                print("Failed to schedule notification: \(error)")
            }
        }
    }

    func cancelReminders(for supplement: Supplement) {
        let center = UNUserNotificationCenter.current()
        let identifiers = supplement.reminderTimes.enumerated().map { index, _ in
            "supplement-\(supplement.id.uuidString)-\(index)"
        }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func updateBadgeCount(_ count: Int) async {
        do {
            try await UNUserNotificationCenter.current().setBadgeCount(count)
        } catch {
            print("Failed to update badge count: \(error)")
        }
    }

    func updateBadgeFromUntaken(medicines: [Medicine], supplements: [Supplement]) async {
        let untakenMedicines = medicines.filter { $0.isActive && !$0.isTakenToday }.count
        let untakenSupplements = supplements.filter { $0.isActive && !$0.isTakenToday }.count
        await updateBadgeCount(untakenMedicines + untakenSupplements)
    }
}
