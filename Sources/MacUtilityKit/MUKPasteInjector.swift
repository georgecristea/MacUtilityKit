import AppKit

/// Synthesizes a paste (⌘V) into the frontmost app via CGEvent. Requires Accessibility.
/// Shared by apps that insert text or clips into other applications.
@MainActor
public final class MUKPasteInjector {
    public init() {}

    /// Whether Accessibility is granted (required to synthesize keystrokes).
    public static var isTrusted: Bool { AXIsProcessTrusted() }

    /// Synthesizes ⌘V. The caller is responsible for having placed the desired content on the
    /// pasteboard. Returns `false` (and does nothing) when Accessibility isn't granted.
    @discardableResult
    public func paste() -> Bool {
        guard Self.isTrusted else { return false }
        sendPasteShortcut()
        return true
    }

    /// Replaces the pasteboard with `text` and pastes it. When `restorePrevious` is true the
    /// previous pasteboard contents are restored shortly after — good for dictation. A clipboard
    /// manager wants `false` so the chosen clip stays on the clipboard.
    @discardableResult
    public func paste(_ text: String, restorePrevious: Bool = false) -> Bool {
        guard Self.isTrusted else { return false }
        let pasteboard = NSPasteboard.general
        let snapshot = restorePrevious ? MUKPasteboardSnapshot.capture(from: pasteboard) : nil

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        sendPasteShortcut()

        if let snapshot {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                snapshot.restore(to: pasteboard)
            }
        }
        return true
    }

    /// The key that types "v" with ⌘ held in the current keyboard layout (9 on US-style
    /// layouts), so ⌘V also pastes on layouts such as Dvorak.
    nonisolated static var pasteKeyCode: CGKeyCode { MUKKeyboardLayout.keyCode(for: "v", commandHeld: true) ?? 9 }

    private func sendPasteShortcut() {
        let source = CGEventSource(stateID: .hidSystemState)
        let keyCode = Self.pasteKeyCode
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}

/// Snapshot of the pasteboard's items, for save/restore around a synthetic paste.
public struct MUKPasteboardSnapshot {
    private let items: [[NSPasteboard.PasteboardType: Data]]

    public static func capture(from pasteboard: NSPasteboard) -> MUKPasteboardSnapshot {
        let captured: [[NSPasteboard.PasteboardType: Data]] = pasteboard.pasteboardItems?.map { item in
            var values: [NSPasteboard.PasteboardType: Data] = [:]
            for type in item.types {
                if let data = item.data(forType: type) {
                    values[type] = data
                }
            }
            return values
        } ?? []
        return MUKPasteboardSnapshot(items: captured)
    }

    public func restore(to pasteboard: NSPasteboard) {
        guard !items.isEmpty else { return }
        pasteboard.clearContents()
        let restored = items.map { values -> NSPasteboardItem in
            let item = NSPasteboardItem()
            for (type, data) in values {
                item.setData(data, forType: type)
            }
            return item
        }
        pasteboard.writeObjects(restored)
    }
}
