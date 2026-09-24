# Mac Toolbox

A small, personal native macOS menu-bar toolbox. It currently manages the built-in display and blocks Apple Music from running.

## Apple Music blocker

With **Block Apple Music** enabled, the toolbox watches for the real system app at `/System/Applications/Music.app` and terminates it whenever it launches. A periodic guard catches launches from media keys and background services. The setting is enabled by default and persists between launches. Enable **Launch at Login** for continuous protection.

The blocker checks both the Apple Music bundle identifier and its system path, so it does not terminate unrelated apps that happen to reuse the identifier. Blocking can be paused at any time from the menu.

## Built-in display automation

With display automation enabled, the toolbox disables the built-in panel when at least one usable external display is active and restores it when the last external display disconnects.

External-display removal is handled immediately from CoreGraphics' removal event, outside the callback itself. A short debounced topology check then reconciles the final state. This avoids waiting for macOS' external-display entry to disappear from a later topology snapshot.

## Build and run

```sh
chmod +x scripts/package-app.sh
scripts/package-app.sh
open dist/InternalDisplayAutoOff.app
```

The app has no Dock icon. Use the toolbox icon in the menu bar to manage its features, enable launch at login, or quit.

## Important private-API caveat

macOS has no public API for disabling the open built-in panel. This utility dynamically loads `SLSConfigureDisplayEnabled` from Apple's private SkyLight framework. It is intended for local/personal use, is not Mac App Store compatible, and may stop working after a macOS update. When the private symbol is unavailable, the app reports that state and does not fall back to brightness tricks or mirroring.

## Safety and recovery

- The app refuses to disable the built-in panel unless CoreGraphics reports another active, online, non-mirrored display with usable pixel dimensions.
- The internal display ID is cached before any disable attempt.
- The last-known internal display ID is persisted so a later launch can still offer recovery after an abnormal termination.
- The app restores the panel after the last external display disconnects and when quitting normally.
- Display changes happen only after a debounced re-evaluation, never inside the CoreGraphics callback.

If the panel does not restore, reconnect an external display, open the menu-bar item, and choose **Restore Internal Display**. Logging out or restarting resets session display configuration. Avoid force-killing the process while the built-in display is disabled, because macOS does not deliver normal termination cleanup after `SIGKILL`.

## Logs

```sh
log stream --style compact --predicate 'process == "InternalDisplayAutoOff"'
```
