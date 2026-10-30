# IOKit Reachability Probe (iPadOS)

A narrowly scoped diagnostic app for iPadOS 26.4.2 research. It checks whether a normally signed app can **see and open type-0 IOKit user-client connections** for seven named service classes.

This replaces the earlier single-service AMFI probe and remains deliberately non-exploitative. It **never calls IOConnectCallMethod / externalMethod**, attempts no privilege changes, and writes no system configuration.

## Fixed test set

- AppleMobileFileIntegrity
- IOSurfaceRoot
- IOHIDSystem
- IOMobileFramebuffer
- IOAudioEngine
- IODTNVRAM
- IOUSBHostDevice

A service may be absent, visible but closed to third-party apps, or connectible. Those states are different, and a successful connection does not establish a vulnerability.

## Build — MANUAL ONLY

**Nothing builds automatically from the current workflow.** It has only the `workflow_dispatch` trigger; no push or pull-request triggers.

1. Open [Actions → Build unsigned iPadOS IPA](../../actions/workflows/build.yml).
2. Click **Run workflow** and select **main**.
3. Download the artifact `IOKitReachabilityProbe-unsigned-ipa`.
4. Unzip it to obtain `IOKitReachabilityProbe-unsigned.ipa`.
5. Sign it using your existing Feather certificate, without injected tweaks, and install it.

The artifact is unsigned; GitHub does not require your certificate, provisioning profile, or Apple credentials.

## On the iPad

1. Open the app, **tap Run read-only connection checks**.
2. It performs one exact-class service lookup and at most one type-0 open attempt for each class, closing any successful connection immediately.
3. Tap **Copy complete report** and paste the result into the research conversation.

The app does not scan arbitrary service classes, brute-force user-client types, or invoke external methods. While these are minimal tests, opening a connection is still an active OS operation. Test on your research device.

## Limitations

- Runs are on demand only, not at app launch.
- A failed `IOServiceOpen` can reflect sandbox, entitlement, service-type, or other policy restrictions.
- The build is intended for GitHub Actions macOS/Xcode and may need adaptation if the installed Xcode SDK changes. Report any build failures rather than assuming an IPA exists.
- The target app and bundle ID are retained as `AMFIOpenProbe` for compatibility with the existing Xcode project; the generated IPA artifact is named IOKitReachabilityProbe.
- No new firmware or jailbreak is required.
