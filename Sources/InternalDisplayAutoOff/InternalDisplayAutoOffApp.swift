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

    init() {
        let manager = DisplayManager()
        _manager = StateObject(wrappedValue: manager)
    }

    var body: some Scene {
        MenuBarExtra {
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
            Toggle("Launch at Login", isOn: $manager.launchAtLogin)
            Divider()
            Button("Quit") {
                manager.prepareToQuit()
                NSApplication.shared.terminate(nil)
            }
        } label: {
            Image(systemName: "display")
                .accessibilityLabel("Internal Display Auto Off")
                .task { appDelegate.manager = manager }
        }
        .menuBarExtraStyle(.menu)
    }
}
