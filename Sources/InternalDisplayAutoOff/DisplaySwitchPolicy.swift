import CoreGraphics

struct DisplayChangeEvent: Sendable {
    let displayID: CGDirectDisplayID
    let flags: CGDisplayChangeSummaryFlags
}

enum DisplaySwitchPolicy {
    static func shouldRestoreImmediately(
        for event: DisplayChangeEvent,
        internalDisplayID: CGDirectDisplayID?,
        internalIsActive: Bool,
        autoModeEnabled: Bool
    ) -> Bool {
        guard autoModeEnabled,
              !internalIsActive,
              let internalDisplayID,
              event.displayID != internalDisplayID
        else { return false }

        return event.flags.contains(.removeFlag)
    }
}
