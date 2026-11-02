## Force research runner — four-step implementation (2026-11-01)

The **Research runner → Force** page now provides five independently selectable, bounded research checks: this app's signing entitlement presence, Mach service name lookup (no message sent), IOKit registry service discovery (no user-client methods), app-owned directory existence, and runtime symbol availability. Each shows its relative risk (low), with explicit acknowledgment. Choose 15 minutes, 1 hour, or 6 hours, and serial or concurrent operation. Methods rotate through fixed cases with a 30-second interval; these checks are not exploit brute-forcing, kernel fuzzing, process injection, or privilege escalation.

The single journal is `Documents/force-research.jsonl` (JSON Lines, one JSON object per line). Records include a session ID, attempt ID, method ID, UTC timestamps with milliseconds, Unix milliseconds, event type, and input/result details. A `before` event is written and synchronized with `fsync` before each check; `after` is written and synchronized upon return. Failure to sync the `before` event halts that worker rather than proceeding unlogged. The Force page includes a journal self-test and an iPad share-sheet export button. Avoid deleting or overwriting the app's Documents folder if preserving history is important.

On reopening Force, the app inspects the journal for unfinished sessions and unmatched operations. A changed estimated boot epoch may support a **possible device reboot**; it cannot prove kernel panic or tell whether the app crashed, was suspended, or was killed. Going to background records the transition and requests the workers stop. Keep the app in the foreground and prevent auto-lock for overnight use; iPadOS does not guarantee background execution or automatic restart after a reboot. All operations should be considered **unverified on hardware** until an actual signed IPA has run.

**Building and checking:** run the existing manual [GitHub Actions IPA workflow](../../actions/workflows/build.yml) on `main`. Download the unsigned IPA only if Xcode succeeds, sign it with Feather, and install it. First verify Force's "Test durable before/after logging" and export the JSONL, then try one selected low-risk check for 15 minutes, then concurrent mode. If compilation fails, use the Actions log before installing. No Xcode compiler or GitHub Actions dispatch tool was available in the development environment, so a passing IPA build is **not yet confirmed**.

---

# iPadOS 26.4.2 Research Tests — iPad mini A17 Pro (23E261)

A manually signed research app for iPad mini A17 Pro on iPadOS 26.4.2 (23E261). The home screen separates the previously verified file-change, HID, FastPath and kernel-service checks into dedicated pages. It does not implement a new jailbreak, arbitrary-process tweak, memory-modification primitive or partial restore.

## Direct exploit research status (2026-10-31)

The previous **Possible Tweaks / Examples** screen was removed because its floating image and tint changes only affected this research app, not other apps or SpringBoard.

The main screen now offers **Exploit Research Status**, summarizing device-verified capabilities and research-only candidates. The status dialog does not execute an exploit.

- **Verified on device:** Erosion / `bad_query` changed another app's writable data; `AOPTouchHIDDriver` FastPath user client type 2 opened. Opening FastPath does not grant kernel memory access.
- **Research-only:** CVE-2026-64740 Game Center sandbox escape, CVE-2026-28995 App Intents sandbox escape, and published SpringBoard / IOSurface corruption advisories. None is implemented as a working tweak exploit in this project.
- **Not supported:** app injection into arbitrary signed processes, modifying installed signed `.app` bundles, or persistent/transient SpringBoard overlay. No partial restore.
- **No new device tests** were added, and the existing HID and file checks remain intact.

The action in `.github/workflows/build.yml` is still manually dispatched. A source commit does not establish that an IPA has compiled or been installed.

## New research test: CVE-2026-84530 AIO kernel-address disclosure

The app now has a seventh independent page: **Research Tests → Kernel information leaks → AIO kqueue CVE-2026-84530**.

**Why this is different:** Apple's advisory and [the original researcher's case study](https://github.com/vschko/CaseStudies/tree/main/CVE-2026-84530) describe an actual kernel-address disclosure fixed in iPadOS 26.7. The previous HID/IOKit pages only established user-client reachability. This new page makes one bounded, read-only attempt to observe the AIO saved-data leak using a FIFO created inside this app's own temporary container. It operates on the calling process's kqueue metadata. It does **not** request arbitrary system-file paths, install code in other apps, patch SpringBoard, perform kernel writes, or trigger a race.

**Pass condition:** a metadata record for the AIO filter contains a kernel-looking address in its saved-data field, accompanied by an ordinary event-data field. **Fail/unsupported condition:** no qualifying record is returned or the installed app's sandbox restricts the process-information interface; the log identifies the unsupported step. Values must not be described as arbitrary kernel memory access. One action per page visit, no automatic execution or retry.

**Limit:** This is a *research build to test a newly published vulnerability primitive*, not a jailbreak or a tweak injector. Exact-build success on iPad16,1 / 23E261 has **not been established**. A detected kernel pointer might help later kernel exploit research but cannot by itself recolor an unrelated app or modify SpringBoard. No partial restore.

**Build:** The current GitHub Actions workflow is still manual-only. Source underwent static structural checks, but Xcode compilation and on-device execution have not been performed in this environment. Only install and run if you accept normal research-app risks; there is no known panic-only trigger in this test. Do not run the existing crash-focused GPU/AIO UAF PoCs as substitutes.

## Research Tests navigation

The app opens to **Research Tests**, a list of independent pages. Existing operations are unchanged:

| Section | Page |
| --- | --- |
| App data | Erosion file-change validation |
| HID / IOHIDFamily | HID service reachability |
| HID / IOHIDFamily | HID provider inventory |
| HID / IOHIDFamily | HID manager class opens |
| HID / IOHIDFamily | AOPTouch FastPath type 2 |
| Kernel services | AppleAVE2 and service opens |

Each page exposes only its own run action and results. Nothing runs on launch. The earlier app-only visual examples and status popup are gone. Historical sections below may refer to the former combined HID screen.

The GitHub Actions build remains manual-only. **This navigation update alone is not a reason to build an IPA; no new exploit capability was added.**

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

## Confirmed iPadOS 26.4.2 device results — 31 October 2026

**HID Class Access v2:** one representative of `AppleWirelessChargingDevice`, `AppleHIDTransportHIDDevice`, and `IOHIDUserDevice` each denied the documented HID-manager connection `0x00484944` with `0xe00002e2`. The already-tested `AppleSPUHIDDevice` was correctly skipped. This constrains tested representative connections, not all possible instances or user-client types.

**HID FastPath Open-Only v1:** `IOHIDEventService` enumeration succeeded; the first `AOPTouchHIDDriver` matched after visiting **63** providers. `IOServiceOpen(service, mach_task_self(), 2, ...)` returned **`0x00000000`** and the connection was immediately closed. This **confirms normal signed app accessibility of that specific FastPath user-client connection on 23E261**. The test invoked no external method, race, or gate input; it does **not** confirm CVE-2026-28992 exploitability or kernel read/write.

The public FastPath PoCs aim to kernel-panic affected devices and are not installed in this app. The next research work is **offline** method table, entitlement, locking, and patched-versus-vulnerable verification. No new IPA build is necessary to repeat this access check.

Full evidence is saved in [private 23E261 research handoff](https://github.com/mekabrine/test/blob/main/ipad26-23E261/HID_FASTPATH_DEVICE_RESULTS_2026-10-31.md).

## Additional FastPath access lead: CVE-2026-28992

Apple's [iOS 26.5 security bulletin](https://support.apple.com/en-us/127110) confirms IOHIDFamily **CVE-2026-28992**, a memory corruption issue addressed with improved locking. The original 23E261 kernelcache contains the class name `IOHIDEventServiceFastPathUserClient` and the FastPath property names; this is **not** an independent identification of the precise vulnerable function.

A [public research repo](https://github.com/0xjohnnydev/CVE-2026-28992-IOHIDFamily-FastPathUserClient-Race-Conditions) describes `IOServiceOpen(..., 2, ...)` for `IOHIDEventService` providers, but its demonstrations aim to **panic/reboot the device**, not supply controlled kernel reads, writes, or a jailbreak. Do **not** run or adapt the PoC's repeated open/close operations, selectors, specially crafted properties, or concurrent race loops on the stock iPad.

The new app button **Check FastPath type 2 once (no selectors)** makes at most **one standard user-client connection** on the first matched `AOPTouchHIDDriver` (which was in the supplied inventory), closes any returned connection immediately, and logs only the status. It is separate from the three-class HID check, and stays disabled after one use per screen instance. A successful open is a reachability observation only. The app has no vulnerability trigger.

No build was automatically run. Existing manual workflow and Feather signing remain unchanged.

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

