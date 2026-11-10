# MacUtilityKit

A shared **SwiftUI toolkit for macOS menu bar utilities**: one layout/theme system plus reusable
building blocks, so several small apps look and behave alike while each keeps its own brand color
and symbol. Public Swift package, consumed by VoxKey, ClipVault and Upkeep through
`.package(url: "https://github.com/georgecristea/MacUtilityKit.git", from: …)`.

## What it exports

```
Sources/MacUtilityKit/
  MUKTheme.swift           MUKBrand, MUKTheme (sizing + semantic colors), MUKStatusMessage
  MUKComponents.swift      MUKBrandIcon, MUKCard, MUKPopoverBackground, MUKLevelMeter, MUKStatusChip,
                           MUKPrimaryButton
  MUKViews.swift           MUKPopoverShell, MUKHeader, MUKBackHeader, MUKIconButton, MUKStatusFooter,
                           MUKBadge, MUKSettingsRow, MUKProgressBar, MUKEmptyState
  MUKPermissions.swift     MUKPermissionState, MUKPermissions (microphone + accessibility)
  MUKOnboarding.swift      MUKPermissionRequirement, MUKOnboardingView (first-run checklist)
  MUKHotkey*.swift         MUKHotkey, MUKHotkeyEngine (hold), MUKHotkeyRecorder, conflict checks
  MUKGlobalShortcut.swift  tap-to-trigger shortcut
  MUKPasteInjector.swift   synthesized ⌘V + pasteboard snapshot/restore
  MUKPreviewPanel.swift    floating, non-activating preview panel
  MUKHardware.swift        chip / RAM / core detection
  MUKLaunchAtLoginManager.swift   LaunchAgent-based launch-at-login
```

## Conventions

- **The host app sets `MUKTheme.brand` once at launch** (name, tagline, symbol, accent + secondary
  accent). Every component reads the brand for color/gradient/glyph — never hardcode app-specific
  colors here.
- Components are **app-agnostic and reusable**. If something is specific to one app, it belongs in
  that app, not here. When a consuming app needs a new reusable UI pattern, add it here so all apps
  benefit.
- Sizing/spacing constants live in `MUKTheme` (`popoverWidth/Height`, `rowRadius`, `cardRadius`,
  `edgePadding`, …). Use them instead of magic numbers.
- `MUKPopoverShell` is the standard popover frame (header + divider + content + optional status
  footer). In-popover navigation (main ↔ settings ↔ about) uses `MUKHeader` for the root and
  `MUKBackHeader` for sub-screens.

## Build and release

```sh
swift build
```

Pure SwiftUI/AppKit, no third-party dependencies, macOS 13+. To develop against an app, run
`swift package edit MacUtilityKit --path ../MacUtilityKit` in the app repo. A change ships by
tagging a new semver version here (`git tag 0.2.0 && git push --tags`), then bumping the app's
dependency and `Package.resolved`.
