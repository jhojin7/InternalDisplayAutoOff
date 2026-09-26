import Combine
import Foundation
import SystemControlsShim

@MainActor
final class DisplayEffectsController: ObservableObject {
    private static let nightShiftStatusDidChange = Notification.Name(
        "MTBNightShiftStatusDidChange"
    )

    @Published private(set) var colorFilterEnabled = false
    @Published private(set) var nightShiftEnabled = false
    @Published private(set) var colorFilterAvailable = false
    @Published private(set) var nightShiftAvailable = false
    @Published private(set) var status = ""

    private var nightShiftStatusObserver: AnyCancellable?

    init() {
        refresh()
        nightShiftStatusObserver = NotificationCenter.default.publisher(
            for: Self.nightShiftStatusDidChange
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] _ in
            self?.refreshNightShiftStatus()
        }
        _ = MTBStartNightShiftStatusNotifications()
    }

    func refresh() {
        colorFilterAvailable = MTBColorFilterIsAvailable()
        colorFilterEnabled = colorFilterAvailable && MTBColorFilterIsEnabled()
        refreshNightShiftStatus()
    }

    private func refreshNightShiftStatus() {
        nightShiftAvailable = MTBNightShiftIsAvailable()
        nightShiftEnabled = nightShiftAvailable && MTBNightShiftIsActive()
    }

    func setColorFilterEnabled(_ enabled: Bool) {
        guard MTBSetColorFilterEnabled(enabled) else {
            status = "Color Filters are unavailable on this macOS version"
            refresh()
            return
        }
        colorFilterEnabled = enabled
        status = "Color Filters \(enabled ? "enabled" : "disabled")"
    }

    func setNightShiftEnabled(_ enabled: Bool) {
        guard MTBSetNightShiftEnabled(enabled) else {
            status = "Night Shift could not be changed"
            refresh()
            return
        }
        nightShiftEnabled = enabled
        status = "Night Shift \(enabled ? "enabled" : "disabled")"
    }
}
