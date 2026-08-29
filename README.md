# AppsFlyerShim

A tiny iOS tweak that neutralizes the **AppsFlyer SDK's** built-in jailbreak and VPN
detection by forcing its verdict methods to return `NO`.

Many apps don't roll their own anti-tamper — they lean on the AppsFlyer attribution SDK,
which ships jailbreak and VPN checks and folds the results into the anti-fraud telemetry
it sends home (`calculateV2SanityFlags…` / `calculateV2Value…`). For those apps, flipping
AppsFlyer's verdict is enough to stop the feature-gating that follows a positive result.

It hooks three class methods on `AppsFlyerUtils`:

| Method | Meaning |
|---|---|
| `+ isJailbrokenWithSkipAdvancedJailbreakValidation:` | jailbreak verdict (basic + "advanced" pass) |
| `+ isJailbroken` | jailbreak verdict |
| `+ isVPNConnected` | the SDK's own VPN detection (its `getifaddrs` / `nw_path` / proxy machinery) |

All three are forced to `NO`. Because these values are *inputs* to the telemetry AppsFlyer
computes and uploads, forcing them clean also makes the server-side payload report clean —
a server verdict can't contradict a flag the SDK itself reported as false.

## Why hook the verdict instead of the primitives

Primitive-level bypasses (Shadow and friends) hook `stat`/`fopen`/`access`, `_dyld` image
enumeration, `fork`, etc. AppsFlyer's *advanced* jailbreak pass uses self-contained,
lower-level checks and can even flag the presence of those hooks — so a maxed-out Shadow
config still trips it. Hooking the **verdict** short-circuits the whole internal chain:
whatever the checks find, the method returns `NO`. Likewise for VPN — AppsFlyer's
`+isVPNConnected` collapses its `getifaddrs`/`NWPath`/`CFNetworkCopySystemProxySettings`
logic into a single boolean, so one hook defeats it with no interface-list surgery.

## Scope

Ships with a **`Classes` filter** on `AppsFlyerUtils`
([confirmed valid in ElleKit's `injector.c`](https://github.com/tealbathingsuit/ellekit/blob/main/injector/injector.c)):
the dylib loads into **every process that contains the AppsFlyer SDK, and nothing else** —
no daemons, no non-AppsFlyer apps. Edit `AppsFlyerShim.plist` to a `Bundles` filter if
you want it scoped to a single app instead.

## What this does NOT do

This defeats detection **only for apps that trust AppsFlyer's state.** An app that runs its
own jailbreak/VPN detection alongside (or ignores AppsFlyer's result and re-checks) will
still detect the jailbreak — AppsFlyer's flags may be dead code or just one factor among
several in such apps. This tweak is deliberately small and single-purpose: it is not a
general jailbreak-detection bypass. Pair it with a bypass like
[Shadow](https://github.com/jjolano/shadow) for the app's own checks; keep Shadow on
regardless, both for non-AppsFlyer path checks and to hide this dylib from `_dyld`
enumeration.

## Building

roothide Theos (the `roothide` package scheme + `arm64e`), plus `dpkg` and `ldid` on the
host. See the sibling GeoShim project's README for the full toolchain notes.

```bash
export THEOS=$HOME/theos
export PATH=/usr/local/bin:$PATH

make package DEBUG_LOG=1     # 1 Hz-ish logging on each check; use for bring-up
make package FINALPACKAGE=1  # silent release
```

The `.deb` lands in `packages/` as `iphoneos-arm64e`.

## Installing & testing

Install through Sileo/Zebra/`apt` (roothide's package manager, which creates the `.jbroot`
symlinks) — not a bare `dpkg -i`.

With the **debug** build, `oslog | grep AppsFlyerShim` reports what bound in each app:

```
loaded in <app>; AppsFlyerUtils=AppsFlyerUtils isJailbroken=0 jbAdv=1 vpn=1
+isJailbrokenWithSkipAdvancedJailbreakValidation:0 original=1, forcing NO
+isVPNConnected original=1, forcing NO
```

`original=1` proves the check was tripping and the tweak flipped it. If features unblock,
the app trusted AppsFlyer. If they don't, the app has its own detection and needs more than
this tweak.

## License

AGPLv3. See [LICENSE](LICENSE).
