# Mac Toolbox handoff

## Goal

Build and run a personal native macOS menu-bar toolbox. It manages the built-in display and blocks Apple Music.

## Current understanding

- macOS exposes display-change notifications through CoreGraphics, but no public API for disabling the open built-in panel.
- The practical local-only implementation dynamically loads `SLSConfigureDisplayEnabled` from the private SkyLight framework.
- This Mac runs macOS 27.0 on Apple Silicon. Swift 6.4 Command Line Tools are installed; full Xcode is not currently selected.

## Constraints

- Native Swift/SwiftUI, menu-bar only (`LSUIElement`), no Dock icon.
- No daemon, root access, SIP changes, kernel extension, or brightness/mirroring fallback.
- Do not mutate display configuration inside the CoreGraphics callback.
- Private API use makes this unsuitable for the Mac App Store and potentially sensitive to OS updates.

## Architecture

- `DisplayMonitor`: CoreGraphics callback plus sleep/wake notifications; debounces topology changes.
- `DisplayManager`: owns observable status and the safety-first auto-mode state machine.
- `SkyLightBackend`: `dlopen`/`dlsym`, with CoreGraphics begin/complete configuration calls.
- `MusicBlocker`: closes the system Music app when it launches.
- SwiftUI `MenuBarExtra`: feature controls, status, launch at login, and Quit.
- SwiftPM builds the executable; a packaging script creates a standard `.app` bundle.

## Safety invariants

1. Never disable the built-in display unless at least one other active, online, non-mirrored display has usable pixel dimensions.
2. Cache the built-in display ID before disabling it.
3. Re-read the topology after every attempted change and report the observed result.
4. Restore on external-display removal, app termination where macOS permits, wake, and explicit user action.
5. If SkyLight is unavailable or returns an error, report unsupported/failure and do not substitute another technique.
6. Configuration work runs after the display callback, on the main queue, with debounce.

## Done criteria

- Project builds as the `MacToolbox` Swift package and packages as `Mac Toolbox.app`.
- Release build and `.app` packaging succeed.
- App launches and its menu-bar UI is visible.
- External-display auto-disable is tested only when another usable display is confirmed; otherwise detection and no-external safety paths are validated.
- Final report includes exact path, build/run results, private-API behavior, and blockers.
