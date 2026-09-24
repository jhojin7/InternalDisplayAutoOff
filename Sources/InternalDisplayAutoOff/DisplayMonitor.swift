import AppKit
import CoreGraphics
import Foundation

private func displayReconfigurationCallback(
    _ display: CGDirectDisplayID,
    _ flags: CGDisplayChangeSummaryFlags,
    _ userInfo: UnsafeMutableRawPointer?
) {
    guard let userInfo else { return }
    let monitor = Unmanaged<DisplayMonitor>.fromOpaque(userInfo).takeUnretainedValue()
    monitor.displayConfigurationDidChange(displayID: display, flags: flags)
}

@MainActor
final class DisplayMonitor {
    private let onChange: () -> Void
    private let onEvent: (DisplayChangeEvent) -> Void
    private var pendingEvaluation: DispatchWorkItem?
    private var observers: [NSObjectProtocol] = []

    init(
        onEvent: @escaping (DisplayChangeEvent) -> Void,
        onChange: @escaping () -> Void
    ) {
        self.onEvent = onEvent
        self.onChange = onChange
        CGDisplayRegisterReconfigurationCallback(
            displayReconfigurationCallback,
            Unmanaged.passUnretained(self).toOpaque()
        )

        for name in [NSWorkspace.didWakeNotification, NSWorkspace.screensDidWakeNotification] {
            observers.append(NSWorkspace.shared.notificationCenter.addObserver(
                forName: name,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.scheduleEvaluation(after: 1.0) }
            })
        }
    }

    nonisolated func displayConfigurationDidChange(
        displayID: CGDirectDisplayID,
        flags: CGDisplayChangeSummaryFlags
    ) {
        let event = DisplayChangeEvent(displayID: displayID, flags: flags)
        Task { @MainActor [weak self] in
            self?.onEvent(event)
            self?.scheduleEvaluation(after: 0.25)
        }
    }

    func scheduleEvaluation(after delay: TimeInterval = 0.25) {
        pendingEvaluation?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.onChange() }
        pendingEvaluation = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    isolated deinit {
        CGDisplayRemoveReconfigurationCallback(
            displayReconfigurationCallback,
            Unmanaged.passUnretained(self).toOpaque()
        )
        for observer in observers {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }
}
