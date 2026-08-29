// AppsFlyerShim - force the AppsFlyer SDK's jailbreak verdict to NO.
//
// The AppsFlyer SDK exposes its jailbreak check as class methods on
// AppsFlyerUtils (see AppsFlyerSDK/AppsFlyerFramework issues #90/#93):
//
//   + [AppsFlyerUtils isJailbroken]
//   + [AppsFlyerUtils isJailbrokenWithSkipAdvancedJailbreakValidation:]
//
// The boolean they return feeds the SDK's anti-fraud telemetry
// (calculateV2SanityFlags.../calculateV2Value...) that is sent to AppsFlyer's
// servers and used to gate features. Primitive-level bypasses (Shadow et al.)
// miss the "advanced" pass because it uses self-contained/lower-level checks
// and can even flag the presence of those hooks. Hooking the *verdict* short-
// circuits the whole chain: whatever the internal checks find, the method
// returns NO, and because that value is an input to the telemetry, the server
// payload reports clean too.
//
// Scope this to the one target app via AppsFlyerShim.plist. Keep Shadow on for
// the app's own (non-AppsFlyer) Cydia-path checks and to hide these dylibs from
// _dyld enumeration.

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#ifdef AFD_DEBUG
#define AFDLog(fmt, ...) NSLog(@"[AppsFlyerShim] " fmt, ##__VA_ARGS__)
#define AFD_DEBUG_BUILD 1
#else
#define AFDLog(fmt, ...) do { if (0) NSLog(@"[AppsFlyerShim] " fmt, ##__VA_ARGS__); } while (0)
#define AFD_DEBUG_BUILD 0
#endif

%hook AppsFlyerUtils

+ (BOOL)isJailbroken {
#if AFD_DEBUG
    BOOL orig = %orig;   // runs the real check only in debug, to confirm it tripped
    AFDLog(@"+isJailbroken original=%d, forcing NO", orig);
#endif
    return NO;
}

+ (BOOL)isJailbrokenWithSkipAdvancedJailbreakValidation:(BOOL)skip {
#if AFD_DEBUG
    BOOL orig = %orig;
    AFDLog(@"+isJailbrokenWithSkipAdvancedJailbreakValidation:%d original=%d, forcing NO", skip, orig);
#endif
    return NO;
}

%end

%ctor {
    @autoreleasepool {
        // Confirms the tweak loaded into the target and whether the class is
        // even present (if absent, the SDK version names it differently and the
        // hook silently no-ops -- class-dump to find the real name).
        if (AFD_DEBUG_BUILD) {
            Class cls = objc_getClass("AppsFlyerUtils");
            AFDLog(@"loaded in %@; AppsFlyerUtils=%@",
                   NSProcessInfo.processInfo.processName,
                   cls ? NSStringFromClass(cls) : @"(absent)");
        }
    }
}
