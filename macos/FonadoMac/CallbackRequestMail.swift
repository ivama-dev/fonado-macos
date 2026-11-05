import Foundation

/// A draft for the system mail handler. The recipient is deliberately left empty.
struct CallbackRequestMail {
    let subject: String
    let body: String
    let url: URL

    static func canRequest(for number: String) -> Bool {
        guard !number.isEmpty, number.count <= 128,
              number.unicodeScalars.allSatisfy(CharacterSet(charactersIn: "0123456789+*# ()-.\u{00a0}\u{202f}\u{2009}").contains) else { return false }
        let normalized = number.filter { "0123456789+*#".contains($0) }
        return normalized.contains(where: { "0123456789".contains($0) })
            && normalized.filter { $0 == "+" }.count <= 1
            && (!normalized.contains("+") || normalized.first == "+")
    }

    init?(recent: RecentCall, name: String? = nil, timeZone: TimeZone = .current) {
        guard Self.canRequest(for: recent.contact.number) else { return nil }
        let number = recent.contact.number.trimmingCharacters(in: .whitespaces)
        let name = Self.singleLine(name ?? recent.contact.name)
        let hasName = !name.isEmpty && name != number && name.lowercased() != "anonymous"
        let target = hasName ? "\(name) (\(number))" : number
        subject = "Rückrufbitte: \(target)"

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_AT")
        formatter.timeZone = timeZone
        formatter.dateFormat = "dd.MM.yyyy 'um' HH:mm zzz"
        var lines = ["Hallo,", "", "bitte rufe \(target) zurück.", ""]
        if hasName { lines.append("Name: \(name)") }
        lines.append("Rufnummer: \(number)")
        lines.append("Anrufzeit: \(formatter.string(from: recent.date))")
        lines.append("Anruf: \(recent.missed ? "Verpasst" : Self.singleLine(recent.detail))")
        if let incoming = recent.incoming { lines.append("Richtung: \(incoming ? "Eingehend" : "Ausgehend")") }
        body = lines.joined(separator: "\r\n")

        // Encode values independently so names, +, &, # and % remain literal text.
        let unreserved = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        guard let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: unreserved),
              let encodedBody = body.addingPercentEncoding(withAllowedCharacters: unreserved),
              let url = URL(string: "mailto:?subject=\(encodedSubject)&body=\(encodedBody)") else { return nil }
        self.url = url
    }

    private static func singleLine(_ value: String) -> String {
        value.components(separatedBy: .controlCharacters.union(.whitespacesAndNewlines))
            .filter { !$0.isEmpty }.joined(separator: " ")
    }
}
