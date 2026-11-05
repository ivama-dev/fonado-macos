import Foundation

@main struct CallbackRequestChecks {
    static func main() throws {
        let zone = TimeZone(secondsFromGMT: 0)!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        let date = calendar.date(from: DateComponents(year: 2026, month: 10, day: 12, hour: 9, minute: 30))!
        let contact = Contact(id: "synthetic", name: "Anna Müller & Söhne #1 + 50%", role: "Test", number: "+43 720 0101010")
        let call = RecentCall(contact: contact, date: date, detail: "Verpasst", missed: true, incoming: true)
        let mail = CallbackRequestMail(recent: call, timeZone: zone)!
        assert(mail.subject == "Rückrufbitte: Anna Müller & Söhne #1 + 50% (+43 720 0101010)")
        assert(mail.body.contains("bitte rufe Anna Müller & Söhne #1 + 50% (+43 720 0101010) zurück."))
        assert(mail.body.contains("Rufnummer: +43 720 0101010"))
        assert(mail.body.contains("12.10.2026 um 09:30"))
        assert(mail.body.contains("Anruf: Verpasst\r\nRichtung: Eingehend"))
        let url = URLComponents(url: mail.url, resolvingAgainstBaseURL: false)!
        assert(url.scheme == "mailto" && url.path.isEmpty && url.host == nil && url.fragment == nil)
        assert(url.queryItems?.map(\.name) == ["subject", "body"])
        assert(url.queryItems?[0].value == mail.subject && url.queryItems?[1].value == mail.body)
        assert(mail.url.absoluteString.contains("%2B43") && mail.url.absoluteString.contains("%0D%0A"))

        // Imported names cannot inject recipients or extra mail headers.
        let injected = CallbackRequestMail(recent: call, name: "Müller\r\nBcc: nobody@example.invalid&body=Test?", timeZone: zone)!
        assert(!injected.subject.contains("\r") && !injected.subject.contains("\n"))
        let injectedURL = URLComponents(url: injected.url, resolvingAgainstBaseURL: false)!
        assert(injectedURL.path.isEmpty && injectedURL.queryItems?.map(\.name) == ["subject", "body"])
        assert(injectedURL.queryItems?[0].value == injected.subject)

        let unknown = Contact(id: "number", name: "101", role: "", number: "101")
        let outgoing = RecentCall(contact: unknown, date: date, detail: "Ausgehend", incoming: false)
        let numberOnly = CallbackRequestMail(recent: outgoing, timeZone: zone)!
        assert(numberOnly.subject == "Rückrufbitte: 101" && !numberOnly.body.contains("Name:"))
        assert(numberOnly.body.contains("Richtung: Ausgehend"))
        let named = CallbackRequestMail(recent: outgoing, name: "Empfang", timeZone: zone)!
        assert(named.subject == "Rückrufbitte: Empfang (101)")
        assert(named.body.contains("Rufnummer: 101"))
        let legacy = RecentCall(contact: unknown, date: date, detail: "Gespräch")
        assert(!CallbackRequestMail(recent: legacy)!.body.contains("Richtung:"))
        for invalid in ["anonymous", "", "+", "1+01", "++101", "101\r\n", "sip:101@example.invalid", "101&bcc=x", String(repeating: "1", count: 129)] {
            let invalidCall = RecentCall(contact: Contact(id: "invalid", name: "Test", role: "", number: invalid), date: date, detail: "Verpasst")
            assert(!CallbackRequestMail.canRequest(for: invalid) && CallbackRequestMail(recent: invalidCall) == nil)
        }
        for valid in ["101", "+437200101010", "+43 (720) 010-1010", "*21101#"] {
            assert(CallbackRequestMail.canRequest(for: valid))
        }
        print("Callback request checks passed: correct contact/number/date, incoming/outgoing/legacy calls, empty recipient, UTF-8 and reserved characters, CRLF, header isolation, unavailable numbers")
    }
}
