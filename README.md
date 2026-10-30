# Floating Graphic — iPadOS Picture in Picture proof

This repository now builds an iPadOS app that displays an **original bouncing cyan-and-white graphic over other apps**, using Apple's supported Picture in Picture (PiP) system. It does **not** inject code into another process, circumvent the sandbox, or modify SpringBoard. The result is a real cross-app visual overlay controlled by iPadOS.

The app includes the previous read-only file browser as a secondary screen.

## What it does

- On first launch, generates a 4-second, 640×360 H.264 video of a bouncing graphic on the device.
- Previews the looping graphic in the app.
- Offers **Start floating picture**. When iPadOS reports PiP as possible, tapping it requests an OS-managed floating window.
- The PiP window can remain visible while you use the Home Screen, Safari, or other apps. You can move and resize it using normal iPadOS PiP controls.
- The file browser remains available via **Open read-only file browser**.

The animation is created using `AVAssetWriter`, `CoreGraphics`, `AVPlayerLooper`, and `AVPictureInPictureController`. No download is required to create the animation.

## Install — manual workflow

**No workflow runs automatically.** The workflow has only the `workflow_dispatch` trigger.

1. Open [Actions → Build unsigned iPadOS IPA](../../actions/workflows/build.yml).
2. Select **Run workflow** on `main`.
3. When it succeeds, download the artifact **`FloatingGraphic-unsigned-ipa`**.
4. Extract the ZIP and obtain **`FloatingGraphic-unsigned.ipa`**.
5. Sign the IPA with your Feather certificate and install it, without injecting tweaks.
6. Launch **Floating Graphic**. The first launch generates the looping animation on-device.
7. After the preview starts, tap **Start floating picture**, then switch to another app.

If PiP is unavailable, the app shows a message instead of attempting unsupported operations. Your iPad must have Picture in Picture enabled in system settings, and another PiP session must not be occupying the feature.

## Scope and limitations

A floating PiP window is **not arbitrary process code execution**, code injection, root access, or a jailbreak. The compositor manages the overlay; the app's code still executes in its own sandbox. This is a working implementation to test a visible, cross-app effect without needing to exploit the operating system.

The internal Xcode target/bundle ID remains `AMFIOpenProbe` for compatibility with the earlier project. This can replace that installation when signed with the same identifier.

The project has been committed to GitHub but **no CI build or on-device run has been performed as part of this update**. Send the error log if the manual build fails.
