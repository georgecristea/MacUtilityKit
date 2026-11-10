import Foundation

/// Detected Mac hardware facts, used to tailor model/feature recommendations per machine.
/// All values come from `sysctl` and are cheap to read.
public struct MUKHardware: Sendable, Equatable {
    /// Marketing chip name, e.g. "Apple M4 Max" or "Intel(R) Core(TM) i5…".
    public let chipBrand: String
    /// Board identifier, e.g. "Mac16,6".
    public let modelIdentifier: String
    public let isAppleSilicon: Bool
    public let ramBytes: UInt64
    public let performanceCores: Int
    public let efficiencyCores: Int

    /// Rounded total RAM in GB.
    public var ramGB: Int { Int((Double(ramBytes) / 1_073_741_824).rounded()) }

    /// Every Apple Silicon Mac (M1+) ships a Neural Engine; Intel Macs have none.
    public var hasNeuralEngine: Bool { isAppleSilicon }

    /// Short chip family token: "M1"…"M5" on Apple Silicon, "Intel" otherwise.
    public var chipFamily: String {
        let lower = chipBrand.lowercased()
        for family in ["m5", "m4", "m3", "m2", "m1"] where lower.contains(family) {
            return family.uppercased()
        }
        return isAppleSilicon ? "Apple Silicon" : "Intel"
    }

    public static let current = MUKHardware.detect()

    public static func detect() -> MUKHardware {
        let brand = sysctlString("machdep.cpu.brand_string") ?? "Unknown CPU"
        let model = sysctlString("hw.model") ?? "Unknown"
        let isArm = (sysctlInt("hw.optional.arm64") ?? 0) == 1
        let ram = ProcessInfo.processInfo.physicalMemory
        let pCores = sysctlInt("hw.perflevel0.physicalcpu") ?? (sysctlInt("hw.physicalcpu") ?? 0)
        let eCores = sysctlInt("hw.perflevel1.physicalcpu") ?? 0
        return MUKHardware(
            chipBrand: brand,
            modelIdentifier: model,
            isAppleSilicon: isArm,
            ramBytes: ram,
            performanceCores: pCores,
            efficiencyCores: eCores)
    }

    private static func sysctlString(_ key: String) -> String? {
        var size = 0
        guard sysctlbyname(key, nil, &size, nil, 0) == 0, size > 0 else { return nil }
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname(key, &buffer, &size, nil, 0) == 0 else { return nil }
        return String(cString: buffer)
    }

    private static func sysctlInt(_ key: String) -> Int? {
        var value: Int = 0
        var size = MemoryLayout<Int>.size
        guard sysctlbyname(key, &value, &size, nil, 0) == 0 else { return nil }
        return value
    }
}
