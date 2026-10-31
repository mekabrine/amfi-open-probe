# Kernel Service Probe — AppleAVE2 accessibility test (23E261)

A minimal signed iPadOS application to test whether an ordinary third-party app can **discover and open** the AppleAVE2 IOKit user client on an iPad mini A17 Pro running iPadOS 26.4.2 (23E261). It does not attempt exploitation, fuzzing, kernel-memory modification, selector invocation, or process injection.

## Checks performed

On tapping **Run one-time checks**, the app attempts exactly one `IOServiceGetMatchingService` and (if matched) one `IOServiceOpen(service, mach_task_self(), 0, ...)` against:
- `AppleAVE2Driver` — **new target**
- `IOSurfaceRoot`, `IOMobileFramebuffer`, `AppleMobileFileIntegrity`, `IODTNVRAM` — previously measured controls.

Every successful connection is immediately closed, and every matched service object is released. The app additionally performs **passive discovery only** of `ANEHWDevice`, with no user-client open.

The output distinguishes `NOT_FOUND` from exact IOKit return codes. A missing matching class does **not** prove the embedded driver is unavailable; a successful open does **not** demonstrate an exploit.

## Build and installation

The GitHub Actions workflow is **manual-only** (`workflow_dispatch`). No build has been triggered.

1. Open [Actions → Build unsigned iPadOS IPA](../../actions/workflows/build.yml).
2. Click **Run workflow**, select `main`.
3. Download `KernelServiceProbe-unsigned-ipa` once the workflow passes, and extract `KernelServiceProbe-unsigned.ipa`.
4. Sign and install through Feather with your normal certificate. This app uses the existing Xcode product/bundle ID `org.research.amfiopenprobe`.
5. Launch **Kernel Service Probe** and tap **Run one-time checks**.
6. Tap **Copy results** and share the log for interpretation.

Stop after one run if the device shows abnormal behavior; do not stress-test or send malformed inputs.

## Interpretation

- `AppleAVE2Driver match=NOT_FOUND`: the class was not registered under this exact name, or isn't discoverable to the app.
- `match=FOUND | open=0x00000000`: a default user-client connection was successfully opened and closed; an access prerequisite is met, not an exploit.
- `match=FOUND | open=0x... nonzero`: exact error code constrains access/entitlement hypotheses.
- `ANEHWDevice`: presence-only observation; no open operation is performed.

There is no jailbreak, SpringBoard modification, filesystem sandbox bypass, or privileged code execution in this app.

**Build status:** Source updated in GitHub. Xcode build and iPad test have not yet been run.
