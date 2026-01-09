# Overview

Comic Optimizer processes comic-folder trees and converts each comic folder into a single archive (.cbz/.cbr/.zip) while optionally running an external image optimizer (pingo). It is designed for batch work and reports progress and optimizer output to the user.

# Per-folder pipeline (what happens, in order)

- Clean non-image files: remove any files that are not recognized image types (PNG, JPEG, WebP, APNG). The intent is to leave only pages before further processing.
- Normalize filenames: sort image files in natural reading order and rename them to a simple sequential scheme (1, 2, 3...) using zero padding (e.g., 001.jpg). This ensures predictable ordering inside the final archive.
- Optionally optimize images: if the user chooses, run the configured pingo command against the folder to convert/compress images (presets supply the pingo arguments). Capture and keep the optimizer’s stdout/stderr so it can be shown to the user.
- Remove redundant originals: after optimization, if a .webp (or otherwise optimized) file exists with the same base name as another image, delete the original (non-webp) copy to avoid duplicates.
- Create archive: package the remaining files into an archive named after the source folder (keeping relative paths inside the archive), using “store” (no extra compression) to match expected reader compatibility.
- Remove source folder: remove the original folder once archiving succeeds. Prefer sending to OS trash where available; otherwise delete recursively. Do not delete the created archive.

# Folder traversal behavior

The app treats a selected root directory as possibly containing "series" folders that themselves contain issue folders. If a folder contains subfolders, each subfolder is processed into its own archive. If a folder contains images directly, that folder is processed into an archive. Process every applicable folder under the chosen root.

# Presets and pingo integration

Presets are named lists of arguments for the pingo executable (for example, a lossy preset vs a lossless preset). The app shows the exact command for the selected preset.
Allow a user-configured pingo path (so the app can run a bundled or external pingo), or fall back to searching the system PATH.
Provide an option to skip running pingo entirely.

# User experience & reporting

Always run long tasks off the UI thread and stream short status updates: current folder name, start/finish per-folder, and any optimizer output lines. Show the full optimizer output per folder in a report view.
Provide an obvious warning that the tool mutates and deletes files; recommend users back up data before running.

# Settings & persistence

Persist minimal settings: last selected root directory, last selected preset, last output extension, skip-pingo flag, custom pingo path, and the presets themselves. Store these in shared_preferences.
Defaults should include sensible lossy and lossless presets.

# Reliability and edge cases

- Use natural (human) sorting for filenames so ordering matches reading order.
- Perform renames atomically (e.g., via temporary names) to avoid name collisions.
- Validate that the archive path is not inside the folder being removed; avoid deleting the produced archive.
- If pingo fails, capture its output and continue to the archive step if appropriate, but surface errors prominently.
- Be careful with permissions and path length limitations on target platforms.

# Safety reminder

Make the app explicit and conservative about destructive actions: show clear confirmation before running, require an explicit “Start” action, and recommend backups.
