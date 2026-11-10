# MacUtilityKit

[![CI](https://github.com/georgecristea/MacUtilityKit/actions/workflows/ci.yml/badge.svg)](https://github.com/georgecristea/MacUtilityKit/actions/workflows/ci.yml)
![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE)

A small SwiftUI + AppKit toolkit for macOS menu bar utilities. It gives every app the same
popover layout and theme, plus the parts small menu bar apps keep rewriting: in-place navigation,
hold-to-talk and tap hotkeys, permission checks, a first-run checklist, launch at login, and paste
injection.

It is the shared foundation of three open-source apps. Each one sets its own name, symbol and
colors; everything else looks and behaves the same:

| App | What it does |
|-----|--------------|
| [VoxKey](https://github.com/georgecristea/VoxKey) | Push-to-talk dictation, transcribed on-device |
| [ClipVault](https://github.com/georgecristea/ClipVault) | Private clipboard history |
| [Upkeep](https://github.com/georgecristea/upkeep) | Keeps a curated list of Mac apps and CLIs up to date |

## Requirements

- macOS 13 or newer
- Swift 5.9 or newer (Xcode 15+)
- No third-party dependencies (SwiftUI, AppKit, AVFoundation)

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/georgecristea/MacUtilityKit.git", from: "0.1.0")
],
targets: [
    .executableTarget(name: "MyApp", dependencies: ["MacUtilityKit"])
]
```

Or in Xcode: **File → Add Package Dependencies…** and paste the repository URL.

The API is pre-1.0 and follows what the three apps need, so a minor version can change it.
Commit your `Package.resolved`.

## Quick start

Set the brand once at launch, then build the popover from the shell and headers:

```swift
import MacUtilityKit
import SwiftUI

// AppDelegate.applicationDidFinishLaunching
MUKTheme.brand = MUKBrand(
    name: "Upkeep",
    tagline: "Your core tools, always current",
    symbol: "arrow.triangle.2.circlepath",
    accent: Color(red: 0.10, green: 0.62, blue: 0.55),
    accentSecondary: Color(red: 0.30, green: 0.80, blue: 0.60))

popover.contentSize = NSSize(width: MUKTheme.popoverWidth, height: MUKTheme.popoverHeight)

// The popover's root view
struct MainPopoverView: View {
    @State private var screen: Screen = .home
    enum Screen { case home, settings }

    var body: some View {
        MUKPopoverShell(message: MUKStatusMessage("Everything is up to date", tone: .success)) {
            switch screen {
            case .home:
                MUKHeader(title: "Upkeep", subtitle: "3 apps tracked", systemImage: "arrow.triangle.2.circlepath") {
                    MUKIconButton(systemImage: "gearshape", help: "Settings") { screen = .settings }
                }
            case .settings:
                MUKBackHeader(title: "Settings", onBack: { screen = .home })
            }
        } content: {
            switch screen {
            case .home:
                MUKEmptyState(title: "Nothing to update", detail: "Checked a minute ago", systemImage: "checkmark.seal")
            case .settings:
                MUKSettingsRow(title: "Launch at login", systemImage: "power") {
                    Toggle("", isOn: .constant(true)).labelsHidden()
                }
            }
        }
    }
}
```

## What's inside

| Area | Types |
|------|-------|
| Theme | `MUKBrand`, `MUKTheme` (sizes, spacing, semantic colors), `MUKStatusMessage` |
| Popover layout | `MUKPopoverShell`, `MUKHeader`, `MUKBackHeader`, `MUKStatusFooter`, `MUKPopoverBackground` |
| Components | `MUKBrandIcon`, `MUKCard`, `MUKIconButton`, `MUKPrimaryButton`, `MUKBadge`, `MUKStatusChip`, `MUKSettingsRow`, `MUKProgressBar` (determinate or not), `MUKEmptyState`, `MUKLevelMeter` |
| Hotkeys | `MUKHotkey` (Codable binding + display string), `MUKHotkeyEngine` (hold to talk: key down / key up), `MUKGlobalShortcut` (tap to trigger), `MUKHotkeyRecorder` (SwiftUI recorder with conflict warnings) |
| Permissions & onboarding | `MUKPermissions` (microphone, accessibility), `MUKPermissionRequirement`, `MUKOnboardingView` (first-run checklist that re-checks live) |
| System | `MUKLaunchAtLoginManager`, `MUKPasteInjector` + `MUKPasteboardSnapshot` (paste with ⌘V, restore the clipboard), `MUKPreviewPanel` (floating panel that never takes focus), `MUKHardware` (chip, RAM, cores) |

## Things to know

- **Accessibility permission.** The hotkey monitors and `MUKPasteInjector` use global event
  monitors and synthetic key events, which macOS only allows once the user grants Accessibility.
- **Microphone.** `MUKPermissions` can request microphone access; your app's `Info.plist` needs an
  `NSMicrophoneUsageDescription`.
- **Launch at login** writes a per-user LaunchAgent (`~/Library/LaunchAgents/<label>.plist`), not
  `SMAppService`. That suits unsandboxed apps distributed outside the Mac App Store, but it won't
  work in a sandboxed app.
- **English and US keyboard.** UI strings are English, and hotkey labels assume a US key layout.

## Developing alongside an app

To change the kit and an app together, point the app at your local checkout:

```sh
cd ../VoxKey
swift package edit MacUtilityKit --path ../MacUtilityKit   # use the local copy
swift package unedit MacUtilityKit                         # back to the released version
```

When the change is ready, tag a new version here and bump the app's dependency.

## License

[MIT](LICENSE) © DeepDive Solna AB. Made by [George Cristea](https://github.com/georgecristea).
