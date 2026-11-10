import AppKit
import SwiftUI

/// A fast, reusable floating preview panel: a borderless, non-activating window that shows
/// arbitrary SwiftUI content next to an anchor rectangle (e.g. beside a popover). It never
/// takes focus or mouse events, so it won't disturb the window it accompanies — ideal for a
/// hover/selection preview. One instance is reused; `show` just updates content + position.
@MainActor
public final class MUKPreviewPanel {
    private var panel: NSPanel?
    private let hosting = NSHostingController(rootView: AnyView(EmptyView()))

    public init() {}

    public var isVisible: Bool { panel?.isVisible ?? false }

    /// Show (or move/update) the panel beside `anchor` (a rect in screen coordinates).
    /// `edge` = .minX places it to the left of the anchor; it flips to the right if there's
    /// no room. The panel is top-aligned to the anchor and clamped to the visible screen.
    ///
    /// Pass `attachedTo` the window the preview accompanies (e.g. the popover window): the
    /// panel becomes a child window, so it's automatically hidden when that window closes —
    /// it can never linger on screen after its parent goes away.
    public func show<Content: View>(
        size: NSSize,
        relativeTo anchor: NSRect,
        edge: NSRectEdge = .minX,
        gap: CGFloat = 10,
        attachedTo parent: NSWindow? = nil,
        @ViewBuilder content: () -> Content)
    {
        hosting.rootView = AnyView(content())
        let panel = ensurePanel()
        let origin = position(size: size, anchor: anchor, edge: edge, gap: gap)
        panel.setFrame(NSRect(origin: origin, size: size), display: true)

        if let parent {
            if panel.parent !== parent {
                panel.parent?.removeChildWindow(panel)
                parent.addChildWindow(panel, ordered: .above) // also orders it on screen
            }
        } else if !panel.isVisible {
            panel.orderFront(nil)
        }
    }

    public func hide() {
        guard let panel else { return }
        panel.parent?.removeChildWindow(panel)
        panel.orderOut(nil)
    }

    private func ensurePanel() -> NSPanel {
        if let panel { return panel }
        let created = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 320),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true)
        created.isOpaque = false
        created.backgroundColor = .clear
        created.hasShadow = true
        created.level = .floating
        created.ignoresMouseEvents = true
        created.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        created.contentViewController = hosting
        panel = created
        return created
    }

    private func position(size: NSSize, anchor: NSRect, edge: NSRectEdge, gap: CGFloat) -> NSPoint {
        var x: CGFloat = edge == .maxX ? anchor.maxX + gap : anchor.minX - size.width - gap
        var y = anchor.maxY - size.height // top-aligned to the anchor

        let screen = NSScreen.screens.first { $0.frame.intersects(anchor) } ?? NSScreen.main
        if let visible = screen?.visibleFrame {
            if x < visible.minX { x = anchor.maxX + gap }            // flip right if no room left
            x = min(max(x, visible.minX), visible.maxX - size.width)
            y = min(max(y, visible.minY), visible.maxY - size.height)
        }
        return NSPoint(x: x, y: y)
    }
}
