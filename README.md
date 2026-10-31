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

## Targeted IOHIDFamily reachability test (new)

**Why this test:** Apple's October 26, 2026 advisory reports IOHIDFamily CVE-2026-112515, an out-of-bounds read that could expose kernel memory. We **do not** know the affected user-client or vulnerable method. The original 23E261 kernelcache contains the IOHIDFamily extension, and Apple's public `IOHIDDevice` implementation documents a dedicated HID manager connection type, `0x00484944` (not the default `0`). Apple's public `IOHIDLibUserClient` source distinguishes ordinary from privileged clients, whereas `IOHIDEventServiceUserClient` requires a private entitlement.

**Exactly what the new screen does:** Tap **HID Check** (top left) then **Run HID check once**. It performs a single `IOServiceGetMatchingService` on `IOHIDDevice`, `IOHIDEventService`, and `IOHIDSystem`, and logs each matched concrete class. For **IOHIDDevice only**, it attempts **one** `IOServiceOpen(..., 0x00484944, ...)` using the official HID manager connection type, logs the return code, and immediately closes any returned connection. The other two classes are **discovery only**. It never invokes a selector, sends a HID report, registers a callback, uses shared memory, or tries a race.

**Interpretation:** `IOHIDDevice match=FOUND | open=0x00000000` establishes only that a normal signed app can create a particular HID connection. It is **not** a kernel read or proof of CVE-2026-112515. A denial constrains reachability; `NOT_FOUND` is inconclusive about other IOKit provider classes. No claim of jailbreak or process injection is made.

Original sources:
- [Apple IOHIDFamily: IOHIDLibUserClient.h](https://github.com/apple-oss-distributions/IOHIDFamily/blob/main/IOHIDFamily/IOHIDLibUserClient.h)
- [Apple IOHIDFamily: IOHIDLibUserClient.cpp](https://github.com/apple-oss-distributions/IOHIDFamily/blob/main/IOHIDFamily/IOHIDLibUserClient.cpp)
- [Apple security advisory: iPadOS 26.7.2](https://support.apple.com/en-us/149227)

**Build:** The existing manual-only GitHub Actions workflow, artifact name and Feather signing steps are unchanged. To collect the result, install the updated unsigned IPA after signing it as usual, tap **HID Check**, tap **Run HID check once**, then **Copy results**. Stop if anything unexpected happens. No kernel-misuse experiment is part of the app.

## Reversible Erosion file-modification experiment

The app now has a **File Test** button in the top right. It opens a separate screen without re-running any kernel probes.

1. Open **File Test**. It creates `Documents/erosion-color-test.txt` with `BLUE` if the file does not exist. The screen shows the exact, UUID-specific absolute path.
2. Tap **Copy file path**. In Erosion, navigate to **File Operations**, target that exact path using its parent directory and file name, and choose **Grant Access**. A prior cross-container read does **not** establish write access.
3. Create a small plain-text file named anything containing just `GREEN` or `RED` followed by a newline. In Erosion's File Operations screen choose **Import File**, then **Overwrite File**. The target should be only the copied `erosion-color-test.txt`.
4. Return to the service probe, tap **Reload file**. The displayed color and value should update if Erosion's cross-container write worked.

This is a controlled and reversible write to a file belonging to **the user's own research app**. No OS or third-party files should be changed. To reset, overwrite the file with `BLUE`. Do not delete or modify unrelated files. Be aware that iPadOS may assign a different data-container UUID after uninstall/reinstall; always copy the current full path.

**Pass criterion:** Before external modification, the app displays `BLUE`. After a successful Erosion overwrite, it displays `GREEN` or `RED` **without rebuilding/repackaging the application**. This demonstrates modification of another app's data, not process injection or kernel access.

**Failure criterion:** Erosion cannot obtain write permission, fails to overwrite, or the app still reads `BLUE`. Record the Erosion error and the file-test display before drawing conclusions.

