import AppKit

/// Watches the global + local event stream for a push-to-talk hotkey and fires
/// `onDown` when the binding becomes fully pressed and `onUp` when it's released.
/// Uses NSEvent monitors (observe-only; requires Accessibility for global key events).
/// Handles both modifier-only bindings (e.g. Fn+Control) and key+modifier bindings.
@MainActor
public final class MUKHotkeyEngine {
    private var binding: MUKHotkey
    private let onDown: () -> Void
    private let onUp: () -> Void

    private var monitors: [Any] = []
    private var isPressed = false

    public init(binding: MUKHotkey, onDown: @escaping () -> Void, onUp: @escaping () -> Void) {
        self.binding = binding
        self.onDown = onDown
        self.onUp = onUp
    }

    /// Swap the binding at runtime (resets pressed state).
    public func update(binding: MUKHotkey) {
        let wasRunning = !monitors.isEmpty
        stop()
        self.binding = binding
        if wasRunning { start() }
    }

    public func start() {
        stop()
        let mask: NSEvent.EventTypeMask = [.flagsChanged, .keyDown, .keyUp]
        if let global = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: { [weak self] event in
            Task { @MainActor in self?.handle(event) }
        }) {
            monitors.append(global)
        }
        if let local = NSEvent.addLocalMonitorForEvents(matching: mask, handler: { [weak self] event in
            Task { @MainActor in self?.handle(event) }
            return event
        }) {
            monitors.append(local)
        }
    }

    public func stop() {
        for monitor in monitors { NSEvent.removeMonitor(monitor) }
        monitors.removeAll()
        if isPressed {
            isPressed = false
            onUp()
        }
    }

    private func handle(_ event: NSEvent) {
        let current = MUKHotkey.modifiers(from: event.modifierFlags.intersection(.deviceIndependentFlagsMask))

        switch event.type {
        case .flagsChanged:
            if binding.keyCode == nil {
                // Modifier-only binding: pressed exactly when the modifier set matches.
                if current == binding.modifiers, !isPressed {
                    fireDown()
                } else if isPressed, current != binding.modifiers {
                    fireUp()
                }
            } else if isPressed, current != binding.modifiers {
                // Key binding: releasing a required modifier ends the press.
                fireUp()
            }
        case .keyDown:
            if let keyCode = binding.keyCode, event.keyCode == keyCode,
                current == binding.modifiers, !isPressed
            {
                fireDown()
            }
        case .keyUp:
            if let keyCode = binding.keyCode, event.keyCode == keyCode, isPressed {
                fireUp()
            }
        default:
            break
        }
    }

    private func fireDown() {
        isPressed = true
        onDown()
    }

    private func fireUp() {
        isPressed = false
        onUp()
    }
}
