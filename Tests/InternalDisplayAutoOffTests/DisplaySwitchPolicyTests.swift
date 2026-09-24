import CoreGraphics
import Testing
@testable import InternalDisplayAutoOff

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
