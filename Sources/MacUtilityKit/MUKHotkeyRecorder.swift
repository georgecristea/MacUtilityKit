import AppKit
import SwiftUI

/// A control for recording a push-to-talk hotkey. Click to record, then press the
/// combo (modifier-only like Fn+Control, or modifiers + a key). Esc cancels. Shows
/// an inline warning when the chosen binding may conflict with the system or typing.
public struct MUKHotkeyRecorder: View {
    @Binding private var hotkey: MUKHotkey
    @State private var isRecording = false
    @State private var monitor: Any?
    @State private var peakModifiers: MUKHotkey.Modifiers = []

    private let allowsModifierOnly: Bool

    /// - Parameter allowsModifierOnly: pass false for shortcuts that need a key (e.g. one
    ///   registered with `MUKCarbonHotKey`); modifier-only presses are then ignored.
    public init(hotkey: Binding<MUKHotkey>, allowsModifierOnly: Bool = true) {
        self._hotkey = hotkey
        self.allowsModifierOnly = allowsModifierOnly
    }

    /// Whether a recorded candidate is acceptable under the recorder's mode.
    static func accepts(_ candidate: MUKHotkey, allowsModifierOnly: Bool) -> Bool {
        allowsModifierOnly || candidate.keyCode != nil
    }

    public var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Button(action: toggle) {
                Text(isRecording ? "Press keys…" : hotkey.displayString)
                    .font(.system(.callout, design: .rounded).weight(.semibold))
                    .frame(minWidth: 76)
            }
            .buttonStyle(.bordered)
            .tint(isRecording ? MUKTheme.accent : nil)

            switch conflict {
            case .warn(let message), .block(let message):
                Text(message)
                    .font(.caption2)
                    .foregroundStyle(MUKTheme.warning)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 180, alignment: .trailing)
                    .fixedSize(horizontal: false, vertical: true)
            case .ok:
                EmptyView()
            }
        }
        .onDisappear { stopRecording() }
    }

    private var conflict: MUKHotkeyConflict { MUKHotkeyConflicts.evaluate(hotkey) }

    private func toggle() {
        isRecording ? stopRecording() : startRecording()
    }

    private func startRecording() {
        isRecording = true
        peakModifiers = []
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            handle(event)
            return nil  // swallow events while recording
        }
    }

    private func handle(_ event: NSEvent) {
        let current = MUKHotkey.modifiers(from: event.modifierFlags.intersection(.deviceIndependentFlagsMask))
        switch event.type {
        case .keyDown:
            if event.keyCode == 53 {  // Esc cancels
                stopRecording()
                return
            }
            commit(MUKHotkey(keyCode: event.keyCode, modifiers: current))
        case .flagsChanged:
            if current.isEmpty {
                if !peakModifiers.isEmpty {
                    commit(MUKHotkey(keyCode: nil, modifiers: peakModifiers))
                }
            } else {
                peakModifiers.formUnion(current)
            }
        default:
            break
        }
    }

    private func commit(_ candidate: MUKHotkey) {
        guard Self.accepts(candidate, allowsModifierOnly: allowsModifierOnly) else {
            peakModifiers = []  // modifier-only not allowed here; keep recording
            return
        }
        if case .block = MUKHotkeyConflicts.evaluate(candidate) {
            peakModifiers = []  // reject; keep recording
            return
        }
        hotkey = candidate
        stopRecording()
    }

    private func stopRecording() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        isRecording = false
        peakModifiers = []
    }
}
