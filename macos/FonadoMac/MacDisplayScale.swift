import AppKit
import SwiftUI

enum MacDisplayScale {
    static let preferenceKey = "fonado.mac.interface-scale-percent"
    static let steps = [100, 110, 125, 150, 175, 200]
    static func normalized(_ percent: Int) -> Int { steps.contains(percent) ? percent : 100 }
    static func factor(_ percent: Int) -> CGFloat { CGFloat(normalized(percent)) / 100 }
    static func larger(_ percent: Int) -> Int { steps.first { $0 > normalized(percent) } ?? 200 }
    static func smaller(_ percent: Int) -> Int { steps.last { $0 < normalized(percent) } ?? 100 }

    static func logicalSize(viewport: CGSize, percent: Int, minimum: CGSize) -> CGSize {
        let scale = factor(percent)
        return CGSize(width: max(minimum.width, viewport.width / scale),
                      height: max(minimum.height, viewport.height / scale))
    }
}

/// Lay out at the corresponding logical size before magnifying. Overflow remains scrollable.
/// Keeping the content's identity stable preserves navigation, entered numbers and ongoing calls.
struct MacScaledViewport<Content: View>: View {
    @AppStorage(MacDisplayScale.preferenceKey) private var percent = 100
    var minimum = CGSize(width: 540, height: 580)
    @ViewBuilder var content: () -> Content
    var body: some View {
        GeometryReader { geometry in
            let scale = MacDisplayScale.factor(percent)
            let logical = MacDisplayScale.logicalSize(viewport: geometry.size, percent: percent, minimum: minimum)
            ScrollView([.horizontal, .vertical]) {
                content()
                    .frame(width: logical.width, height: logical.height, alignment: .topLeading)
                    .scaleEffect(scale, anchor: .topLeading)
                    .frame(width: logical.width * scale, height: logical.height * scale, alignment: .topLeading)
            }.scrollBounceBehavior(.basedOnSize)
        }
    }
}

/// A separate sheet/popover needs its own transform; a parent's transform does not cross windows.
struct MacScaledPresentation<Content: View>: View {
    @AppStorage(MacDisplayScale.preferenceKey) private var percent = 100
    @State private var contentSize = CGSize(width: 540, height: 500)
    @ViewBuilder var content: () -> Content
    private var available: CGSize {
        let screen = NSApp.keyWindow?.screen ?? NSScreen.main
        let size = screen?.visibleFrame.size ?? CGSize(width: 1280, height: 800)
        return CGSize(width: max(320, size.width - 80), height: max(300, size.height - 120))
    }
    var body: some View {
        let scale = MacDisplayScale.factor(percent)
        ScrollView([.horizontal, .vertical]) {
            MacMagnifiedLayout(scale: scale) {
                content()
                    .background {
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear { updateContentSize(geometry.size) }
                                .onChange(of: geometry.size) { _, size in updateContentSize(size) }
                        }
                    }
                    .scaleEffect(scale, anchor: .topLeading)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(width: min(contentSize.width * scale, available.width),
               height: min(contentSize.height * scale, available.height))
    }
    private func updateContentSize(_ size: CGSize) {
        guard size.width.isFinite, size.height.isFinite, size.width > 0, size.height > 0 else { return }
        if abs(contentSize.width - size.width) > 0.5 || abs(contentSize.height - size.height) > 0.5 { contentSize = size }
    }
}

private struct MacMagnifiedLayout: Layout {
    let scale: CGFloat
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let content = subviews.first else { return .zero }
        let size = content.sizeThatFits(.unspecified)
        return CGSize(width: size.width * scale, height: size.height * scale)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(at: bounds.origin, anchor: .topLeading,
            proposal: ProposedViewSize(width: bounds.width / scale, height: bounds.height / scale))
    }
}

struct MacDisplayMenu: View {
    @AppStorage(MacDisplayScale.preferenceKey) private var percent = 100
    var body: some View {
        Menu {
            Button("Vergrößern") { percent = MacDisplayScale.larger(percent) }.disabled(percent == 200)
            Button("Verkleinern") { percent = MacDisplayScale.smaller(percent) }.disabled(percent == 100)
            Divider()
            Picker("Größe der Oberfläche", selection: $percent) {
                ForEach(MacDisplayScale.steps, id: \.self) { value in Text("\(value) %").tag(value) }
            }.pickerStyle(.inline)
            Divider()
            Button("Standardgröße (100 %)") { percent = 100 }
        } label: {
            Text("\(MacDisplayScale.normalized(percent)) %").monospacedDigit()
        }
        .help("Schrift und Bedienelemente vergrößern")
        .accessibilityLabel("Darstellung: \(MacDisplayScale.normalized(percent)) Prozent")
    }
}

struct MacDisplayControls: ToolbarContent {
    @AppStorage(MacDisplayScale.preferenceKey) private var percent = 100
    var body: some ToolbarContent {
        ToolbarItem(id: "display.decrease") {
            Button("Darstellung verkleinern", systemImage: "textformat.size.smaller") { percent = MacDisplayScale.smaller(percent) }
                .labelStyle(.iconOnly).accessibilityIdentifier("display.decrease")
                .disabled(MacDisplayScale.normalized(percent) == 100)
                .help("Darstellung verkleinern (⌘−)").accessibilityLabel("Darstellung verkleinern")
        }
        ToolbarItem(id: "display.menu") { MacDisplayMenu() }
        ToolbarItem(id: "display.increase") {
            Button("Darstellung vergrößern", systemImage: "textformat.size.larger") { percent = MacDisplayScale.larger(percent) }
                .labelStyle(.iconOnly).accessibilityIdentifier("display.increase")
                .disabled(MacDisplayScale.normalized(percent) == 200)
                .help("Darstellung vergrößern (⌘+)").accessibilityLabel("Darstellung vergrößern")
        }
    }
}

struct MacDisplayCommands: Commands {
    @AppStorage(MacDisplayScale.preferenceKey) private var percent = 100
    var body: some Commands {
        CommandGroup(after: .toolbar) {
            Button("Vergrößern") { percent = MacDisplayScale.larger(percent) }
                .keyboardShortcut("+", modifiers: .command).disabled(percent == 200)
            Button("Verkleinern") { percent = MacDisplayScale.smaller(percent) }
                .keyboardShortcut("-", modifiers: .command).disabled(percent == 100)
            Button("Standardgröße") { percent = 100 }.keyboardShortcut("0", modifiers: .command)
            Divider()
            Picker("Größe der Oberfläche", selection: $percent) {
                ForEach(MacDisplayScale.steps, id: \.self) { value in Text("\(value) %").tag(value) }
            }
        }
    }
}
