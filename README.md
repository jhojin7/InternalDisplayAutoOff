# Mac Toolbox

A native menu-bar app for the macOS behavior I want to control myself.

I started this project because I wanted my MacBook's built-in display to switch off when I connected an external monitor—without closing the lid, mirroring displays, or turning the brightness down. It has since become a home for other small fixes that are useful every day but do not deserve a separate app.

Mac Toolbox currently handles two jobs:

- **External-display mode** disables the built-in panel while a usable external display is connected and restores it when the last external display goes away.
- **Apple Music blocking** closes the system Music app whenever macOS, a media key, or another service tries to launch it.
- **Display effects** provides direct menu-bar switches for macOS Color Filters and Night Shift.

Both features are independently switchable. The app has no Dock icon, remembers its settings, and can start at login.

## Requirements

- macOS 14 or later
- Apple Silicon or Intel Mac
- Swift 6 command-line tools to build from source

No administrator access, daemon, kernel extension, or SIP change is required.

## Build and install

Build an ad-hoc-signed app bundle:

```sh
scripts/package-app.sh
```

The result is written to `dist/Mac Toolbox.app`. You can run it in place:

```sh
open "dist/Mac Toolbox.app"
```

Or install it in `/Applications`:

```sh
ditto "dist/Mac Toolbox.app" "/Applications/Mac Toolbox.app"
open "/Applications/Mac Toolbox.app"
```

Once it is running, open the toolbox icon in the menu bar. Turn on **Launch at Login** if you want its rules enforced after every login.

## Built-in display control

When **Auto-disable Built-in Display** is enabled, Mac Toolbox reads the current CoreGraphics display topology and looks for an active external display that is online, not mirrored, and has usable pixel dimensions. Only then will it ask macOS to disable the built-in panel.

The panel is restored when:

- the last usable external display is removed;
- the Mac wakes without an external display;
- you choose **Restore Internal Display**; or
- Mac Toolbox quits normally.

Display-removal events get an immediate recovery path, followed by a debounced topology check. This matters because CoreGraphics can report the removal event before its display list has fully caught up.

### Private API warning

macOS does not expose a public API for disabling the panel of an open MacBook. Mac Toolbox dynamically loads `SLSConfigureDisplayEnabled` from Apple's private SkyLight framework.

That has two practical consequences:

1. This app is for personal use and cannot be distributed through the Mac App Store.
2. A macOS update may change or remove the private function and require a code update here.

If SkyLight is unavailable, the app reports that display control is unsupported. It does not fall back to brightness tricks or display mirroring.

### Recovery

The app saves the last known built-in display ID before changing anything and verifies the observed topology after each operation. It also refuses to disable the panel unless another usable display is active.

If the built-in display ever fails to return:

1. Reconnect an external display.
2. Open Mac Toolbox from the menu bar.
3. Choose **Restore Internal Display**.

Logging out or restarting also resets the session's display configuration. Avoid force-killing Mac Toolbox while the built-in panel is disabled, since `SIGKILL` does not allow the normal quit handler to restore it.

## Apple Music blocking

With **Block Apple Music** enabled, Mac Toolbox listens for application launches and checks once per second as a fallback. When the real system Music app appears, it first requests a normal termination and force-terminates it after a short grace period if necessary.

The match uses both:

- bundle identifier: `com.apple.Music`
- bundle path: `/System/Applications/Music.app`

Checking both values prevents the blocker from closing an unrelated app that happens to reuse Music's bundle identifier. Disabling the switch immediately pauses the rule; it does not modify or remove Apple's app.

## Display effects

The **Color Filters** and **Night Shift** switches control the corresponding macOS display settings directly. They do not invoke Apple Shortcuts. Their state is read from the system when the app starts and refreshed as the menu-bar app updates.

These controls use macOS interfaces that Apple does not document for third-party apps: MediaAccessibility preferences for Color Filters and CoreBrightness for Night Shift. Like the built-in display control, they may require maintenance after a macOS update.

## Design

Mac Toolbox is a small SwiftUI and AppKit application built with Swift Package Manager.

| Component | Responsibility |
| --- | --- |
| `MacToolboxApp` | Menu-bar UI and application lifecycle |
| `DisplayManager` | Display state, user settings, and recovery decisions |
| `DisplayMonitor` | CoreGraphics callbacks plus sleep and wake notifications |
| `DisplayTopology` | Snapshot of active, online, mirrored, and built-in displays |
| `DisplaySwitchPolicy` | Testable rules for immediate restoration |
| `SkyLightBackend` | Narrow wrapper around the private display API |
| `MusicBlocker` | Launch observation, periodic checks, and termination |
| `MusicBlockPolicy` | Exact identification of the system Music app |
| `DisplayEffectsController` | Reads and changes Color Filters and Night Shift state |
| `SystemControlsShim` | Narrow Objective-C bridge to the underlying macOS display-effect APIs |

The code deliberately keeps policy separate from AppKit side effects so the important decisions can be tested without changing the current display configuration or launching applications.

## Development

Build the executable directly:

```sh
swift build
```

Run the policy tests:

```sh
swift test
```

Watch the installed app's logs:

```sh
log stream --style compact --predicate 'process == "MacToolbox"'
```

The packaging script creates a conventional `.app` bundle, copies the release executable and property list into place, and applies an ad-hoc signature. There are no third-party runtime dependencies.

## Scope

This is intentionally a personal toolbox rather than a general-purpose system utility. New features should be small, visible in the menu, independently reversible, and understandable from the source. Anything that needs elevated privileges or quietly changes system configuration belongs somewhere else.
