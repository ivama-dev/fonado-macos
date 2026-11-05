import Combine
import Foundation

enum LDAPAddressBookError: LocalizedError {
    case unavailable
    var errorDescription: String? { "Das Adressbuch ist für diese Firma nicht verfügbar." }
}

struct LDAPContact: Decodable, Identifiable, Equatable {
    let id, name, email, company: String
    let phones: [Phone]
    struct Phone: Decodable, Equatable, Hashable {
        let label, value: String
    }
    func callContact(_ phone: Phone) -> Contact {
        Contact(id: "ldap:\(id):\(phone.value)", name: name.isEmpty ? phone.value : name,
                role: company.isEmpty ? "Adressbuch" : company, number: phone.value)
    }
}

struct LDAPSearchResult: Decodable {
    let tenant_id: String
    let contacts: [LDAPContact]
    let truncated: Bool
}

/// Results exist only in memory and belong to one authenticated company session.
@MainActor
final class LDAPAddressBook: ObservableObject {
    @Published private(set) var context: TeamContext?
    @Published private(set) var enabled = false
    @Published private(set) var configured = false
    @Published private(set) var contacts: [LDAPContact] = []
    @Published private(set) var loading = false
    @Published private(set) var error: String?
    @Published private(set) var truncated = false
    @Published private(set) var searched = false
    private var generation = 0

    func setContext(_ context: TeamContext?, enabled: Bool, configured: Bool) {
        guard self.context != context || self.enabled != enabled || self.configured != configured else { return }
        clear()
        self.context = context
        self.enabled = context != nil && enabled
        self.configured = context != nil && configured
    }

    func clear() {
        generation += 1
        contacts = []; error = nil; truncated = false; loading = false; searched = false
    }

    func search(query: String, using load: () async throws -> LDAPSearchResult) async {
        clear()
        guard let context, enabled, configured, query.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 else { return }
        let request = generation
        loading = true
        defer { if generation == request { loading = false } }
        do {
            let result = try await load()
            try Task.checkCancellation()
            guard generation == request, self.context == context else { return }
            guard result.tenant_id == context.tenantID, result.contacts.count <= 100,
                  Set(result.contacts.map(\.id)).count == result.contacts.count else {
                throw CocoaError(.fileReadCorruptFile)
            }
            contacts = result.contacts; truncated = result.truncated; searched = true
        } catch is CancellationError { return }
        catch {
            guard generation == request, self.context == context else { return }
            self.error = error.localizedDescription
        }
    }
}
