# Internal Display Auto Off

A small native macOS menu-bar utility for an open MacBook connected to an external display. With Auto enabled, it disables the built-in panel when at least one usable external display is active and restores it when the last external display disconnects.

External-display removal is handled immediately from CoreGraphics' removal event, outside the callback itself. A short debounced topology check then reconciles the final state. This avoids waiting for macOS' external-display entry to disappear from a later topology snapshot.

## Build and run

```sh
chmod +x scripts/package-app.sh
scripts/package-app.sh
open dist/InternalDisplayAutoOff.app
```

The app has no Dock icon. Use the display icon in the menu bar to inspect status, pause automation, restore the internal panel, optionally enable launch at login, or quit.

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
