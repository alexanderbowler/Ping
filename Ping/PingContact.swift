import Foundation
import SwiftData

@Model
final class PingContact {
    var id: UUID
    var name: String
    var phoneNumber: String?
    var email: String?
    var notes: String?
    var company: String?
    var intervalValue: Int
    var intervalUnit: String // "days", "weeks", or "months"
    var lastContacted: Date
    var nextPingDate: Date
    var contactIdentifier: String?

    var isOverdue: Bool {
        nextPingDate < Date()
    }

    var intervalLabel: String {
        if intervalUnit == "days" {
            return intervalValue == 1 ? "Every day" : "Every \(intervalValue) days"
        } else if intervalUnit == "weeks" {
            return intervalValue == 1 ? "Every week" : "Every \(intervalValue) weeks"
        } else {
            return intervalValue == 1 ? "Every month" : "Every \(intervalValue) months"
        }
    }

    init(name: String, phoneNumber: String? = nil, email: String? = nil, notes: String? = nil, company: String? = nil, intervalValue: Int, intervalUnit: String, contactIdentifier: String? = nil) {
        self.id = UUID()
        self.name = name
        self.phoneNumber = phoneNumber
        self.email = email
        self.notes = notes
        self.company = company
        self.intervalValue = intervalValue
        self.intervalUnit = intervalUnit
        self.contactIdentifier = contactIdentifier
        self.lastContacted = Date()
        self.nextPingDate = PingContact.computeNextPingDate(from: Date(), intervalValue: intervalValue, intervalUnit: intervalUnit)
    }

    func markAsContacted() {
        lastContacted = Date()
        nextPingDate = PingContact.computeNextPingDate(from: Date(), intervalValue: intervalValue, intervalUnit: intervalUnit)
    }

    func updateInterval(value: Int, unit: String) {
        intervalValue = value
        intervalUnit = unit
        nextPingDate = PingContact.computeNextPingDate(from: lastContacted, intervalValue: value, intervalUnit: unit)
    }

    static func computeNextPingDate(from date: Date, intervalValue: Int, intervalUnit: String) -> Date {
        let calendar = Calendar.current
        if intervalUnit == "days" {
            return calendar.date(byAdding: .day, value: intervalValue, to: date) ?? date
        } else if intervalUnit == "weeks" {
            return calendar.date(byAdding: .weekOfYear, value: intervalValue, to: date) ?? date
        } else {
            return calendar.date(byAdding: .month, value: intervalValue, to: date) ?? date
        }
    }

    @MainActor static func rebalanceGroup(intervalValue: Int, intervalUnit: String, in context: ModelContext) {
        let descriptor = FetchDescriptor<PingContact>()
        guard let allContacts = try? context.fetch(descriptor) else { return }

        let group = allContacts.filter {
            $0.intervalValue == intervalValue && $0.intervalUnit == intervalUnit
        }

        guard group.count > 1 else { return }

        let now = Date()
        let endDate = computeNextPingDate(from: now, intervalValue: intervalValue, intervalUnit: intervalUnit)
        let totalSeconds = endDate.timeIntervalSince(now)
        let spacing = totalSeconds / Double(group.count)

        let sorted = group.sorted { $0.id.uuidString < $1.id.uuidString }

        for (index, contact) in sorted.enumerated() {
            contact.nextPingDate = now.addingTimeInterval(spacing * Double(index + 1))
            NotificationManager.shared.cancelNotifications(for: contact)
            NotificationManager.shared.scheduleNotification(for: contact)
        }
    }
}
