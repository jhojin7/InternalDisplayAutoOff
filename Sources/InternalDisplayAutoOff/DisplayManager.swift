import AppKit
import Combine
import CoreGraphics
import Foundation
import ServiceManagement

@MainActor
final class DisplayManager: ObservableObject {
    @Published var autoModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(autoModeEnabled, forKey: "autoModeEnabled")
            evaluate(reason: "Auto mode changed")
        }
    }
    @Published private(set) var status = "Starting…"
    @Published private(set) var detail = "Reading display topology"
    @Published private(set) var externalDisplayCount = 0
    @Published private(set) var internalIsActive = true
    @Published private(set) var backendAvailable = false
    @Published var launchAtLogin: Bool {
        didSet { updateLaunchAtLogin() }
    }

    private var cachedInternalDisplayID: CGDirectDisplayID?
    private let backend: SkyLightBackend?
    private var monitor: DisplayMonitor?
    private var operationInProgress = false

    init() {
        autoModeEnabled = UserDefaults.standard.object(forKey: "autoModeEnabled") as? Bool ?? true
        launchAtLogin = SMAppService.mainApp.status == .enabled
        if UserDefaults.standard.object(forKey: "lastKnownInternalDisplayID") != nil {
            cachedInternalDisplayID = CGDirectDisplayID(
                UserDefaults.standard.integer(forKey: "lastKnownInternalDisplayID")
            )
        }
        do {
            backend = try SkyLightBackend()
            backendAvailable = true
        } catch {
            backend = nil
            detail = error.localizedDescription
        }
        monitor = DisplayMonitor(
            onEvent: { [weak self] event in self?.handleDisplayEvent(event) },
            onChange: { [weak self] in self?.evaluate(reason: "Display configuration changed") }
        )
        evaluate(reason: "App launched")
    }

    private func handleDisplayEvent(_ event: DisplayChangeEvent) {
        guard DisplaySwitchPolicy.shouldRestoreImmediately(
            for: event,
            internalDisplayID: cachedInternalDisplayID,
            internalIsActive: internalIsActive,
            autoModeEnabled: autoModeEnabled
        ), let internalDisplayID = cachedInternalDisplayID else { return }

        setInternalDisplay(
            internalDisplayID,
            enabled: true,
            reason: "External display removal detected"
        )
    }

    func evaluate(reason: String) {
        guard !operationInProgress else { return }
        let topology = DisplayTopology.read(cachedInternalID: cachedInternalDisplayID)
        if let internalID = topology.internalDisplayID {
            cachedInternalDisplayID = internalID
            UserDefaults.standard.set(Int(internalID), forKey: "lastKnownInternalDisplayID")
        }
        externalDisplayCount = topology.usableExternalDisplayIDs.count
        internalIsActive = cachedInternalDisplayID.map(topology.activeDisplayIDs.contains) ?? true

        guard let internalID = cachedInternalDisplayID else {
            status = "Built-in display not found"
            detail = "No built-in panel was reported by CoreGraphics"
            log(reason)
            return
        }
        guard backend != nil else {
            status = "Unsupported on this macOS"
            log(reason)
            return
        }
        guard autoModeEnabled else {
            status = internalIsActive ? "Auto mode paused" : "Built-in display is off"
            detail = "Use Restore Internal Display before disconnecting the external display"
            log(reason)
            return
        }

        if !topology.usableExternalDisplayIDs.isEmpty && internalIsActive {
            setInternalDisplay(internalID, enabled: false, reason: "External display detected")
        } else if topology.usableExternalDisplayIDs.isEmpty && !internalIsActive {
            setInternalDisplay(internalID, enabled: true, reason: "No external display remains")
        } else {
            status = internalIsActive ? "Built-in display active" : "Built-in display disabled"
            detail = topology.usableExternalDisplayIDs.isEmpty
                ? "Waiting for an external display"
                : "Protected by \(topology.usableExternalDisplayIDs.count) usable external display(s)"
            log(reason)
        }
    }

    func restoreInternalDisplay() {
        guard let id = cachedInternalDisplayID ?? DisplayTopology.read().internalDisplayID else {
            status = "Built-in display not found"
            detail = "CoreGraphics did not report a built-in display ID"
            return
        }
        cachedInternalDisplayID = id
        setInternalDisplay(id, enabled: true, reason: "Manual restore")
    }

    func prepareToQuit() {
        guard !internalIsActive else { return }
        restoreInternalDisplay()
    }

    private func setInternalDisplay(_ id: CGDirectDisplayID, enabled: Bool, reason: String) {
        guard let backend else { return }
        if !enabled {
            let fresh = DisplayTopology.read(cachedInternalID: id)
            guard !fresh.usableExternalDisplayIDs.isEmpty else {
                status = "Safety check stopped disable"
                detail = "No usable external display is active"
                return
            }
        }

        operationInProgress = true
        do {
            try backend.setDisplay(id, enabled: enabled)
            operationInProgress = false
            let observed = DisplayTopology.read(cachedInternalID: id)
            internalIsActive = observed.activeDisplayIDs.contains(id)
            externalDisplayCount = observed.usableExternalDisplayIDs.count
            let reachedTarget = internalIsActive == enabled
            status = reachedTarget
                ? (enabled ? "Built-in display restored" : "Built-in display disabled")
                : "Display change was not observed"
            detail = reachedTarget ? reason : "SkyLight returned success, but CoreGraphics reports the previous state"
            log(reason)
        } catch {
            operationInProgress = false
            status = enabled ? "Restore failed" : "Disable failed"
            detail = error.localizedDescription
            log(reason)
        }
    }

    private func updateLaunchAtLogin() {
        do {
            if launchAtLogin { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
        } catch {
            detail = "Launch at login: \(error.localizedDescription)"
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    private func log(_ reason: String) {
        NSLog("[InternalDisplayAutoOff] %@ — %@; status=%@; external=%d; internalActive=%@",
              reason, detail, status, externalDisplayCount, internalIsActive.description)
    }
}
