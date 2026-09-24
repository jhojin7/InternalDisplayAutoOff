import Combine
import Foundation
import SystemControlsShim

@MainActor
final class DisplayEffectsController: ObservableObject {
    @Published private(set) var colorFilterEnabled = false
    @Published private(set) var nightShiftEnabled = false
    @Published private(set) var colorFilterAvailable = false
    @Published private(set) var nightShiftAvailable = false
    @Published private(set) var status = ""

    init() {
        refresh()
    }

    func refresh() {
        colorFilterAvailable = MTBColorFilterIsAvailable()
        nightShiftAvailable = MTBNightShiftIsAvailable()
        colorFilterEnabled = colorFilterAvailable && MTBColorFilterIsEnabled()
        nightShiftEnabled = nightShiftAvailable && MTBNightShiftIsEnabled()
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
