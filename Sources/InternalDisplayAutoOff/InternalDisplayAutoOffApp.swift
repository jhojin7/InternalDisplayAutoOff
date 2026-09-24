import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    weak var manager: DisplayManager?

    func applicationWillTerminate(_ notification: Notification) {
        MainActor.assumeIsolated { manager?.prepareToQuit() }
    }
}

@main
struct InternalDisplayAutoOffApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var manager: DisplayManager
    @StateObject private var musicBlocker: MusicBlocker

    init() {
        let manager = DisplayManager()
        _manager = StateObject(wrappedValue: manager)
        _musicBlocker = StateObject(wrappedValue: MusicBlocker())
    }

    var body: some Scene {
        MenuBarExtra {
            Text("Displays").font(.headline)
            VStack(alignment: .leading, spacing: 3) {
                Text(manager.status).font(.headline)
                Text(manager.detail).font(.caption).foregroundStyle(.secondary)
                Text("Usable external displays: \(manager.externalDisplayCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)

            Divider()
            Toggle("Auto-disable Built-in Display", isOn: $manager.autoModeEnabled)
            Button("Restore Internal Display") { manager.restoreInternalDisplay() }

            Divider()
            Text("App Blocking").font(.headline)
            Toggle("Block Apple Music", isOn: $musicBlocker.isEnabled)
            Text(musicBlocker.status)
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()
            Toggle("Launch at Login", isOn: $manager.launchAtLogin)
            Divider()
            Button("Quit") {
                manager.prepareToQuit()
                NSApplication.shared.terminate(nil)
            }
        } label: {
            Image(systemName: "wrench.and.screwdriver")
                .accessibilityLabel("Mac Toolbox")
                .task { appDelegate.manager = manager }
        }
        .menuBarExtraStyle(.menu)
    }
}
