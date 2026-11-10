import SwiftUI

public struct MUKPopoverShell<Header: View, Content: View>: View {
    private let header: Header
    private let content: Content
    private let message: MUKStatusMessage?

    public init(
        message: MUKStatusMessage? = nil,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content)
    {
        self.header = header()
        self.content = content()
        self.message = message
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, MUKTheme.edgePadding)
                .padding(.top, 14)
                .padding(.bottom, 12)
            Divider().opacity(0.5)
            content
            if let message {
                Divider().opacity(0.5)
                MUKStatusFooter(message: message)
            }
        }
        .frame(width: MUKTheme.popoverWidth, height: MUKTheme.popoverHeight)
        .background(MUKPopoverBackground())
    }
}

public struct MUKHeader<Trailing: View>: View {
    private let title: String
    private let subtitle: String?
    private let systemImage: String
    private let trailing: Trailing

    public init(
        title: String,
        subtitle: String? = nil,
        systemImage: String,
        @ViewBuilder trailing: () -> Trailing)
    {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(spacing: 11) {
            MUKBrandIcon(symbol: systemImage, size: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            trailing
        }
        .buttonStyle(.borderless)
    }
}

/// Header for an in-popover sub-screen (Settings, About). A back chevron returns to the
/// previous screen; the popover itself stays the same `.transient` popover so it still
/// dismisses on click-away. Pairs with `MUKHeader` (used for the root screen).
public struct MUKBackHeader<Trailing: View>: View {
    private let title: String
    private let onBack: () -> Void
    private let trailing: Trailing

    public init(
        title: String,
        onBack: @escaping () -> Void,
        @ViewBuilder trailing: () -> Trailing)
    {
        self.title = title
        self.onBack = onBack
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(spacing: 10) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .help("Back")

            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            trailing
        }
        .buttonStyle(.borderless)
    }
}

extension MUKBackHeader where Trailing == EmptyView {
    public init(title: String, onBack: @escaping () -> Void) {
        self.init(title: title, onBack: onBack, trailing: { EmptyView() })
    }
}

/// A thin progress bar. Determinate when given a 0...1 `value`; indeterminate (a sliding
/// segment) when `value` is nil — used for "loading model into memory" where there's no
/// fraction. Brand-tinted. Reusable across apps for downloads/loads.
public struct MUKProgressBar: View {
    private let value: Double?
    private let height: CGFloat

    public init(value: Double? = nil, height: CGFloat = 4) {
        self.value = value.map { max(0, min(1, $0)) }
        self.height = height
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary.opacity(0.5))
                if let value {
                    Capsule()
                        .fill(MUKTheme.accentGradient)
                        .frame(width: max(height, geo.size.width * value))
                        .animation(.easeOut(duration: 0.2), value: value)
                } else {
                    MUKIndeterminateSegment(trackWidth: geo.size.width, height: height)
                }
            }
        }
        .frame(height: height)
    }
}

private struct MUKIndeterminateSegment: View {
    let trackWidth: CGFloat
    let height: CGFloat
    @State private var animate = false

    var body: some View {
        let segmentWidth = max(40, trackWidth * 0.35)
        Capsule()
            .fill(MUKTheme.accentGradient)
            .frame(width: segmentWidth)
            .offset(x: animate ? max(0, trackWidth - segmentWidth) : 0)
            .animation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true), value: animate)
            .onAppear { animate = true }
    }
}

public struct MUKIconButton: View {
    private let systemImage: String
    private let help: String
    private let action: () -> Void

    public init(systemImage: String, help: String, action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.help = help
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .frame(width: 24, height: 24)
        }
        .help(help)
    }
}

public struct MUKStatusFooter: View {
    private let message: MUKStatusMessage

    public init(message: MUKStatusMessage) {
        self.message = message
    }

    public var body: some View {
        Text(message.text)
            .font(.caption)
            .foregroundStyle(message.color)
            .lineLimit(1)
            .padding(.horizontal, MUKTheme.edgePadding)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

public struct MUKBadge: View {
    private let text: String
    private let tone: MUKStatusMessage.Tone

    public init(_ text: String, tone: MUKStatusMessage.Tone = .neutral) {
        self.text = text
        self.tone = tone
    }

    public var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.12), in: Capsule())
    }

    private var color: Color {
        MUKStatusMessage("", tone: tone).color
    }
}

public struct MUKSettingsRow<Accessory: View>: View {
    private let title: String
    private let detail: String?
    private let systemImage: String
    private let accessory: Accessory

    public init(
        title: String,
        detail: String? = nil,
        systemImage: String,
        @ViewBuilder accessory: () -> Accessory)
    {
        self.title = title
        self.detail = detail
        self.systemImage = systemImage
        self.accessory = accessory()
    }

    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.callout)
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            accessory
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: MUKTheme.rowRadius))
    }
}

public struct MUKEmptyState: View {
    private let title: String
    private let detail: String
    private let systemImage: String

    public init(title: String, detail: String, systemImage: String) {
        self.title = title
        self.detail = detail
        self.systemImage = systemImage
    }

    public var body: some View {
        VStack(spacing: 9) {
            Image(systemName: systemImage)
                .font(.system(size: 34))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.callout.weight(.medium))
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
