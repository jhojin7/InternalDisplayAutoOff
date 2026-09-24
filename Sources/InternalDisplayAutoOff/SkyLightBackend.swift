import CoreGraphics
import Darwin
import Foundation

final class SkyLightBackend {
    typealias ConfigureDisplayEnabled = @convention(c) (
        CGDisplayConfigRef?, CGDirectDisplayID, Bool
    ) -> CGError

    enum BackendError: LocalizedError {
        case frameworkUnavailable
        case symbolUnavailable
        case beginFailed(CGError)
        case configureFailed(CGError)
        case completeFailed(CGError)

        var errorDescription: String? {
            switch self {
            case .frameworkUnavailable: "SkyLight.framework could not be loaded"
            case .symbolUnavailable: "SLSConfigureDisplayEnabled is unavailable on this macOS version"
            case .beginFailed(let error): "Could not begin display configuration (CGError \(error.rawValue))"
            case .configureFailed(let error): "SkyLight rejected the display change (CGError \(error.rawValue))"
            case .completeFailed(let error): "Could not commit display configuration (CGError \(error.rawValue))"
            }
        }
    }

    private let handle: UnsafeMutableRawPointer
    private let configureDisplayEnabled: ConfigureDisplayEnabled

    init() throws {
        guard let handle = dlopen(
            "/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight",
            RTLD_NOW | RTLD_LOCAL
        ) else { throw BackendError.frameworkUnavailable }
        guard let symbol = dlsym(handle, "SLSConfigureDisplayEnabled") else {
            dlclose(handle)
            throw BackendError.symbolUnavailable
        }
        self.handle = handle
        configureDisplayEnabled = unsafeBitCast(symbol, to: ConfigureDisplayEnabled.self)
    }

    deinit { dlclose(handle) }

    func setDisplay(_ displayID: CGDirectDisplayID, enabled: Bool) throws {
        var configuration: CGDisplayConfigRef?
        let begin = CGBeginDisplayConfiguration(&configuration)
        guard begin == .success, let configuration else { throw BackendError.beginFailed(begin) }

        let configured = configureDisplayEnabled(configuration, displayID, enabled)
        guard configured == .success else {
            CGCancelDisplayConfiguration(configuration)
            throw BackendError.configureFailed(configured)
        }

        let completed = CGCompleteDisplayConfiguration(configuration, .forSession)
        guard completed == .success else { throw BackendError.completeFailed(completed) }
    }
}
