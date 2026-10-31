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

## HID device result and passive follow-up (October 31, 2026)

The first physical-device run on stock iPad mini A17 Pro (iPadOS 26.4.2, 23E261) returned:

```
IOHIDDevice | match=FOUND | concrete=AppleSPUHIDDevice | type=0x00484944 | open=0xe00002e2 (-536870174)
IOHIDEventService | match=FOUND | concrete=AppleARMPMUPowerSensor | open=NOT_ATTEMPTED
IOHIDSystem | match=NOT_FOUND | open=NOT_ATTEMPTED
```

**Interpretation:** The first `IOHIDDevice` provider was a specialized `AppleSPUHIDDevice` instance and returned **NOT PERMITTED**. This proves the tested connection was denied, not that every HID device class rejects that type. Apple's public `IOHIDDevice.cpp` notes that subclasses may override the default HID user-client behavior. The event-service discovery did not include an open attempt.

**New follow-up:** Open **HID Check**, then select **Inventory HID providers** instead of the old connection test. The new action passively enumerates up to 64 registered matches per family (`IOHIDDevice`, `IOHIDEventService`, and `IOHIDSystem`) and summarizes the concrete classes and counts. It never calls `IOServiceOpen`, invokes selectors or generates HID events. Select **Copy results** to share the inventory. Class enumeration does not itself demonstrate exploitability. The existing **Run HID check once** action is retained unchanged.

This is a diagnostic step only; do not infer an exploit from a discovered service.

## HID class access v2 (31 October 2026)

Results from the previous stock 23E261 app installation:

- `IOHIDDevice`: 21 observed services: `AppleSPUHIDDevice` (16), `AppleHIDTransportHIDDevice` (3), `AppleWirelessChargingDevice` (1), `IOHIDUserDevice` (1).
- `IOHIDEventService`: 64 observed at the enumeration cap; at least six concrete classes, **incomplete total**.
- `IOHIDSystem`: zero matching service instances.
- Previous `IOHIDDevice` connection to `AppleSPUHIDDevice` using type `0x00484944` was denied with `0xe00002e2`. This does **not** establish denial for the other three classes.

**New button: `Check other 3 HID classes once`.** It walks up to 64 matching `IOHIDDevice` providers and attempts exactly **one** documented-type `IOServiceOpen` on the first `AppleHIDTransportHIDDevice`, `AppleWirelessChargingDevice`, and `IOHIDUserDevice` encountered. Any successful connection is immediately closed; additional instances of the same class and all `AppleSPUHIDDevice` objects are skipped. The button stays disabled after the check, preventing repeated opens in the same screen instance. The existing original reachability and inventory buttons are unchanged.

**Interpretation:** A successful open only verifies one connection's accessibility to the ordinary signed app, not the vulnerable CVE method, kernel memory access, privileges, a jailbreak, or process injection. A denied result can be class/device-instance-specific. This test invokes no external methods, constructs no HID reports, sends no malformed buffers, and does no kernel stress.

**Build policy:** Workflow remains `workflow_dispatch` only. Do not trigger any build automatically; run it manually if collecting a new on-device result.

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

