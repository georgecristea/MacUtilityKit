import SwiftUI

/// A rounded-square app glyph filled with the brand gradient. Used in headers and heroes.
public struct MUKBrandIcon: View {
    private let symbol: String
    private let size: CGFloat

    public init(symbol: String = MUKTheme.brand.symbol, size: CGFloat = 28) {
        self.symbol = symbol
        self.size = size
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
            .fill(MUKTheme.accentGradient)
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: symbol)
                    .font(.system(size: size * 0.5, weight: .semibold))
                    .foregroundStyle(.white))
            .shadow(color: MUKTheme.accent.opacity(0.35), radius: size * 0.16, y: size * 0.06)
    }
}

/// A subtle elevated container. The shared surface for grouped content across apps.
public struct MUKCard<Content: View>: View {
    private let padding: CGFloat
    private let content: Content

    public init(padding: CGFloat = 14, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    public var body: some View {
        content
            .padding(padding)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: MUKTheme.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: MUKTheme.cardRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.07), lineWidth: 1))
    }
}

/// Brand-tinted popover backdrop: window material with a soft accent glow at the top.
public struct MUKPopoverBackground: View {
    public init() {}

    public var body: some View {
        ZStack {
            Rectangle().fill(.background)
            RadialGradient(
                colors: [MUKTheme.accent.opacity(0.16), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 300)
        }
        .ignoresSafeArea()
    }
}

/// Live audio meter. Driven by a single 0...1 input level but animated into a lively
/// equalizer so recording feels responsive. Reusable by any app that captures audio.
public struct MUKLevelMeter: View {
    private let level: Double
    private let barCount: Int
    private let height: CGFloat
    private let tint: LinearGradient

    public init(
        level: Double,
        barCount: Int = 13,
        height: CGFloat = 46,
        tint: LinearGradient = MUKTheme.accentGradient)
    {
        self.level = max(0, min(1, level))
        self.barCount = barCount
        self.height = height
        self.tint = tint
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: 0.05, paused: false)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            HStack(alignment: .center, spacing: 3) {
                ForEach(0..<barCount, id: \.self) { index in
                    Capsule()
                        .fill(tint)
                        .frame(width: 4, height: barHeight(index, t))
                }
            }
            .frame(height: height)
            .animation(.easeOut(duration: 0.09), value: level)
        }
    }

    private func barHeight(_ index: Int, _ time: Double) -> CGFloat {
        let center = Double(barCount - 1) / 2
        let distance = center == 0 ? 0 : abs(Double(index) - center) / center  // 0 center … 1 edge
        let envelope = 1.0 - 0.5 * distance                                    // taller in the middle
        let wobble = 0.5 + 0.5 * sin(time * 7.0 + Double(index) * 0.9)         // 0 … 1 per bar
        let amplitude = max(0.05, level) * envelope * (0.4 + 0.6 * wobble)
        let minH = 4.0
        let maxH = Double(height)
        return CGFloat(minH + amplitude * (maxH - minH))
    }
}

/// Compact labeled status pill, e.g. "Mic · Allowed". Tone drives the color.
public struct MUKStatusChip: View {
    private let label: String
    private let value: String
    private let tone: MUKStatusMessage.Tone

    public init(label: String, value: String, tone: MUKStatusMessage.Tone) {
        self.label = label
        self.value = value
        self.tone = tone
    }

    public var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(MUKStatusMessage("", tone: tone).color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(MUKStatusMessage("", tone: tone).color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.quaternary.opacity(0.4), in: Capsule())
    }
}

/// Gradient call-to-action: the one primary action on a screen ("Update all", "Start").
/// Dims when disabled so a screen can keep its layout while the action is unavailable.
public struct MUKPrimaryButton: View {
    @Environment(\.isEnabled) private var isEnabled
    private let title: String
    private let systemImage: String?
    private let action: () -> Void

    public init(_ title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(.callout.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(MUKTheme.accentGradient, in: Capsule())
            .shadow(color: MUKTheme.accent.opacity(isEnabled ? 0.3 : 0), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.45)
    }
}
