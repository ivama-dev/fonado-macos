import Foundation

@main
struct LDAPAddressBookChecks {
    @MainActor static func main() async throws {
        let context = TeamContext(tenantID: "alpha", accountID: "owner", sessionID: UUID())
        let book = LDAPAddressBook()
        let json = #"{"tenant_id":"alpha","contacts":[{"id":"anna","name":"Anna Berger","email":"anna@example.test","company":"Beispiel","phones":[{"label":"mobile","value":"+436641234567"}]}],"truncated":false}"#
        let result = try JSONDecoder().decode(LDAPSearchResult.self, from: Data(json.utf8))
        book.setContext(context, enabled: true, configured: true)
        await book.search(query: "a") { fatalError("Short searches must not use the network") }
        precondition(book.contacts.isEmpty && !book.loading)
        await book.search(query: "Anna") { result }
        precondition(book.contacts.count == 1 && book.searched && !book.loading)
        let contact = book.contacts[0].callContact(book.contacts[0].phones[0])
        precondition(contact.name == "Anna Berger" && contact.number == "+436641234567" && contact.role == "Beispiel")

        var reply: CheckedContinuation<LDAPSearchResult, Error>?
        let oldRequest = Task { @MainActor in
            await book.search(query: "Anna") { try await withCheckedThrowingContinuation { reply = $0 } }
        }
        while reply == nil { await Task.yield() }
        precondition(book.contacts.isEmpty)
        await book.search(query: "Anna Berger") { result }
        reply?.resume(throwing: CocoaError(.fileReadCorruptFile)); await oldRequest.value
        precondition(book.contacts.count == 1 && book.error == nil && !book.loading)

        reply = nil
        let tenantRequest = Task { @MainActor in
            await book.search(query: "Anna") { try await withCheckedThrowingContinuation { reply = $0 } }
        }
        while reply == nil { await Task.yield() }
        book.setContext(TeamContext(tenantID: "beta", accountID: "owner", sessionID: UUID()), enabled: true, configured: true)
        reply?.resume(returning: result); await tenantRequest.value
        precondition(book.contacts.isEmpty && !book.loading)

        book.setContext(context, enabled: true, configured: true)
        let foreign = LDAPSearchResult(tenant_id: "other", contacts: result.contacts, truncated: false)
        await book.search(query: "Anna") { foreign }
        precondition(book.contacts.isEmpty && book.error != nil)
        await book.search(query: "Anna") { result }
        book.setContext(context, enabled: false, configured: true)
        precondition(book.contacts.isEmpty && !book.enabled)
        await book.search(query: "Anna") { fatalError("Disabled directory must not search") }
        book.setContext(nil, enabled: true, configured: true)
        precondition(!book.enabled && !book.configured && book.contacts.isEmpty)
        print("PASS: LDAP search decoding, call actions, query races, tenant changes, foreign replies, disable and logout")
    }
}
