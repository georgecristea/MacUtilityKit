import SwiftUI

/// One permission/setup step in the onboarding checklist.
public struct MUKPermissionRequirement: Identifiable {
    public let id: String
    public let title: String
    public let detail: String
    public let systemImage: String
    /// Action button label (e.g. "Grant", "Download").
    public let actionTitle: String
    /// Reads the current state (polled while onboarding is open).
    public let status: @MainActor () -> MUKPermissionState
    /// Triggers the prompt / opens the relevant System Settings pane / starts the work.
    public let request: @MainActor () -> Void
    /// Optional: while true, the row shows a progress bar instead of the action button.
    public let isInProgress: (@MainActor () -> Bool)?

    public init(
        id: String,
        title: String,
        detail: String,
        systemImage: String,
        actionTitle: String = "Grant",
        status: @escaping @MainActor () -> MUKPermissionState,
        request: @escaping @MainActor () -> Void,
        isInProgress: (@MainActor () -> Bool)? = nil)
    {
        self.id = id
        self.title = title
        self.detail = detail
        self.systemImage = systemImage
        self.actionTitle = actionTitle
        self.status = status
        self.request = request
        self.isInProgress = isInProgress
    }
}

/// First-run setup checklist: a welcome header and one row per requirement, each with a
/// live status dot and a Grant button. Polls the requirement states so rows flip to
/// "Allowed" the moment the user grants them (no app restart). Re-openable from Settings.
@MainActor
public struct MUKOnboardingView: View {
    private let requirements: [MUKPermissionRequirement]
    private let doneTitle: String
    private let onDone: () -> Void

    @State private var states: [String: MUKPermissionState] = [:]

    private let pollTimer = Timer.publish(every: 0.6, on: .main, in: .common).autoconnect()

    public init(
        requirements: [MUKPermissionRequirement],
        doneTitle: String = "Get Started",
        onDone: @escaping () -> Void)
    {
        self.requirements = requirements
        self.doneTitle = doneTitle
        self.onDone = onDone
    }

    private var allGranted: Bool {
        requirements.allSatisfy { states[$0.id] == .granted }
    }

    public var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                MUKBrandIcon(symbol: MUKTheme.brand.symbol, size: 54)
                Text("Welcome to \(MUKTheme.brand.name)")
                    .font(.title2.weight(.semibold))
                if !MUKTheme.brand.tagline.isEmpty {
                    Text(MUKTheme.brand.tagline)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Text("Grant these once and you're ready to go.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 26)
            .padding(.bottom, 18)

            VStack(spacing: 10) {
                ForEach(requirements) { requirement in
                    row(requirement)
                }
            }
            .padding(.horizontal, 22)

            Spacer(minLength: 16)

            VStack(spacing: 6) {
                if allGranted {
                    Label("You're all set", systemImage: "checkmark.circle.fill")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(MUKTheme.success)
                }
                Button(action: onDone) {
                    Text(allGranted ? doneTitle : "Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 22)
        }
        .frame(width: 420, height: 460)
        .background(MUKPopoverBackground())
        .onAppear(perform: refresh)
        .onReceive(pollTimer) { _ in refresh() }
    }

    private func row(_ requirement: MUKPermissionRequirement) -> some View {
        let state = states[requirement.id] ?? .unknown
        return HStack(spacing: 12) {
            MUKBrandIcon(symbol: requirement.systemImage, size: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text(requirement.title).font(.callout.weight(.medium))
                Text(requirement.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            if state == .granted {
                Label("Allowed", systemImage: "checkmark.circle.fill")
                    .labelStyle(.iconOnly)
                    .font(.title3)
                    .foregroundStyle(MUKTheme.success)
            } else if requirement.isInProgress?() == true {
                MUKProgressBar(value: nil).frame(width: 90)
            } else {
                Button(requirement.actionTitle) { requirement.request() }
                    .buttonStyle(.bordered)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: MUKTheme.rowRadius, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6)))
    }

    private func refresh() {
        for requirement in requirements {
            states[requirement.id] = requirement.status()
        }
    }
}
