import Foundation

@main
struct ContactsDirectoryChecks {
    @MainActor
    static func main() async {
        let contact = DeviceContact(id: "anna", name: "Anna", numbers: [
            DevicePhoneNumber(id: "mobile", label: "Mobil", value: "+436641234567")
        ])
        let directory = ContactsDirectory()
        await directory.refresh(currentAccess: { .allowed }) { [contact] }
        precondition(directory.contacts == [contact] && !directory.isLoading && directory.errorMessage == nil)

        // A cancelled current request must finish its loading state, even if its loader returns a result.
        var reply: CheckedContinuation<[DeviceContact], Error>?
        let cancelled = Task { @MainActor in
            await directory.refresh(currentAccess: { .allowed }) {
                try await withCheckedThrowingContinuation { reply = $0 }
            }
        }
        while reply == nil { await Task.yield() }
        precondition(directory.isLoading && directory.contacts.isEmpty)
        cancelled.cancel()
        reply?.resume(returning: [contact])
        await cancelled.value
        precondition(!directory.isLoading && directory.contacts.isEmpty && directory.errorMessage == nil)

        // Cancellation can also arrive through a loader throwing, without becoming a visible error.
        reply = nil
        let cancelledFailure = Task { @MainActor in
            await directory.refresh(currentAccess: { .allowed }) {
                try await withCheckedThrowingContinuation { reply = $0 }
            }
        }
        while reply == nil { await Task.yield() }
        cancelledFailure.cancel()
        reply?.resume(throwing: CancellationError())
        await cancelledFailure.value
        precondition(!directory.isLoading && directory.errorMessage == nil)

        // Finishing an older request must not dismiss the newest request's loading indicator.
        reply = nil
        let oldRequest = Task { @MainActor in
            await directory.refresh(currentAccess: { .allowed }) {
                try await withCheckedThrowingContinuation { reply = $0 }
            }
        }
        while reply == nil { await Task.yield() }
        var latestReply: CheckedContinuation<[DeviceContact], Error>?
        let latestRequest = Task { @MainActor in
            await directory.refresh(currentAccess: { .allowed }) {
                try await withCheckedThrowingContinuation { latestReply = $0 }
            }
        }
        while latestReply == nil { await Task.yield() }
        oldRequest.cancel()
        reply?.resume(returning: [contact])
        await oldRequest.value
        precondition(directory.isLoading && directory.contacts.isEmpty && directory.errorMessage == nil)
        latestReply?.resume(returning: [contact])
        await latestRequest.value
        precondition(!directory.isLoading && directory.contacts == [contact])

        // Clearing the directory invalidates a late response synchronously.
        reply = nil
        let clearedRequest = Task { @MainActor in
            await directory.refresh(currentAccess: { .allowed }) {
                try await withCheckedThrowingContinuation { reply = $0 }
            }
        }
        while reply == nil { await Task.yield() }
        directory.clear()
        precondition(!directory.isLoading && directory.contacts.isEmpty)
        reply?.resume(returning: [contact])
        await clearedRequest.value
        precondition(!directory.isLoading && directory.contacts.isEmpty)

        await directory.refresh(currentAccess: { .allowed }) { throw CocoaError(.fileReadUnknown) }
        precondition(!directory.isLoading && directory.contacts.isEmpty && directory.errorMessage != nil)
        await directory.refresh(currentAccess: { .denied }) { preconditionFailure("Denied contacts must not be read") }
        precondition(!directory.isLoading && directory.contacts.isEmpty && directory.errorMessage == nil)

        var permission = ContactsDirectory.Access.allowed
        await directory.refresh(currentAccess: { permission }) {
            permission = .denied
            return [contact]
        }
        precondition(directory.access == .denied && directory.contacts.isEmpty && !directory.isLoading)
        print("PASS: contact loading cancellation, overlapping refreshes, clear, errors and permission changes without Contacts access")
    }
}
