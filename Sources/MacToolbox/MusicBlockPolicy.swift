import Foundation

enum MusicBlockPolicy {
    static let musicBundleIdentifier = "com.apple.Music"
    static let systemMusicPath = "/System/Applications/Music.app"

    static func shouldTerminate(bundleIdentifier: String?, bundlePath: String?) -> Bool {
        bundleIdentifier == musicBundleIdentifier && bundlePath == systemMusicPath
    }
}
