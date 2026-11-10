import AppKit

/// A global "tap" hotkey: fires `onTrigger` once each time the bound key is pressed with
/// exactly the bound modifiers. Unlike `MUKHotkeyEngine` (push-to-talk; separate down/up),
/// this is the right model for an opener shortcut — e.g. ⌘⇧V to show a panel.
///
/// Uses NSEvent monitors (observe-only; requires Accessibility for the global monitor).
/// The local monitor consumes the event when it matches, so the shortcut doesn't also reach
/// the app's own key window.
@MainActor
public final class MUKGlobalShortcut {
    private var binding: MUKHotkey
    private let onTrigger: () -> Void
    private var monitors: [Any] = []

    public init(binding: MUKHotkey, onTrigger: @escaping () -> Void) {
        self.binding = binding
        self.onTrigger = onTrigger
    }

    /// Swap the binding at runtime.
    public func update(binding: MUKHotkey) {
        let wasRunning = !monitors.isEmpty
        stop()
        self.binding = binding
        if wasRunning { start() }
    }

    public func start() {
        stop()
        let mask: NSEvent.EventTypeMask = [.keyDown]
        if let global = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: { [weak self] event in
            Task { @MainActor in self?.handle(event) }
        }) {
            monitors.append(global)
        }
        if let local = NSEvent.addLocalMonitorForEvents(matching: mask, handler: { [weak self] event in
            let consumed = self?.matches(event) ?? false
            if consumed {
                Task { @MainActor in self?.onTrigger() }
                return nil
            }
            return event
        }) {
            monitors.append(local)
        }
    }

    public func stop() {
        for monitor in monitors { NSEvent.removeMonitor(monitor) }
        monitors.removeAll()
    }

    private func handle(_ event: NSEvent) {
        if matches(event) { onTrigger() }
    }

    private func matches(_ event: NSEvent) -> Bool {
        guard let keyCode = binding.keyCode else { return false }
        let current = MUKHotkey.modifiers(from: event.modifierFlags.intersection(.deviceIndependentFlagsMask))
        return event.keyCode == keyCode && current == binding.modifiers
    }
}
