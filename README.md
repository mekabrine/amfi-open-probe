# IOSurface Inspector — read-only reachability and padding test

iPadOS 26.4.2 (23E261) research app for a normally signed iPadOS app. It now contains **two separate, on-demand tests**:

1. **IOKit service survey**: checks visibility and type-0 opening for seven named classes. Immediately closes successful connections. Does not invoke external methods.
2. **IOSurface selector 13 padding check**: opens IOSurfaceRoot, calls **only selector 13** three times with **no input**, reads its fixed 40-byte output, prints just the five padding bytes at offsets 33, 36–39, and closes the connection. This selector was individually audited from the user's exact kernelcache: handler 0xfffffff009c39cf0 reads internal fields and writes output; no visible state modification.

**This is a targeted diagnostic, not an exploit.** Do not interpret unusual bytes as a confirmed information leak. No arbitrary selectors, payloads, fuzzing, or system configuration changes are involved. Even a read-only kernel method call is an active operation on the research device.

## Why selector 13?

The iPadOS 26.4.2 dispatch descriptor for selector 13 specifies 0 input scalars, 0 input-structure bytes, and a 0x28-byte structure output. Its handler writes offsets 0–32 and 34–35 but does not explicitly write offsets **33 and 36–39** (five bytes total). XNU's method handler does not explicitly clear the in-band structure output at the argument-setup point. However, other IOKit/Mach mechanisms could initialize or sanitize the buffer, so there is **no confirmed vulnerability**.

The three calls prefill the app's output array with 0x00, 0xA5, and 0x5A before calling `IOConnectCallStructMethod`. This makes it easier to see whether the returned padding is deterministic or tracks the caller's marker; it does **not** definitively establish the origin of unexpected bytes.

Only the five candidate padding bytes and return values are displayed. The other 35 bytes of system information are deliberately not included in the diagnostic report.

## Manual GitHub Actions build — nothing automatic

The workflow has **only `workflow_dispatch`**, with no push or pull-request triggers.

1. Open [Actions → Build unsigned iPadOS IPA](../../actions/workflows/build.yml).
2. Manually click **Run workflow** for `main`.
3. Download artifact **`IOSurfacePadCheck-unsigned-ipa`**.
4. Extract the ZIP to obtain **`IOSurfacePadCheck-unsigned.ipa`**.
5. Use your existing Feather certificate to sign the IPA (without tweak injection), then install it.

The Xcode project and executable target retain the original internal name `AMFIOpenProbe` for build compatibility; the home-screen display name is **IOSurface Inspector**. This can replace the earlier probe if signed with the same app identifier.

## On-device procedure

1. Launch **IOSurface Inspector**.
2. Tap **Inspect IOSurface selector 13 (read-only)** — the app will make three identical read-only calls with differing caller-side prefill markers.
3. Tap **Copy complete report** and paste the report into the research conversation.

If the calls fail, their return codes are useful on their own.

## Interpreting the padding check

- If returned padding matches each different marker, the bytes may be untouched or preserved by the call path. This **does not prove** a kernel leak.
- If all bytes are zero, the output path may be sanitizing or zero-initializing the padding.
- If padding contains unexpected nonzero values, we have a **candidate that requires further tracing and confirmation**, not an immediate exploit finding.
- If selector 13 is blocked, we must not infer it is reachable just because the user-client connection succeeds.

No new IPSW, restore, jailbreaking tool, or extra entitlements are required. A failed or crashed build should be reported with its workflow log.
