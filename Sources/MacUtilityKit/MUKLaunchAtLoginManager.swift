import Foundation

public struct MUKLaunchAtLoginManager {
    private let label: String

    public init(label: String) {
        self.label = label
    }

    public var isEnabled: Bool {
        FileManager.default.fileExists(atPath: launchAgentURL.path)
    }

    public func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try enable()
        } else {
            try disable()
        }
    }

    private var launchAgentURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("LaunchAgents", isDirectory: true)
            .appendingPathComponent("\(label).plist")
    }

    private func enable() throws {
        let directory = launchAgentURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let plist: [String: Any] = [
            "Label": label,
            "ProgramArguments": launchArguments(),
            "RunAtLoad": true
        ]

        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try data.write(to: launchAgentURL, options: .atomic)
    }

    private func disable() throws {
        guard FileManager.default.fileExists(atPath: launchAgentURL.path) else { return }
        try FileManager.default.removeItem(at: launchAgentURL)
    }

    private func launchArguments() -> [String] {
        let bundleURL = Bundle.main.bundleURL
        if bundleURL.pathExtension == "app" {
            return ["/usr/bin/open", bundleURL.path]
        }

        if let executableURL = Bundle.main.executableURL {
            return [executableURL.path]
        }

        return [CommandLine.arguments[0]]
    }
}
