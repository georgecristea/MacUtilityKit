import AppKit

/// A push-to-talk hotkey binding: a set of modifier keys and an optional regular key.
/// A modifier-only binding (e.g. Fn+Control) fires while exactly those modifiers are held;
/// a binding with a `keyCode` fires while that key is held with exactly those modifiers.
public struct MUKHotkey: Codable, Equatable, Sendable {
    public struct Modifiers: OptionSet, Codable, Sendable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        public static let control = Modifiers(rawValue: 1 << 0)
        public static let option = Modifiers(rawValue: 1 << 1)
        public static let shift = Modifiers(rawValue: 1 << 2)
        public static let command = Modifiers(rawValue: 1 << 3)
        public static let function = Modifiers(rawValue: 1 << 4)
    }

    /// Carbon/AppKit virtual key code; nil for a modifier-only binding.
    public var keyCode: UInt16?
    public var modifiers: Modifiers

    public init(keyCode: UInt16? = nil, modifiers: Modifiers) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    /// The shipped default: Fn + Control, held to talk.
    public static let fnControl = MUKHotkey(keyCode: nil, modifiers: [.control, .function])

    /// Whether the binding is usable (has at least a key or one modifier).
    public var isEmpty: Bool { keyCode == nil && modifiers.isEmpty }

    /// e.g. "fn ⌃", "⌃⌥Space".
    public var displayString: String {
        var parts: [String] = []
        if modifiers.contains(.function) { parts.append("fn") }
        if modifiers.contains(.control) { parts.append("⌃") }
        if modifiers.contains(.option) { parts.append("⌥") }
        if modifiers.contains(.shift) { parts.append("⇧") }
        if modifiers.contains(.command) { parts.append("⌘") }
        if let keyCode { parts.append(MUKHotkey.keyName(for: keyCode)) }
        return parts.isEmpty ? "—" : parts.joined()
    }

    // MARK: NSEvent bridging

    /// Maps device-independent NSEvent flags to our modifier set.
    public static func modifiers(from flags: NSEvent.ModifierFlags) -> Modifiers {
        var result: Modifiers = []
        if flags.contains(.control) { result.insert(.control) }
        if flags.contains(.option) { result.insert(.option) }
        if flags.contains(.shift) { result.insert(.shift) }
        if flags.contains(.command) { result.insert(.command) }
        if flags.contains(.function) { result.insert(.function) }
        return result
    }

    static func keyName(for keyCode: UInt16) -> String {
        if let named = specialKeyNames[keyCode] { return named }
        // Resolve a character from the current keyboard layout for letter/number keys.
        if let character = KeyboardLayout.character(for: keyCode) {
            return character.uppercased()
        }
        return "Key \(keyCode)"
    }

    private static let specialKeyNames: [UInt16: String] = [
        49: "Space", 36: "Return", 48: "Tab", 51: "Delete", 53: "Esc",
        123: "←", 124: "→", 125: "↓", 126: "↑",
        122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6",
        98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12",
    ]
}

/// Verdict for a candidate binding, used to warn the user in the recorder UI.
public enum MUKHotkeyConflict: Equatable, Sendable {
    case ok
    case warn(String)
    case block(String)
}

public enum MUKHotkeyConflicts {
    /// Curated validation. Blocks unusable bindings; warns about combos that interfere
    /// with normal typing or common system shortcuts.
    public static func evaluate(_ hotkey: MUKHotkey) -> MUKHotkeyConflict {
        if hotkey.isEmpty {
            return .block("Pick at least one modifier (or a key plus a modifier).")
        }
        // A bare regular key with no modifiers would type/trigger constantly.
        if hotkey.keyCode != nil, hotkey.modifiers.isEmpty {
            return .block("Add a modifier — a key on its own would fire while typing.")
        }
        // Bare Fn is reserved by macOS (dictation / emoji / input switching).
        if hotkey.keyCode == nil, hotkey.modifiers == [.function] {
            return .warn("macOS uses Fn on its own for dictation and emoji.")
        }
        // A single modifier alone is easy to trigger by accident.
        if hotkey.keyCode == nil, isSingleModifier(hotkey.modifiers) {
            return .warn("A single modifier can trigger accidentally while you type.")
        }
        if let conflict = systemShortcut(hotkey) {
            return .warn("This may conflict with the system shortcut \(conflict).")
        }
        return .ok
    }

    private static func isSingleModifier(_ modifiers: MUKHotkey.Modifiers) -> Bool {
        [MUKHotkey.Modifiers.control, .option, .shift, .command, .function]
            .contains { modifiers == $0 }
    }

    private static func systemShortcut(_ hotkey: MUKHotkey) -> String? {
        guard let keyCode = hotkey.keyCode else { return nil }
        // A few well-known reserved Command combos.
        if hotkey.modifiers == [.command] {
            switch keyCode {
            case 49: return "⌘Space (Spotlight)"
            case 48: return "⌘Tab (App Switcher)"
            case 12: return "⌘Q (Quit)"
            case 13: return "⌘W (Close)"
            default: return nil
            }
        }
        return nil
    }
}

/// Minimal current-layout character lookup for displaying letter/number keys.
private enum KeyboardLayout {
    static func character(for keyCode: UInt16) -> String? {
        layout[keyCode]
    }

    // ANSI US layout for the common letter/number/punctuation keys.
    private static let layout: [UInt16: String] = [
        0: "a", 1: "s", 2: "d", 3: "f", 4: "h", 5: "g", 6: "z", 7: "x", 8: "c", 9: "v",
        11: "b", 12: "q", 13: "w", 14: "e", 15: "r", 16: "y", 17: "t", 31: "o", 32: "u",
        34: "i", 35: "p", 37: "l", 38: "j", 40: "k", 45: "n", 46: "m",
        18: "1", 19: "2", 20: "3", 21: "4", 23: "5", 22: "6", 26: "7", 28: "8", 25: "9", 29: "0",
        27: "-", 24: "=", 33: "[", 30: "]", 41: ";", 39: "'", 43: ",", 47: ".", 44: "/", 42: "\\", 50: "`",
    ]
}
