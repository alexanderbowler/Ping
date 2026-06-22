import SwiftUI
import SwiftData

struct AddContactView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var phoneNumber = ""
    @State private var email = ""
    @State private var company = ""
    @State private var notes = ""
    @State private var intervalValue = 1
    @State private var intervalUnit = "months"
    @State private var showingContactPicker = false

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Contact") {
                    Button {
                        showingContactPicker = true
                    } label: {
                        Label("Import from Contacts", systemImage: "person.crop.circle.badge.plus")
                    }

                    TextField("Name", text: $name)
                    TextField("Phone Number (optional)", text: $phoneNumber)
                        .keyboardType(.phonePad)
                    TextField("Email (optional)", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    TextField("Company (optional)", text: $company)
                }

                Section("Notes") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Reminder Interval") {
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
            }
            .navigationTitle("Add Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveContact() }
                        .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showingContactPicker) {
                ContactPickerRepresentable(selectedName: $name, selectedPhone: $phoneNumber, selectedEmail: $email, selectedCompany: $company)
            }
            .onChange(of: intervalUnit) {
                let maxValue = intervalUnit == "days" ? 7 : (intervalUnit == "weeks" ? 4 : 12)
                if intervalValue > maxValue {
                    intervalValue = maxValue
                }
            }
        }
    }

    private func saveContact() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedPhone = phoneNumber.trimmingCharacters(in: .whitespaces)
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespaces)
        let trimmedCompany = company.trimmingCharacters(in: .whitespaces)

        let contact = PingContact(
            name: trimmedName,
            phoneNumber: trimmedPhone.isEmpty ? nil : trimmedPhone,
            email: trimmedEmail.isEmpty ? nil : trimmedEmail,
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
            company: trimmedCompany.isEmpty ? nil : trimmedCompany,
            intervalValue: intervalValue,
            intervalUnit: intervalUnit
        )

        modelContext.insert(contact)
        PingContact.rebalanceGroup(intervalValue: intervalValue, intervalUnit: intervalUnit, in: modelContext)
        dismiss()
    }
}

#Preview {
    AddContactView()
        .modelContainer(for: PingContact.self, inMemory: true)
}
