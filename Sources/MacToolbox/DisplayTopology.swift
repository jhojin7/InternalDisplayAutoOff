import CoreGraphics

struct DisplayTopology: Equatable {
    let activeDisplayIDs: [CGDirectDisplayID]
    let internalDisplayID: CGDirectDisplayID?
    let usableExternalDisplayIDs: [CGDirectDisplayID]

    static func read(cachedInternalID: CGDirectDisplayID? = nil) -> DisplayTopology {
        let active = displayList(using: CGGetActiveDisplayList)
        let online = displayList(using: CGGetOnlineDisplayList)
        let allKnown = Array(Set(active + online))
        let detectedInternal = allKnown.first(where: { CGDisplayIsBuiltin($0) != 0 })
        let internalID = detectedInternal ?? cachedInternalID

        let external = active.filter { id in
            id != internalID &&
                CGDisplayIsBuiltin(id) == 0 &&
                CGDisplayIsOnline(id) != 0 &&
                CGDisplayIsActive(id) != 0 &&
                CGDisplayIsInMirrorSet(id) == 0 &&
                CGDisplayPixelsWide(id) > 0 &&
                CGDisplayPixelsHigh(id) > 0
        }

        return DisplayTopology(
            activeDisplayIDs: active,
            internalDisplayID: internalID,
            usableExternalDisplayIDs: external
        )
    }

    private static func displayList(
        using function: (UInt32, UnsafeMutablePointer<CGDirectDisplayID>?, UnsafeMutablePointer<UInt32>?) -> CGError
    ) -> [CGDirectDisplayID] {
        var count: UInt32 = 0
        guard function(0, nil, &count) == .success, count > 0 else { return [] }
        var displays = Array(repeating: CGDirectDisplayID(0), count: Int(count))
        var actual = count
        guard function(count, &displays, &actual) == .success else { return [] }
        return Array(displays.prefix(Int(actual)))
    }
}
