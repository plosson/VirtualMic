# Pouet

macOS virtual microphone driver (C Audio Server Plugin) + companion Swift app. Proxies a real mic through shared memory, allows audio injection from soundboard files.

## Build

The canonical build system is `make`. An Xcode project (`Pouet.xcodeproj`) is also provided for IDE convenience (code completion, debugging, navigation) but is not used for CI or releases.

```bash
make          # build driver + app (unsigned)
make clean    # remove build/
make install  # install driver locally (sudo)
make uninstall
```

To use Xcode: `open Pouet.xcodeproj`. The project mirrors the same sources, frameworks, and flags as the Makefile. Both build systems must stay in sync — if you add/move source files, update both `Makefile` (GUI_SRC) and `Pouet.xcodeproj/project.pbxproj`.

## Release

1. Update version in `App/Info.plist` (both `CFBundleShortVersionString` and `CFBundleVersion`)
2. Commit the version bump
3. Tag and push:

```bash
git tag v1.x.x && git push origin main --tags
```

CI (.github/workflows/build.yml) will automatically: build → sign → notarize → create GitHub Release with the `.pkg` installer.

## Code guidelines

- Keep it simple. No over-engineering, no premature abstractions.
- Go step by step. Never do large refactors in one shot — test stability at each step.
- Prefer editing existing files over creating new ones.
- Run the `code-simplifier` agent after each task to clean up.
- No backward-compatibility shims — if something is unused, delete it.
- Driver code (C) runs on the real-time audio thread — no allocations, no locks, no syscalls.
- Swift app is split into `App/UI/` (SwiftUI views) and `App/Services/` (audio, state, logic).
- Build with `make` (not Xcode) for CI and releases. Verify the build passes before considering a task done.
