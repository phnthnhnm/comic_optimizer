# Comic Optimizer

Comic Optimizer is a modern, user-friendly Flutter desktop app for optimizing comic book archives (CBZ) by compressing images and optionally running the `pingo` optimizer.

## Features

- Batch optimize comic folders into CBZ/CBR/ZIP files
- Select from multiple `pingo` presets
- See the exact `pingo` command that will be run for each preset
- Option to skip `pingo` optimization

## Requirements

- [pingo](https://css-ig.net/pingo) (recommended for image optimization compression; optional if you only want basic auto file renaming/sorting and folder archiving). Install from and put it on your `PATH` or specify the full path in the app settings.
- [Flutter SDK](https://docs.flutter.dev/install). The project is a Flutter desktop app — have `flutter` available in your PATH to run or build from source.

## Installation

### Download the Standalone Release (Recommended)

- Visit the [GitHub Releases](https://github.com/phnthnhnm/comic_optimizer/releases) page and download the prebuilt Windows zip for the latest version.
- Extract the zip and run the executable in the extracted folder.

### Build from Source (Windows)

1. Clone the repository:

```bash
git clone https://github.com/phnthnhnm/comic_optimizer.git
cd comic_optimizer
```

2. Ensure the Flutter SDK is installed and on your `PATH`. Enable desktop support if needed:

```bash
flutter channel stable
flutter upgrade
flutter config --enable-windows-desktop
```

3. Get dependencies and run in debug on Windows:

```bash
flutter pub get
flutter run -d windows
```

4. Create a release build for Windows:

```bash
flutter build windows --release
# The release executable will be under build\\windows\\runner\\Release\\
```

Zip the release folder for distribution or upload the artifacts to GitHub Releases.

## How to Use

1. Launch the app (downloaded release or run via `flutter run -d windows`).
2. Click "Choose Root" to select the root directory containing your comic folders.
3. Choose a `pingo` preset from the dropdown.
   - The exact command for the selected preset is shown on hover.
   - (Optional) Check "Skip pingo" to bypass `pingo` optimization.
4. Click "Start" to begin processing. Live progress is shown in the app.
5. Use the Settings screen to change theme or other preferences.

## User Settings Location

User-specific settings are saved in a JSON file in a user-writable config directory:

`%APPDATA%/com.phanthanhnam/comic_optimizer/shared_preferences.json`

This file is created automatically on first run. Deleting it will reset preferences to defaults.

## License

See [LICENSE](LICENSE) for details.
