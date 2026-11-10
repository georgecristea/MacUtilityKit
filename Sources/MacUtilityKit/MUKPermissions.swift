import AppKit
import AVFoundation

public enum MUKPermissionState: Equatable {
    case granted
    case denied
    case notDetermined
    case unknown

    public var label: String {
        switch self {
        case .granted: "Allowed"
        case .denied: "Not Allowed"
        case .notDetermined: "Not Set"
        case .unknown: "Unknown"
        }
    }

    public var tone: MUKStatusMessage.Tone {
        self == .granted ? .success : .warning
    }
}

public enum MUKPermissions {
    public static var microphone: MUKPermissionState {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized: .granted
        case .denied, .restricted: .denied
        case .notDetermined: .notDetermined
        @unknown default: .unknown
        }
    }

    public static func requestMicrophone() async -> MUKPermissionState {
        let granted = await AVCaptureDevice.requestAccess(for: .audio)
        return granted ? .granted : .denied
    }

    public static var accessibility: MUKPermissionState {
        AXIsProcessTrusted() ? .granted : .denied
    }

    public static func promptForAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}
