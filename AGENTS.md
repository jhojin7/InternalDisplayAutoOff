# AGENTS.md

## Project

Mac Toolbox is a personal, native macOS menu-bar utility built with SwiftUI,
AppKit, and Swift Package Manager. It currently controls the built-in display,
blocks Apple Music, and exposes display-effect toggles.

This is a local utility, not an App Store product. Keep solutions small and
direct. Do not introduce accounts, analytics, remote services, update
frameworks, installers, or distribution infrastructure unless explicitly
requested.

## Development workflow

1. Read `README.md` and the relevant source files before making changes.
2. Check `git status --short`. Preserve all existing user changes and avoid
   touching unrelated files.
3. Keep policy and decision logic separate from AppKit and system side effects.
4. Add or update focused tests when changing policy logic.
5. Validate changes with:

   ```sh
   swift build
   swift test
   scripts/package-app.sh
   ```

   If `swift test` fails because the local Command Line Tools installation is
   missing `TestingMacros` or `XCTest`, report that toolchain problem clearly.
   Do not rewrite or delete valid tests merely to make the local environment
   appear green.
6. For a local installation, run:

   ```sh
   scripts/update-installed-app.sh
   ```

7. After the user has reviewed and committed changes on `main`, this repository
   supports:

   ```sh
   git ship
   ```

   `git ship` pushes `main` and updates `/Applications/Mac Toolbox.app` only
   after the push succeeds. Install the repository-local automation once with
   `scripts/install-git-automation.sh`. A merge pulled into `main` also triggers
   the updater through `.githooks/post-merge`.

Do not commit, push, or run `git ship` unless the user explicitly asks. Never
hide a failed push by installing the local app anyway.

## Architecture boundaries

- `MacToolboxApp`: menu-bar UI and application lifecycle.
- `DisplayManager`: observable state, settings, and display actions.
- `DisplayMonitor`: CoreGraphics callbacks and sleep/wake notifications.
- `DisplayTopology`: display discovery and classification.
- `DisplaySwitchPolicy`: pure, testable display decisions.
- `SkyLightBackend`: the narrow private-API boundary.
- `MusicBlocker` and `MusicBlockPolicy`: Music detection and termination.
- `DisplayEffectsController` and `SystemControlsShim`: display-effect APIs.

Prefer extending these boundaries over adding system calls directly to UI code.
New features should be visible, independently switchable, reversible, and easy
to understand from the source.

## Display safety invariants

These rules are mandatory:

1. Never disable the built-in display unless another active, online,
   non-mirrored display with usable dimensions is present.
2. Cache the built-in display ID before changing its state.
3. Re-read and verify the topology after every attempted display change.
4. Restore the built-in display when the last usable external display is
   removed, on wake when appropriate, on normal app termination, and when the
   user requests restoration.
5. Do not mutate display configuration inside a CoreGraphics callback. Schedule
   work onto the appropriate queue and retain the existing debounce behavior.
6. If the private SkyLight function is unavailable or fails, report the failure.
   Do not substitute brightness reduction, mirroring, or another surprising
   behavior.
7. Do not use `SIGKILL` to stop the app. It prevents the normal restoration
   handler from running. The update script must continue to request normal
   termination and abort if the app does not exit.

## What not to do

- Do not add a daemon, privileged helper, kernel extension, administrator
  requirement, or SIP workaround.
- Do not make the project depend on the Mac App Store. Private APIs make that
  distribution path inappropriate.
- Do not replace the narrow dynamic SkyLight lookup with broad undocumented API
  usage elsewhere in the codebase.
- Do not perform display changes from tests. Tests should exercise pure policy
  and topology logic without modifying the current Mac display configuration.
- Do not force-quit Mac Toolbox while its built-in display may be disabled.
- Do not destructively overwrite the installed app without staging the new
  bundle and retaining a rollback path until installation succeeds.
- Do not discard or rewrite unrelated work in a dirty working tree.

## Style

- Follow the existing Swift 6 style and concurrency annotations.
- Prefer small types, explicit names, early guards, and narrow system wrappers.
- Avoid speculative abstractions and third-party dependencies for small tasks.
- Keep menu text concise and user-facing errors actionable.
- Update `README.md` when commands, requirements, behavior, or safety guidance
  changes.
