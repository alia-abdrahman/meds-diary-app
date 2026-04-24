import Foundation
import UserNotifications

@Observable
final class NotificationManager {
    var isAuthorized = false

    private func reminderMessage(for name: String) -> String {
        let messages = [
            "Time to take \(name)",
            "Friendly reminder for \(name)",
            "Hey! It's \(name) time",
            "You're doing great — time for \(name)",
            "A gentle nudge for \(name)",
            "Ready when you are — \(name) time",
            "Take care of yourself — time for \(name)",
            "A little self-care moment — \(name) is up",
            "You've got this — \(name) time",
            "Looking after you — it's \(name) time",
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

    func scheduleAllReminders(medicines: [Medicine], supplements: [Supplement]) async {
        let center = UNUserNotificationCenter.current()

        // Remove all existing reminder notifications
        let pending = await center.pendingNotificationRequests()
        let existingIDs = pending.map(\.identifier).filter {
            $0.hasPrefix("reminder-") || $0.hasPrefix("medicine-") || $0.hasPrefix("supplement-")
        }
        center.removePendingNotificationRequests(withIdentifiers: existingIDs)

        // Group all active & untaken items by reminder time (hour:minute)
        // Items already taken today don't need reminders
        var timeSlots: [String: [String]] = [:]
        let calendar = Calendar.current

        for medicine in medicines where medicine.isActive && !medicine.isTakenToday {
            for time in medicine.reminderTimes {
                let comps = calendar.dateComponents([.hour, .minute], from: time)
                let key = String(format: "%02d-%02d", comps.hour ?? 0, comps.minute ?? 0)
                timeSlots[key, default: []].append(medicine.name)
            }
        }

        for supplement in supplements where supplement.isActive && !supplement.isTakenToday {
            for time in supplement.reminderTimes {
                let comps = calendar.dateComponents([.hour, .minute], from: time)
                let key = String(format: "%02d-%02d", comps.hour ?? 0, comps.minute ?? 0)
                timeSlots[key, default: []].append(supplement.name)
            }
        }

        // Schedule one notification per time slot
        for (key, names) in timeSlots {
            let parts = key.split(separator: "-")
            guard parts.count == 2,
                  let hour = Int(parts[0]),
                  let minute = Int(parts[1]) else { continue }

            let content = UNMutableNotificationContent()
            content.title = "Medication Reminder"
            if names.count == 1 {
                content.body = reminderMessage(for: names[0])
            } else {
                content.body = "Time to take: \(names.joined(separator: ", "))"
            }
            content.sound = .default

            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

            let identifier = "reminder-\(key)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            do {
                try await center.add(request)
            } catch {
                print("Failed to schedule notification: \(error)")
            }
        }
    }

    func scheduleAppointmentReminders(for appointment: Appointment) async {
        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current

        // Remove existing reminders for this appointment
        cancelAppointmentReminders(for: appointment)

        guard appointment.status == "upcoming" else { return }

        // Combine date and time into a single Date
        let timeComps = calendar.dateComponents([.hour, .minute], from: appointment.time)
        let appointmentDateTime = calendar.date(bySettingHour: timeComps.hour ?? 0,
                                                 minute: timeComps.minute ?? 0,
                                                 second: 0,
                                                 of: appointment.date) ?? appointment.date

        // Only schedule if the appointment is in the future
        guard appointmentDateTime > Date() else { return }

        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short

        let timeString = timeFormatter.string(from: appointment.time)

        // 1. Day before at 9:00 AM
        if let dayBefore = calendar.date(byAdding: .day, value: -1, to: appointment.date) {
            var dayBeforeComps = calendar.dateComponents([.year, .month, .day], from: dayBefore)
            dayBeforeComps.hour = 9
            dayBeforeComps.minute = 0

            if let triggerDate = calendar.date(from: dayBeforeComps), triggerDate > Date() {
                let content = UNMutableNotificationContent()
                content.title = "Appointment Tomorrow"
                content.body = "Your \(appointment.discipline) checkup is tomorrow at \(timeString) — you've got this!"
                content.sound = .default

                let trigger = UNCalendarNotificationTrigger(dateMatching: dayBeforeComps, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "appointment-day-\(appointment.id.uuidString)",
                    content: content,
                    trigger: trigger
                )

                do {
                    try await center.add(request)
                } catch {
                    print("Failed to schedule appointment day reminder: \(error)")
                }
            }
        }

        // 2. Night before at 9:00 PM
        if let dayBefore = calendar.date(byAdding: .day, value: -1, to: appointment.date) {
            var nightBeforeComps = calendar.dateComponents([.year, .month, .day], from: dayBefore)
            nightBeforeComps.hour = 21
            nightBeforeComps.minute = 0

            if let triggerDate = calendar.date(from: nightBeforeComps), triggerDate > Date() {
                let content = UNMutableNotificationContent()
                content.title = "Appointment Tomorrow"
                content.body = "A gentle reminder — your \(appointment.discipline) appointment is tomorrow at \(timeString). Rest well tonight!"
                content.sound = .default

                let trigger = UNCalendarNotificationTrigger(dateMatching: nightBeforeComps, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "appointment-night-\(appointment.id.uuidString)",
                    content: content,
                    trigger: trigger
                )

                do {
                    try await center.add(request)
                } catch {
                    print("Failed to schedule appointment night reminder: \(error)")
                }
            }
        }

        // 3. Two hours before the appointment
        if let twoHoursBefore = calendar.date(byAdding: .hour, value: -2, to: appointmentDateTime) {
            if twoHoursBefore > Date() {
                let content = UNMutableNotificationContent()
                content.title = "Almost Time"
                content.body = "Your \(appointment.discipline) appointment is at \(timeString) — you're all set!"
                content.sound = .default

                let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: twoHoursBefore)
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "appointment-2h-\(appointment.id.uuidString)",
                    content: content,
                    trigger: trigger
                )

                do {
                    try await center.add(request)
                } catch {
                    print("Failed to schedule appointment 2h reminder: \(error)")
                }
            }
        }
    }

    func cancelAppointmentReminders(for appointment: Appointment) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [
            "appointment-day-\(appointment.id.uuidString)",
            "appointment-night-\(appointment.id.uuidString)",
            "appointment-2h-\(appointment.id.uuidString)"
        ])
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
