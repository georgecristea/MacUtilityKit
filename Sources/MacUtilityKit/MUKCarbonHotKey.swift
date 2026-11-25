import AppKit
import Carbon.HIToolbox

/// A system-wide "tap" shortcut registered with Carbon's hotkey API, e.g. ⇧⌘V to show a panel.
///
/// Unlike `MUKGlobalShortcut` (NSEvent monitors), it needs no Accessibility permission and the
/// key press is consumed, so the frontmost app does not also receive it. The binding must have a
/// key; modifier-only bindings cannot be registered.
@MainActor
public final class MUKCarbonHotKey {
    let id: UInt32
    /// "MUKH": marks hotkeys registered by this type, so others' hotkeys are left alone.
    static let signature = OSType(0x4D55_4B48)
    private var ref: EventHotKeyRef?

    /// True while the shortcut is registered with the system.
    public private(set) var isRegistered = false

    public init(binding: MUKHotkey, onTrigger: @escaping () -> Void) {
        id = Self.nextID
        Self.nextID += 1
        Self.actions[id] = onTrigger
        Self.installHandlerOnce()
        update(binding: binding)
    }

    deinit {
        if let ref { UnregisterEventHotKey(ref) }
        let id = id
        Task { @MainActor in Self.actions[id] = nil }
    }

    /// Registers a new binding in place of the current one. Returns false when the binding has
    /// no key or the system refuses it (for example, another app already holds it).
    @discardableResult
    public func update(binding: MUKHotkey) -> Bool {
        stop()
        guard let keyCode = binding.keyCode else { return false }
        let hotKeyID = EventHotKeyID(signature: Self.signature, id: id)
        let status = RegisterEventHotKey(UInt32(keyCode), Self.carbonModifiers(binding.modifiers), hotKeyID,
                                         GetApplicationEventTarget(), 0, &ref)
        isRegistered = status == noErr
        if !isRegistered { ref = nil }
        return isRegistered
    }

    /// Unregisters the shortcut. `update(binding:)` registers it again.
    public func stop() {
        if let ref { UnregisterEventHotKey(ref) }
        ref = nil
        isRegistered = false
    }

    static func carbonModifiers(_ modifiers: MUKHotkey.Modifiers) -> UInt32 {
        var result: UInt32 = 0
        if modifiers.contains(.command) { result |= UInt32(cmdKey) }
        if modifiers.contains(.shift) { result |= UInt32(shiftKey) }
        if modifiers.contains(.option) { result |= UInt32(optionKey) }
        if modifiers.contains(.control) { result |= UInt32(controlKey) }
        return result
    }

    /// The closure for a pressed hotkey, or nil when it was not registered by `MUKCarbonHotKey`.
    static func action(for hotKeyID: EventHotKeyID) -> (() -> Void)? {
        guard hotKeyID.signature == signature else { return nil }
        return actions[hotKeyID.id]
    }

    // One Carbon handler for the process, dispatching to the registered closures by id.
    private static var nextID: UInt32 = 1
    private static var actions: [UInt32: () -> Void] = [:]
    private static var handlerInstalled = false

    private static func installHandlerOnce() {
        guard !handlerInstalled else { return }
        handlerInstalled = true
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                                           nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
            // Leave other code's hotkeys (another library in the same app) to their own handlers.
            guard status == noErr, hotKeyID.signature == MUKCarbonHotKey.signature else {
                return OSStatus(eventNotHandledErr)
            }
            DispatchQueue.main.async { MainActor.assumeIsolated { MUKCarbonHotKey.action(for: hotKeyID)?() } }
            return noErr
        }, 1, &spec, nil, nil)
    }
}
