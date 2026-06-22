import SwiftUI
import SwiftData

struct ContactDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var contact: PingContact

    @State private var isEditingInterval = false
    @State private var editIntervalValue: Int = 1
    @State private var editIntervalUnit: String = "months"
    @State private var showingDeleteConfirmation = false

    var body: some View {
        List {
            Section {
                HStack {
                    Text("Name")
                    Spacer()
                    Text(contact.name)
                        .foregroundStyle(.secondary)
                }

                if let phone = contact.phoneNumber {
                    HStack {
                        Text("Phone")
                        Spacer()
                        Text(phone)
                            .foregroundStyle(.secondary)
                    }
                }

                if let email = contact.email {
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(email)
                            .foregroundStyle(.secondary)
                    }
                }

                if let company = contact.company {
                    HStack {
                        Text("Company")
                        Spacer()
                        Text(company)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                HStack {
                    Text("Reminder")
                    Spacer()
                    Text(contact.intervalLabel)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Last Contacted")
                    Spacer()
                    Text(contact.lastContacted, style: .date)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Next Ping")
                    Spacer()
                    Text(contact.nextPingDate, style: .date)
                        .foregroundStyle(contact.isOverdue ? .red : .secondary)
                }

                if contact.isOverdue {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text("Overdue by \(overdueDays) day\(overdueDays == 1 ? "" : "s")")
                            .foregroundStyle(.red)
                    }
                }
            }

            Section("Notes") {
                TextField("Add notes...", text: Binding(
                    get: { contact.notes ?? "" },
                    set: { contact.notes = $0.isEmpty ? nil : $0 }
                ), axis: .vertical)
                    .lineLimit(3...10)
            }

            Section {
                Button {
                    contact.markAsContacted()
                    NotificationManager.shared.cancelNotifications(for: contact)
                    NotificationManager.shared.scheduleNotification(for: contact)
                } label: {
                    Label("Mark as Contacted", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                        .font(.headline)
                }
                .tint(.green)
            }

            Section {
                Button("Change Reminder Interval") {
                    editIntervalValue = contact.intervalValue
                    editIntervalUnit = contact.intervalUnit
                    isEditingInterval = true
                }

                Button("Delete Contact", role: .destructive) {
                    showingDeleteConfirmation = true
                }
            }
        }
        .navigationTitle(contact.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isEditingInterval) {
            EditIntervalView(
                intervalValue: $editIntervalValue,
                intervalUnit: $editIntervalUnit
            ) {
                contact.updateInterval(value: editIntervalValue, unit: editIntervalUnit)
                NotificationManager.shared.cancelNotifications(for: contact)
                NotificationManager.shared.scheduleNotification(for: contact)
            }
        }
        .confirmationDialog("Delete Contact", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                let intervalValue = contact.intervalValue
                let intervalUnit = contact.intervalUnit
                NotificationManager.shared.cancelNotifications(for: contact)
                modelContext.delete(contact)
                PingContact.rebalanceGroup(intervalValue: intervalValue, intervalUnit: intervalUnit, in: modelContext)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete \(contact.name)? This will also cancel their reminders.")
        }
    }

    private var overdueDays: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: contact.nextPingDate, to: Date())
        return max(1, components.day ?? 1)
    }
}

struct EditIntervalView: View {
    @Binding var intervalValue: Int
    @Binding var intervalUnit: String
    var onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Picker("Unit", selection: $intervalUnit) {
                    Text("Days").tag("days")
                    Text("Weeks").tag("weeks")
                    Text("Months").tag("months")
                }
                .pickerStyle(.segmented)

                Picker("Every", selection: $intervalValue) {
                    if intervalUnit == "days" {
                        ForEach(1...7, id: \.self) { value in
                            Text(value == 1 ? "1 day" : "\(value) days").tag(value)
                        }
                    } else if intervalUnit == "weeks" {
                        ForEach(1...4, id: \.self) { value in
                            Text(value == 1 ? "1 week" : "\(value) weeks").tag(value)
                        }
                    } else {
                        ForEach(1...12, id: \.self) { value in
                            Text(value == 1 ? "1 month" : "\(value) months").tag(value)
                        }
                    }
                }
            }
            .navigationTitle("Change Interval")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                }
            }
            .onChange(of: intervalUnit) {
                let maxValue = intervalUnit == "days" ? 7 : (intervalUnit == "weeks" ? 4 : 12)
                if intervalValue > maxValue {
                    intervalValue = maxValue
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ContactDetailView(contact: PingContact(
            name: "John Appleseed",
            phoneNumber: "+1 (555) 123-4567",
            intervalValue: 2,
            intervalUnit: "months"
        ))
    }
    .modelContainer(for: PingContact.self, inMemory: true)
}
