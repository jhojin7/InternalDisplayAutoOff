import CoreGraphics
import Testing
@testable import MacToolbox

@Suite("Display switching policy")
struct DisplaySwitchPolicyTests {
    private let internalID = CGDirectDisplayID(1)
    private let externalID = CGDirectDisplayID(2)

    @Test("External removal restores an inactive built-in display immediately")
    func externalRemovalRestoresImmediately() {
        let event = DisplayChangeEvent(displayID: externalID, flags: [.removeFlag])

        #expect(DisplaySwitchPolicy.shouldRestoreImmediately(
            for: event,
            internalDisplayID: internalID,
            internalIsActive: false,
            autoModeEnabled: true
        ))
    }

    @Test("Other changes do not undo external-only mode")
    func unrelatedChangeDoesNotRestore() {
        let event = DisplayChangeEvent(displayID: externalID, flags: [.movedFlag])

        #expect(!DisplaySwitchPolicy.shouldRestoreImmediately(
            for: event,
            internalDisplayID: internalID,
            internalIsActive: false,
            autoModeEnabled: true
        ))
    }

    @Test("Removing the built-in display does not recursively restore it")
    func internalRemovalDoesNotRestore() {
        let event = DisplayChangeEvent(displayID: internalID, flags: [.removeFlag])

        #expect(!DisplaySwitchPolicy.shouldRestoreImmediately(
            for: event,
            internalDisplayID: internalID,
            internalIsActive: false,
            autoModeEnabled: true
        ))
    }

    @Test("Paused auto mode does not act on removal")
    func pausedModeDoesNotRestore() {
        let event = DisplayChangeEvent(displayID: externalID, flags: [.removeFlag])

        #expect(!DisplaySwitchPolicy.shouldRestoreImmediately(
            for: event,
            internalDisplayID: internalID,
            internalIsActive: false,
            autoModeEnabled: false
        ))
    }
}

@Suite("Music blocking policy")
struct MusicBlockPolicyTests {
    @Test("The real system Music app is blocked")
    func systemMusicIsBlocked() {
        #expect(MusicBlockPolicy.shouldTerminate(
            bundleIdentifier: "com.apple.Music",
            bundlePath: "/System/Applications/Music.app"
        ))
    }

    @Test("A decoy reusing Music's bundle identifier is not terminated")
    func decoyIsNotBlocked() {
        #expect(!MusicBlockPolicy.shouldTerminate(
            bundleIdentifier: "com.apple.Music",
            bundlePath: "/Applications/Music Decoy.app"
        ))
    }

    @Test("An app at the Music path without its identifier is not terminated")
    func unrelatedAppIsNotBlocked() {
        #expect(!MusicBlockPolicy.shouldTerminate(
            bundleIdentifier: "example.app",
            bundlePath: "/System/Applications/Music.app"
        ))
    }
}
