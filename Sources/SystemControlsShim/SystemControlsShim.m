#import "SystemControlsShim.h"

#import <Foundation/Foundation.h>
#import <dlfcn.h>

typedef bool (*DisplayFilterGetEnabledFunction)(int);
typedef void (*DisplayFilterSetEnabledFunction)(int, bool);
typedef void (*UniversalAccessStartFunction)(int);

static const int MTBSystemDisplayFilter = 1;

static void *MTBMediaAccessibilityHandle(void) {
    static void *handle;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        handle = dlopen(
            "/System/Library/Frameworks/MediaAccessibility.framework/MediaAccessibility",
            RTLD_LAZY | RTLD_LOCAL
        );
    });
    return handle;
}

static DisplayFilterGetEnabledFunction MTBDisplayFilterGetEnabled(void) {
    return (DisplayFilterGetEnabledFunction)dlsym(
        MTBMediaAccessibilityHandle(),
        "MADisplayFilterPrefGetCategoryEnabled"
    );
}

static DisplayFilterSetEnabledFunction MTBDisplayFilterSetEnabled(void) {
    return (DisplayFilterSetEnabledFunction)dlsym(
        MTBMediaAccessibilityHandle(),
        "MADisplayFilterPrefSetCategoryEnabled"
    );
}

static void MTBWakeUniversalAccessDaemon(void) {
    static UniversalAccessStartFunction startFunction;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        void *handle = dlopen("/usr/lib/libUniversalAccess.dylib", RTLD_LAZY | RTLD_LOCAL);
        startFunction = (UniversalAccessStartFunction)dlsym(handle, "_UniversalAccessDStart");
    });
    if (startFunction) {
        startFunction(8);
    }
}

bool MTBColorFilterIsAvailable(void) {
    return MTBDisplayFilterGetEnabled() && MTBDisplayFilterSetEnabled();
}

bool MTBColorFilterIsEnabled(void) {
    DisplayFilterGetEnabledFunction getEnabled = MTBDisplayFilterGetEnabled();
    return getEnabled ? getEnabled(MTBSystemDisplayFilter) : false;
}

bool MTBSetColorFilterEnabled(bool enabled) {
    DisplayFilterSetEnabledFunction setEnabled = MTBDisplayFilterSetEnabled();
    if (!setEnabled) {
        return false;
    }
    setEnabled(MTBSystemDisplayFilter, enabled);
    MTBWakeUniversalAccessDaemon();
    return true;
}

@interface MTBBlueLightClient : NSObject
- (BOOL)getBlueLightStatus:(void *)status;
- (BOOL)setEnabled:(BOOL)enabled;
- (void)setStatusNotificationBlock:(void (^)(void))block;
- (void)enableNotifications;
@end

static NSString * const MTBNightShiftStatusDidChange = @"MTBNightShiftStatusDidChange";

static MTBBlueLightClient *MTBNightShiftClient(void) {
    static MTBBlueLightClient *client;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSBundle *bundle = [NSBundle bundleWithPath:
            @"/System/Library/PrivateFrameworks/CoreBrightness.framework"];
        if (![bundle load]) {
            return;
        }
        Class clientClass = NSClassFromString(@"CBBlueLightClient");
        if (clientClass) {
            client = [[clientClass alloc] init];
        }
    });
    return client;
}

bool MTBNightShiftIsAvailable(void) {
    MTBBlueLightClient *client = MTBNightShiftClient();
    return client &&
        [client respondsToSelector:@selector(getBlueLightStatus:)] &&
        [client respondsToSelector:@selector(setEnabled:)];
}

bool MTBNightShiftIsActive(void) {
    MTBBlueLightClient *client = MTBNightShiftClient();
    // CoreBrightness's private status structure has changed between macOS
    // releases. Its first two fields remain the active and enabled BOOLs.
    // Read the active field so a Sunset to Sunrise schedule is reflected by
    // the menu instead of appearing enabled throughout the daytime. Reserve
    // ample aligned storage so additions cannot overwrite our stack.
    union {
        max_align_t alignment;
        unsigned char bytes[128];
    } status = {0};
    return client && [client getBlueLightStatus:&status] && status.bytes[0] != 0;
}

bool MTBSetNightShiftEnabled(bool enabled) {
    MTBBlueLightClient *client = MTBNightShiftClient();
    return client && [client setEnabled:enabled];
}

bool MTBStartNightShiftStatusNotifications(void) {
    MTBBlueLightClient *client = MTBNightShiftClient();
    if (!client || ![client respondsToSelector:@selector(setStatusNotificationBlock:)]) {
        return false;
    }

    [client setStatusNotificationBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter]
                postNotificationName:MTBNightShiftStatusDidChange
                object:nil];
        });
    }];
    if ([client respondsToSelector:@selector(enableNotifications)]) {
        [client enableNotifications];
    }
    return true;
}
