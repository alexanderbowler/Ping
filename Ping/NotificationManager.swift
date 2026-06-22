import Foundation
import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    func scheduleNotification(for contact: PingContact) {
        let center = UNUserNotificationCenter.current()

        cancelNotifications(for: contact)

        let content = UNMutableNotificationContent()
        content.title = "Reach out to \(contact.name)"
        content.body = "It's time to reach out to \(contact.name), it's been \(timeSince(contact.lastContacted)) since you've last reached out to them."
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: contact.nextPingDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(
            identifier: "ping-\(contact.id.uuidString)",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    func scheduleDailyNag(for contact: PingContact) {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = "Reach out to \(contact.name)"
        content.body = "It's time to reach out to \(contact.name), it's been \(timeSince(contact.lastContacted)) since you've last reached out to them."
        content.sound = .default

        let nagTimes: [(hour: Int, id: String)] = [
            (9, "nag-am-\(contact.id.uuidString)"),
            (15, "nag-pm-\(contact.id.uuidString)"),
            (21, "nag-eve-\(contact.id.uuidString)")
        ]

        for nag in nagTimes {
            var dateComponents = DateComponents()
            dateComponents.hour = nag.hour
            dateComponents.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: nag.id, content: content, trigger: trigger)
            center.add(request)
        }
    }

    func scheduleImmediateNotifications(for contacts: [PingContact]) {
        let center = UNUserNotificationCenter.current()
        let overdueContacts = contacts.filter { $0.isOverdue }

        for contact in overdueContacts {
            let content = UNMutableNotificationContent()
            content.title = "Reach out to \(contact.name)"
            content.body = "It's time to reach out to \(contact.name), it's been \(timeSince(contact.lastContacted)) since you've last reached out to them."
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
            let request = UNNotificationRequest(
                identifier: "immediate-\(contact.id.uuidString)",
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    func cancelNotifications(for contact: PingContact) {
        let identifiers = [
            "ping-\(contact.id.uuidString)",
            "nag-am-\(contact.id.uuidString)",
            "nag-pm-\(contact.id.uuidString)",
            "nag-eve-\(contact.id.uuidString)",
            "immediate-\(contact.id.uuidString)"
        ]
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    func rescheduleAll(contacts: [PingContact]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        for contact in contacts {
            if contact.isOverdue {
                scheduleDailyNag(for: contact)
            } else {
                scheduleNotification(for: contact)
            }
        }
    }

    private func timeSince(_ date: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .weekOfYear, .day], from: date, to: Date())

        if let years = components.year, years > 0 {
            return years == 1 ? "1 year" : "\(years) years"
        } else if let months = components.month, months > 0 {
            return months == 1 ? "1 month" : "\(months) months"
        } else if let weeks = components.weekOfYear, weeks > 0 {
            return weeks == 1 ? "1 week" : "\(weeks) weeks"
        } else if let days = components.day, days > 0 {
            return days == 1 ? "1 day" : "\(days) days"
        } else {
            return "less than a day"
        }
    }
}
