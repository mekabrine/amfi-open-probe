# AMFI Open Probe

A minimal iPadOS app that checks whether an ordinarily signed app can locate the `AppleMobileFileIntegrity` IOKit service and open a type-0 user-client connection.

**Safety:** This app calls only `IOServiceMatching`, `IOServiceGetMatchingService`, `IOServiceOpen`, `IOServiceClose` and `IOObjectRelease`. It never calls AMFI external methods or alters security state.

## Build

1. Open **Actions → Build unsigned iPadOS IPA → Run workflow** (or push to `main`).
2. Download the `AMFIOpenProbe-unsigned-ipa` workflow artifact.
3. Unzip it to obtain `AMFIOpenProbe-unsigned.ipa`.
4. Sign with your own normal iPadOS app signing process, then install on your device.
5. Run the app and copy the text it displays.

The GitHub Actions artifact is **unsigned** and cannot be installed directly. No signing certificates or secrets are needed for the CI build.

## Interpreting results

- `dlopen failed`: the framework isn't available to the app.
- `AMFI service not found`: the service was not visible to the app.
- `IOServiceOpen(type=0)`: the return code is the primary observation.
- `Connection opened; closing immediately`: a type-0 connection was permitted, **not** proof of an AMFI bypass or permission to invoke privileged methods.

The iPadOS private IOKit interface is undocumented for third-party apps. No jailbreak or vulnerability is claimed. The build is configured for Xcode on a macOS GitHub Actions runner; it has not yet been validated by a successful workflow run.

## Scope

Target research device: iPad mini A17 Pro, iPadOS 26.4.2. The test does not require any additional firmware downloads, restores, or privileged operations.
