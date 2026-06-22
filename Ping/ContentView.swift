import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PingContact.nextPingDate) private var contacts: [PingContact]
    @State private var showingAddContact = false
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            Group {
                if contacts.isEmpty {
                    ContentUnavailableView(
                        "No Contacts Yet",
                        systemImage: "person.crop.circle.badge.plus",
                        description: Text("Add someone to get reminded to reach out to them.")
                    )
                } else if isSearching {
                    if searchResults.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                    } else {
                        List {
                            ForEach(searchResults) { contact in
                                NavigationLink(value: contact) {
                                    ContactRow(contact: contact)
                                }
                            }
                            .onDelete { offsets in
                                deleteContacts(offsets, from: searchResults)
                            }
                        }
                    }
                } else {
                    List {
                        if !overdueContacts.isEmpty {
                            Section("Overdue") {
                                ForEach(overdueContacts) { contact in
                                    NavigationLink(value: contact) {
                                        ContactRow(contact: contact)
                                    }
                                }
                                .onDelete { offsets in
                                    deleteContacts(offsets, from: overdueContacts)
                                }
                            }
                        }

                        if !upcomingContacts.isEmpty {
                            Section("Upcoming") {
                                ForEach(upcomingContacts) { contact in
                                    NavigationLink(value: contact) {
                                        ContactRow(contact: contact)
                                    }
                                }
                                .onDelete { offsets in
                                    deleteContacts(offsets, from: upcomingContacts)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Ping")
            .searchable(text: $searchText, prompt: "Search contacts")
            .searchToolbarBehavior(.minimize)
            .navigationDestination(for: PingContact.self) { contact in
                ContactDetailView(contact: contact)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddContact = true
                    } label: {
                        Label("Add Contact", systemImage: "plus")
                    }
                }
                DefaultToolbarItem(kind: .search, placement: .bottomBar)
            }
            .sheet(isPresented: $showingAddContact) {
                AddContactView()
            }
        }
    }

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var searchResults: [PingContact] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return contacts }
        return contacts.filter { contact in
            if contact.name.lowercased().contains(query) { return true }
            if let phone = contact.phoneNumber, phone.lowercased().contains(query) { return true }
            if let email = contact.email, email.lowercased().contains(query) { return true }
            if let company = contact.company, company.lowercased().contains(query) { return true }
            return false
        }
    }

    private var overdueContacts: [PingContact] {
        contacts.filter { $0.isOverdue }
    }

    private var upcomingContacts: [PingContact] {
        contacts.filter { !$0.isOverdue }
    }

    private func deleteContacts(_ offsets: IndexSet, from list: [PingContact]) {
        var groupsToRebalance: Set<String> = []
        withAnimation {
            for index in offsets {
                let contact = list[index]
                groupsToRebalance.insert("\(contact.intervalValue)-\(contact.intervalUnit)")
                NotificationManager.shared.cancelNotifications(for: contact)
                modelContext.delete(contact)
            }
        }
        for key in groupsToRebalance {
            let parts = key.split(separator: "-")
            if let value = Int(parts[0]) {
                let unit = String(parts[1])
                PingContact.rebalanceGroup(intervalValue: value, intervalUnit: unit, in: modelContext)
            }
        }
    }
}

struct ContactRow: View {
    let contact: PingContact

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name)
                    .font(.headline)
                Text(contact.intervalLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if contact.isOverdue {
                Text("Overdue")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.red, in: Capsule())
            } else {
                Text(daysUntilText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private var daysUntilText: String {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()), to: calendar.startOfDay(for: contact.nextPingDate)).day ?? 0
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Tomorrow"
        } else {
            return "In \(days) days"
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: PingContact.self, inMemory: true)
}
