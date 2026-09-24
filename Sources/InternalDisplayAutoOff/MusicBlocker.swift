import AppKit
import Combine
import Foundation

@MainActor
final class MusicBlocker: ObservableObject {
    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "musicBlockingEnabled")
            if isEnabled {
                blockRunningMusic()
            } else {
                status = "Music blocking paused"
            }
        }
    }

    @Published private(set) var status: String

    private var launchObserver: NSObjectProtocol?
    private var guardTimer: Timer?
    private var forceTerminationTasks: [pid_t: Task<Void, Never>] = [:]

    init() {
        let enabled = UserDefaults.standard.object(forKey: "musicBlockingEnabled") as? Bool ?? true
        isEnabled = enabled
        status = enabled ? "Apple Music blocked" : "Music blocking paused"

        launchObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
                    as? NSRunningApplication else { return }
            MainActor.assumeIsolated {
                self?.blockIfNeeded(application)
            }
        }

        guardTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.blockRunningMusic()
            }
        }
        blockRunningMusic()
    }

    func blockRunningMusic() {
        guard isEnabled else { return }
        NSRunningApplication.runningApplications(
            withBundleIdentifier: MusicBlockPolicy.musicBundleIdentifier
        ).forEach(blockIfNeeded)
    }

    private func blockIfNeeded(_ application: NSRunningApplication) {
        guard isEnabled,
              MusicBlockPolicy.shouldTerminate(
                bundleIdentifier: application.bundleIdentifier,
                bundlePath: application.bundleURL?.path
              ) else { return }

        let pid = application.processIdentifier
        application.terminate()
        status = "Blocked Apple Music"
        NSLog("[MacToolbox] Terminated Apple Music (pid=%d)", pid)

        forceTerminationTasks[pid]?.cancel()
        forceTerminationTasks[pid] = Task { [weak self, weak application] in
            try? await Task.sleep(for: .milliseconds(750))
            guard !Task.isCancelled, let application, !application.isTerminated else {
                self?.forceTerminationTasks[pid] = nil
                return
            }
            application.forceTerminate()
            self?.forceTerminationTasks[pid] = nil
            NSLog("[MacToolbox] Force-terminated Apple Music (pid=%d)", pid)
        }
    }
}
