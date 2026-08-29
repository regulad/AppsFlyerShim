// AppsFlyerDefeat - force the AppsFlyer SDK's jailbreak and VPN verdicts to NO.
//
// The AppsFlyer SDK exposes these checks as class methods on AppsFlyerUtils.
// Confirmed by class-dump of the SDK in the target binary:
//
//   + isJailbrokenWithSkipAdvancedJailbreakValidation:(BOOL)   -> jailbreak
//   + isVPNConnected                                           -> VPN
//   + isJailbroken                                             -> jailbreak (see note)
//
// NOTE on +isJailbroken: it was NOT present in THIS app's class-dump - almost
// certainly dead-code-stripped from this build, since it exists in the SDK
// generally. It is kept hooked anyway: the Classes filter loads this dylib into
// every app containing AppsFlyerUtils, and %hook on a method a given app does
// not implement simply never binds (harmless). Keeping it covers apps that DO
// ship the method without a second build.
//
// The booleans they return feed the SDK's anti-fraud telemetry
// (calculateV2SanityFlags.../calculateV2Value...) sent to AppsFlyer's servers
// and used to gate features. Primitive-level bypasses (Shadow et al.) miss the
// "advanced" pass because it uses self-contained/lower-level checks and can even
// flag the presence of those hooks. Hooking the *verdict* short-circuits the
// whole chain: whatever the internal checks find, the method returns NO, and
// because that value is an input to the telemetry, the server payload reports
// clean too.
//
// This also means the SDK's VPN detection (its own getifaddrs / nw_path /
// CFNetworkCopySystemProxySettings machinery) collapses to a single hookable
// verdict - no interface-list surgery needed for AppsFlyer's check.
//
// Scoped via AppsFlyerDefeat.plist to any process containing AppsFlyerUtils
// (the Classes filter). Keep Shadow on for the app's own non-AppsFlyer
// Cydia-path checks and to hide these dylibs from _dyld enumeration.

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#ifdef AFD_DEBUG
#define AFDLog(fmt, ...) NSLog(@"[AppsFlyerDefeat] " fmt, ##__VA_ARGS__)
#define AFD_DEBUG_BUILD 1
#else
#define AFDLog(fmt, ...) do { if (0) NSLog(@"[AppsFlyerDefeat] " fmt, ##__VA_ARGS__); } while (0)
#define AFD_DEBUG_BUILD 0
#endif

%hook AppsFlyerUtils

// Present in the SDK generally; may be dead-stripped from a given app, in which
// case this hook harmlessly never binds. See the note in the file header.
+ (BOOL)isJailbroken {
#if AFD_DEBUG
    BOOL orig = %orig;
    AFDLog(@"+isJailbroken original=%d, forcing NO", orig);
#endif
    return NO;
}

+ (BOOL)isJailbrokenWithSkipAdvancedJailbreakValidation:(BOOL)skip {
#if AFD_DEBUG
    BOOL orig = %orig;   // run the real check in debug only, to confirm it tripped
    AFDLog(@"+isJailbrokenWithSkipAdvancedJailbreakValidation:%d original=%d, forcing NO", skip, orig);
#endif
    return NO;
}

+ (BOOL)isVPNConnected {
#if AFD_DEBUG
    BOOL orig = %orig;
    AFDLog(@"+isVPNConnected original=%d, forcing NO", orig);
#endif
    return NO;
}

%end

%ctor {
    @autoreleasepool {
        // Confirms the tweak loaded into the target and that the class is present.
        // Also sanity-checks that the two methods actually exist on this SDK
        // version; a NO here means the SDK renamed them and the hook no-ops.
        if (AFD_DEBUG_BUILD) {
            Class cls = objc_getClass("AppsFlyerUtils");
            BOOL hasJB = cls && [cls respondsToSelector:@selector(isJailbroken)];
            BOOL hasJBAdv = cls && [cls respondsToSelector:
                @selector(isJailbrokenWithSkipAdvancedJailbreakValidation:)];
            BOOL hasVPN = cls && [cls respondsToSelector:@selector(isVPNConnected)];
            AFDLog(@"loaded in %@; AppsFlyerUtils=%@ isJailbroken=%d jbAdv=%d vpn=%d",
                   NSProcessInfo.processInfo.processName,
                   cls ? NSStringFromClass(cls) : @"(absent)", hasJB, hasJBAdv, hasVPN);
        }
    }
}
