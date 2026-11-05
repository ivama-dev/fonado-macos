import Foundation

@main
struct DisplayScaleChecks {
    static func main() {
        for invalid in [-100, 0, 99, 126, Int.max] {
            precondition(MacDisplayScale.factor(invalid) == 1, "Invalid saved values must keep the interface usable")
        }
        precondition(MacDisplayScale.larger(200) == 200)
        precondition(MacDisplayScale.smaller(100) == 100)
        var value = 100
        while value < 200 {
            let next = MacDisplayScale.larger(value)
            precondition(next > value && MacDisplayScale.smaller(next) == value)
            value = next
        }
        let minimum = CGSize(width: 540, height: 580)
        for viewport in [CGSize(width: 820, height: 580), CGSize(width: 1060, height: 720), CGSize(width: 1512, height: 900)] {
            for percent in MacDisplayScale.steps {
                let logical = MacDisplayScale.logicalSize(viewport: viewport, percent: percent, minimum: minimum)
                let scale = MacDisplayScale.factor(percent)
                precondition(logical.width >= minimum.width && logical.height >= minimum.height)
                precondition(logical.width * scale >= viewport.width - 0.001)
                precondition(logical.height * scale >= viewport.height - 0.001)
            }
        }
        let suite = "app.fonado.display-check." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(175, forKey: MacDisplayScale.preferenceKey)
        precondition(UserDefaults(suiteName: suite)!.integer(forKey: MacDisplayScale.preferenceKey) == 175)
        print("PASS: safe preferences, reversible size steps, 200 percent, small/large viewport overflow and persistence")
    }
}
