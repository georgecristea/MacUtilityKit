import Carbon.HIToolbox
import CoreGraphics
import Foundation

/// Maps virtual key codes to the characters they type in the current keyboard layout, and
/// back. Use it to synthesize shortcuts by character (⌘V types "v" on any layout, not only on
/// the US key position) and to show recorded shortcuts with the right key label.
public enum MUKKeyboardLayout {
    /// The lowercase character `keyCode` types with no modifiers, or nil when the key types
    /// nothing visible or the layout cannot be read.
    public static func character(for keyCode: CGKeyCode) -> String? {
        guard let source = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue(),
              let raw = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else { return nil }
        let layoutData = Unmanaged<CFData>.fromOpaque(raw).takeUnretainedValue() as Data
        var deadKeyState: UInt32 = 0
        var chars = [UniChar](repeating: 0, count: 4)
        var length = 0
        let status = layoutData.withUnsafeBytes { buffer -> OSStatus in
            guard let layout = buffer.baseAddress?.assumingMemoryBound(to: UCKeyboardLayout.self) else { return -1 }
            return UCKeyTranslate(layout, keyCode, UInt16(kUCKeyActionDisplay), 0, UInt32(LMGetKbdType()),
                                  OptionBits(kUCKeyTranslateNoDeadKeysBit), &deadKeyState, chars.count, &length, &chars)
        }
        guard status == noErr, length > 0 else { return nil }
        let string = String(utf16CodeUnits: chars, count: length).lowercased()
        guard string.unicodeScalars.allSatisfy({ !CharacterSet.controlCharacters.contains($0) && !CharacterSet.whitespaces.contains($0) })
        else { return nil }
        return string
    }

    /// The first key code (0–127) that types `character` in the current layout.
    public static func keyCode(for character: String) -> CGKeyCode? {
        let wanted = character.lowercased()
        return (CGKeyCode(0)..<128).first { self.character(for: $0) == wanted }
    }
}
