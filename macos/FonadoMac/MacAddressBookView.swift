import SwiftUI

struct MacAddressBookView: View {
    @EnvironmentObject private var customer: CustomerAccount
    var body: some View { MacLDAPSearchView(directory: customer.addressBook) }
}

private struct MacLDAPSearchView: View {
    @EnvironmentObject private var customer: CustomerAccount
    @ObservedObject var directory: LDAPAddressBook
    @State private var query = ""
    var body: some View {
        VStack(spacing: 0) {
            if let company = customer.cloudMemberships.first(where: { $0.id == directory.context?.tenantID }) {
                HStack {
                    Label(company.name, systemImage: "building.2").font(.headline)
                    Spacer()
                }.padding()
                Divider()
            }
            if !directory.enabled {
                ContentUnavailableView("Adressbuch deaktiviert", systemImage: "book.closed",
                                       description: Text("Das Adressbuch ist für diese Firma nicht aktiviert."))
            } else if !directory.configured {
                ContentUnavailableView("Adressbuch wird eingerichtet", systemImage: "book.closed",
                                       description: Text("Die LDAP-Serverdaten müssen in der Kundenverwaltung hinterlegt werden."))
            } else if directory.loading {
                ProgressView("Kontakte suchen …").frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = directory.error {
                ContentUnavailableView {
                    Label("Suche fehlgeschlagen", systemImage: "exclamationmark.magnifyingglass")
                } description: { Text(error) } actions: {
                    Button("Erneut suchen") { Task { await customer.searchAddressBook(query) } }
                }
            } else if directory.contacts.isEmpty {
                ContentUnavailableView(directory.searched ? "Keine Kontakte gefunden" : "Firmenadressbuch durchsuchen",
                                       systemImage: "magnifyingglass",
                                       description: Text(directory.searched ? "Versuche einen anderen Namen oder eine andere Telefonnummer." : "Gib mindestens zwei Zeichen eines Namens, einer E-Mail-Adresse oder einer Telefonnummer ein."))
            } else {
                List(directory.contacts) { contact in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(contact.name.isEmpty ? "Kontakt" : contact.name).font(.headline)
                        if !contact.company.isEmpty { Text(contact.company).foregroundStyle(.secondary) }
                        if !contact.email.isEmpty { Text(contact.email).textSelection(.enabled).foregroundStyle(.secondary) }
                        ForEach(contact.phones, id: \.self) { phone in MacContactRow(contact: contact.callContact(phone)) }
                    }.padding(.vertical, 6)
                }
                if directory.truncated {
                    Text("Weitere Treffer vorhanden. Bitte die Suche eingrenzen.")
                        .font(.callout).foregroundStyle(.secondary).padding()
                }
            }
        }
        .searchable(text: $query, prompt: "Name, E-Mail oder Telefonnummer")
        .task(id: query) {
            directory.clear()
            do { try await Task.sleep(for: .milliseconds(350)) } catch { return }
            await customer.searchAddressBook(query)
        }
        .onChange(of: directory.context) { _, _ in query = "" }
        .onDisappear { directory.clear() }
    }
}
