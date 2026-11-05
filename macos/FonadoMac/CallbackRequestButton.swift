import SwiftUI

struct CallbackRequestButton: View {
    @EnvironmentObject private var phone: PhoneStore
    @Environment(\.openURL) private var openURL
    @State private var preparing = false
    let recent: RecentCall

    var body: some View {
        Button {
            preparing = true
            Task { @MainActor in
                defer { preparing = false }
                guard phone.recents.contains(where: { $0.id == recent.id }) else { return }
                let favorites = phone.favorites.map {
                    DeviceContact(id: $0.id, name: $0.name,
                                  numbers: [.init(id: $0.id, label: $0.role, value: $0.number)])
                }
                let favorite = DeviceContact.resolvedContact(in: favorites, number: recent.contact.number)
                let resolved = await phone.manager.resolveContact?(recent.contact.number)
                // A contact lookup must not open an old account's draft after sign-out.
                guard !Task.isCancelled, phone.recents.contains(where: { $0.id == recent.id }),
                      let mail = CallbackRequestMail(recent: recent, name: (resolved ?? favorite ?? recent.contact).name) else { return }
                openURL(mail.url) { accepted in
                    if !accepted {
                        phone.manager.show("Das Mailprogramm konnte nicht geöffnet werden. Bitte richte ein Standard-Mailprogramm ein.")
                    }
                }
            }
        } label: {
            Label("Rückrufbitte per E-Mail", systemImage: "envelope")
        }
        .disabled(preparing || !CallbackRequestMail.canRequest(for: recent.contact.number))
        .help(CallbackRequestMail.canRequest(for: recent.contact.number)
              ? "E-Mail mit Name, Rufnummer und Anrufzeit vorbereiten"
              : "Für diesen Anruf ist keine Rückrufnummer verfügbar")
    }
}
