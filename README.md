# Comic Optimizer

[![CI](https://github.com/phnthnhnm/comic_optimizer/actions/workflows/ci.yml/badge.svg)](https://github.com/phnthnhnm/comic_optimizer/actions/workflows/ci.yml)

Comic Optimizer is a Windows desktop app that turns folders of comic pages into
`.cbz` archives after re-encoding every image to JPEG XL. It is built for batch
work: point it at a library root, pick a quality preset, and it handles the
whole pipeline — cleaning up each folder, normalizing page order, encoding with
`cjxl`, packing the archive, and removing the originals.

> [!WARNING]
> Comic Optimizer **modifies and deletes files**. By default it removes
> non-image files from each comic folder, replaces the original images with
> `.jxl` versions, and deletes the source folder once the archive is written.
> Try **Keep originals** on a small folder first, and keep a backup of anything
> you care about.

## Features

- **Batch processing** of an ordered queue of libraries, with per-folder
  status, live progress, pause/resume and cancel.
- **Preflight summary** before every run: comics, images and non-image files,
  with the deletion and safe-run choices in one place.
- **Run workspace** with comics/images progress, elapsed and remaining time, a
  folder table, and severity-coloured diagnostics.
- **Results and history**: space saved, comics grouped by library, failure
  details with retry, a JSON report export, and the last 50 runs on the
  History screen.
- **Keyboard-first workflow**: `Ctrl+O` add folder, `Ctrl+Enter` start,
  `Ctrl+P` pause/resume, `Ctrl+E` export, `Ctrl+1`/`Ctrl+2`/`Ctrl+,` navigate.
- **Desktop feedback**: taskbar progress while a run is active, a best-effort
  native notification when it finishes, and accessible labels/tooltips on the
  primary controls.
- **Three built-in quality presets** (Lossless, Visually Lossless, Lossy) plus a
  preset editor for saved custom `cjxl` argument sets.
- **Size guard**: if the new `.jxl` is not smaller than the original image, the
  `.jxl` is discarded and the original is kept.
- **Automatic fallbacks**: WebP pages are converted with `dwebp`; JPEGs that
  `cjxl` rejects are re-saved with ImageMagick and retried.
- **Configurable encoder**: point the app at a specific `cjxl` executable in
  Settings instead of relying on `PATH`.
- **Safe run**: process a copy of each folder and leave the originals
  untouched.
- **Flexible cleanup**: move processed folders to the Recycle Bin (default) or
  delete them permanently.
- **Post-run actions**: quit, sleep, hibernate, shut down or restart when the
  batch finishes, with an optional confirmation countdown.
- **Settings backup/restore** to a JSON file, and one fixed Catppuccin Mocha
  theme with a green accent.

## Requirements

- **Windows 10 or later (x64).** The app uses Windows-specific behaviour for
  the Recycle Bin and post-run power actions.
- **[libjxl](https://github.com/libjxl/libjxl) `cjxl` on your `PATH`.** This is
  the only hard external dependency; without it the encoding step cannot run.
  The current release is tested against `cjxl` v0.13.0. `cjxl` v0.11 or newer
  is expected to work, since the presets only use long-standing flags. If the
  encoder lives somewhere else, set its full path in **Settings → Encoding**.
- **Optional: [ImageMagick](https://imagemagick.org/) (`magick`).** Used only
  as a retry path when `cjxl` exits with code 1 (for example on CMYK or
  slightly malformed JPEGs).
- **Optional: [libwebp](https://developers.google.com/speed/webp) (`dwebp`).**
  Required only if your comics contain `.webp` pages.
- **Flutter SDK** (stable channel) if you build from source. The project was
  last built with Flutter 3.50 / Dart 3.14; `pubspec.yaml` requires Dart
  `^3.13.0` and Flutter 3.47 or newer.

## Installation

### Download a release (recommended)

1. Open the [Releases](https://github.com/phnthnhnm/comic_optimizer/releases)
   page.
2. Download the latest `comic_optimizer-<version>-windows-x64.zip`.
3. Extract the archive and run `comic_optimizer.exe`.

`cjxl` is not bundled — install libjxl separately and make sure `cjxl.exe` is
on `PATH` (for example with `scoop install libjxl` or the official release
archives).

### Nightly builds

> [!WARNING]
> Nightly builds are untested and may be unstable or broken. Use them at your
> own risk.

1. Open the [Actions](https://github.com/phnthnhnm/comic_optimizer/actions/workflows/ci.yml)
   tab and select the latest successful run.
2. Download the **windows-build** artifact (a GitHub account is required).
3. Extract the zip and run `comic_optimizer.exe`.

### Build from source

```bash
git clone https://github.com/phnthnhnm/comic_optimizer.git
cd comic_optimizer
flutter pub get
flutter run -d windows        # debug run
flutter build windows --release
```

The release build is written to `build\windows\x64\runner\Release\`. Zip that
folder if you want to distribute it.

## Usage

1. Click **Add folder** for each comic library. Folders are processed in the
   order shown; drag the handle to reorder, or remove one with ×.
2. Pick a **quality preset**:
   - **Lossless** — perfect quality, largest files.
   - **Visually lossless** — recommended; indistinguishable at reading size.
   - **Smaller files** — lossy; smallest output.
3. Adjust the options:
   - **Encode to JPEG XL** — archive existing images as-is when disabled.
   - **Delete non-image files** — remove `ComicInfo.xml`, `.nfo`, `.txt`, etc.
   - **Keep originals** — process a copy and leave the source folders untouched.
   - **Advanced** — permanent deletion and the after-finish power action.
4. Click **Start** and review the preflight summary (comics, images, non-image
   files). Confirm to run; the workspace shows live comics/images progress,
   elapsed and remaining time, a folder table and diagnostics. Use **Pause**,
   **Resume** or **Cancel** in the header at any time.
5. When the run finishes, review **Results**: space saved, comics grouped by
   library, and any failures with **Retry failed**. **Export report** saves a
   JSON summary, and **History** keeps the last 50 runs.

A comic folder is any folder directly under a library root, or directly under
one of those folders. If a root itself contains only images, the root is
treated as a single comic.

### Keyboard shortcuts

| Shortcut | Action |
| --- | --- |
| `Ctrl+O` | Add a library folder |
| `Ctrl+Enter` | Start a run (opens preflight) |
| `Ctrl+P` | Pause or resume the current run |
| `Ctrl+E` | Export the finished run as JSON |
| `Ctrl+1` | Library |
| `Ctrl+2` | History |
| `Ctrl+,` | Settings |

## How it works

For every comic folder the app runs this pipeline:

1. Record the size of each image so savings can be reported later.
2. Delete files that are not images when **Delete non-image files** is on.
3. Rename the remaining images to a zero-padded sequence (`001.png`,
   `002.png`, …) so pages are archived in natural order.
4. If **Encode to JPEG XL** is on, encode each image to `<name>.jxl`:
   - `.webp` pages are first converted to PNG with `dwebp`;
   - `cjxl` is run with the selected preset;
   - if `cjxl` exits with code 1, the page is re-saved with `magick` and
     retried once;
   - if the resulting `.jxl` is not smaller than the original, it is deleted
     and the original image is kept.
5. Delete any original image that now has a `.jxl` file with the same name.
6. Write `<folder>.cbz` next to the source folder (a ZIP archive with no
   compression, since JPEG XL is already compressed).
7. Delete the source folder — moved to the Recycle Bin by default, or removed
   permanently if that option is enabled.

> [!IMPORTANT]
> - **Non-image files are deleted by default.** That includes `ComicInfo.xml`,
>   `.nfo`, `.txt` and anything else that is not `.png`, `.jpg`, `.jpeg`,
>   `.webp`, `.apng` or `.jxl`. Turn off **Delete non-image files** to keep
>   them; they are then packed into the archive.
> - **Only files directly inside the comic folder are archived.** Nested
>   subfolders are not packed, but the whole folder is still removed
>   afterwards.
> - **Archives are always ZIP**, even when the output extension is `.cbr`.
>   The extension is only a label for comic readers.
> - An existing archive with the same name is overwritten.

## Presets

| Preset | `cjxl` arguments | Notes |
| --- | --- | --- |
| Lossless | `--distance=0 --lossless_jpeg=1 --quiet` | Mathematically lossless. JPEG pages are losslessly transcoded when possible; other formats are encoded losslessly from pixels. |
| Visually Lossless | `--distance=1.0 --lossless_jpeg=0 --quiet` | Re-encodes pixels at distance 1.0. Visually indistinguishable at normal reading size. |
| Lossy | `--distance=3.0 --lossless_jpeg=0 --quiet` | Smallest files. Good for quick reading; fine line art may show artifacts. |

Presets live in `lib/domain/models/preset.dart`. Custom presets created in the
app are stored with the rest of the settings and appear alongside the built-ins.

## Settings and data

Settings are stored with `shared_preferences` at:

```
%APPDATA%\com.phanthanhnam\comic_optimizer\shared_preferences.json
```

Deleting that file resets the app to its defaults. **Settings** is split into
six sections:

- **General** — default quality preset, archive format, and the after-run action.
- **Encoding** — the `cjxl` path (leave it as `cjxl` to resolve from `PATH`),
  with **Check version** detection.
- **Presets** — built-in argument sets plus saved custom presets.
- **Safety** — Keep originals, non-image deletion, and permanent deletion.
- **Data** — timestamped JSON backup, restore, and full reset.
- **About** — version, source link, and credits.

The app uses one fixed Catppuccin Mocha theme with a green accent; there is no
theme setting.

## Project structure

```
lib/
  main.dart                     App entry point and theme wiring
  core/                         Interfaces, Result type, router, providers, utils
  domain/                       Freezed models and enums (settings, state, presets)
  infrastructure/services/      Implementations: encoder, archive, optimizer,
                                file I/O, settings
  features/                     Riverpod notifiers and screens (home, settings)
  presentation/                 Reusable widgets and log-line colouring
test/                           Unit and integration tests mirroring lib/
windows/                        Flutter Windows runner
.github/workflows/              CI and release automation
```

## Development

```bash
flutter pub get
flutter analyze                       # must be clean
dart format lib/ test/
flutter test                          # 132 tests, including cjxl integration
flutter build windows --release
```

Generated code (`*.freezed.dart`, `*.g.dart`) is committed. Regenerate it after
changing a freezed model or an enum that is serialized:

```bash
dart run build_runner build --delete-conflicting-outputs
```

The encoder tests invoke the real `cjxl` when it is on `PATH` and skip
otherwise, so install libjxl to get full coverage.

## Troubleshooting

| Symptom | Cause / fix |
| --- | --- |
| `ProcessException: The system cannot find the file specified` | `cjxl` is not on `PATH`. Install libjxl, or set the full path in Settings → Encoding. |
| `cjxl exit 1` followed by an ImageMagick retry | The JPEG could not be transcoded as-is. The app re-saves it as PNG and retries; install ImageMagick to enable this fallback. |
| `Reverted larger .jxl` | Expected: the encoded file was not smaller, so the original was kept. |
| WebP pages are skipped or fail | Install `dwebp` from libwebp. |
| Source folder is not removed | The archive could not be written, or the folder is in use. Check the log for the folder. |
| "Failed to remove source folder" | Recycle Bin deletion goes through PowerShell; check that PowerShell is available and the folder is not locked. |

## Contributing

- Use [Conventional Commits](https://www.conventionalcommits.org/). CI only
  runs for `feat`, `fix`, `refactor`, `ci` and `build` messages.
- Run `flutter analyze` and `flutter test` before pushing.
- Commits are signed; configure a signing key if you want to reproduce the
  release history.

## Releases

Releases are automated from `main` with
[release-please](https://github.com/googleapis/release-please); there is no
manual tagging or upload step.

1. Merge changes into `main` using Conventional Commit messages.
2. The **Release Please** workflow opens or updates a pull request named
   `chore(main): release X.Y.Z`, containing the version bump and the
   changelog entry.
3. Merge that pull request. Release Please creates the `vX.Y.Z` tag and
   publishes the GitHub release.
4. The **Release Build and Upload** workflow runs on the published release,
   builds the tagged commit, and attaches
   `comic_optimizer-X.Y.Z-windows-x64.zip` to it.

Version bumps follow the commit types (`feat` → minor, `fix` → patch,
breaking change → major; pre-1.0 minor bumps are enabled).

## License

See [LICENSE](LICENSE) for details.
