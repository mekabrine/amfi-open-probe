# Read-only iPadOS File Explorer

Simple file browser for iPadOS built with UIKit. Displays the current absolute path, allows manual path entry and folder navigation, and previews UTF-8 text or the first 2 KiB of binary data. Reads are capped at 64 KiB per file.

## Choosing files outside the app

Use **Browse Files: choose folder** to grant access to a folder exposed in Apple's Files picker, including iCloud Drive, On My iPad, or a connected File Provider. The explorer can then browse the selected folder and its children for the duration of the app session. Use **Browse Files: choose file** to open a single document. These operations use security-scoped URLs and coordinated reads.

Typing a path is not a permission grant. This app uses ordinary iPadOS APIs; it **does not inherit another app's access rights** or gain access to other applications' protected containers. Unavailable paths display the relevant access error.

## Build and sign

1. Open [Actions → Build unsigned iPadOS IPA](../../actions/workflows/build.yml).
2. Manually choose **Run workflow** on `main`. This workflow has no automatic push or pull-request triggers.
3. Download the unsigned IPA from the completed run's artifact ZIP.
4. Sign the IPA with your existing Feather signing setup, without injecting tweaks, then install it.

The internal Xcode project name is retained from the original probe. The installed app displays **Read-only Explorer**. The workflow may still use an older IPA artifact label.

No file changes, deletions, or uploads are performed by this app. A successful build has not yet been verified after this update.
