# Contributing to MacUtilityKit

Thanks for taking a look. MacUtilityKit is the shared toolkit behind
[ClipVault](https://github.com/georgecristea/ClipVault), [VoxKey](https://github.com/georgecristea/VoxKey)
and [Upkeep](https://github.com/georgecristea/upkeep), maintained in spare time, so the best
contributions are focused ones.

- **Bugs:** open an issue with your macOS version, Mac model (Apple Silicon or Intel), and steps to
  reproduce. If it shows up in one of the apps, say which.
- **Features:** open an issue first so we can agree on the shape before you write code. Components
  here must stay app-agnostic: anything specific to one app belongs in that app.
- **Pull requests:** keep them small and on one topic. Run `swift build` and `swift test` before
  pushing. The apps use this package, so public API changes must stay additive (new parameters
  get defaults) unless the change is coordinated with all three.

## Trying a change in an app

Clone the app next to this repo and, in the app's folder:

```sh
swift package edit MacUtilityKit --path ../MacUtilityKit   # use your local copy
swift package unedit MacUtilityKit                         # back to the released version
```

## Licensing

By contributing you agree that your contribution is licensed under this project's
[MIT License](LICENSE).
