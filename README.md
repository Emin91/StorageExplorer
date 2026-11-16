<div align="center">

<img src="docs/icon.png" width="128" height="128" alt="Storage Explorer icon">

# Storage Explorer

**Inspect React Native app storage in real time, right next to iOS Simulator.**<br>
No packages to install. No changes to your app code.

[![Latest release](https://img.shields.io/github/v/release/Emin91/StorageExplorer?color=FF9500&label=release)](https://github.com/Emin91/StorageExplorer/releases/latest)
![macOS 15+](https://img.shields.io/badge/macOS-15%2B-000000?logo=apple&logoColor=white)
![Swift](https://img.shields.io/badge/SwiftUI-Swift%206-F05138?logo=swift&logoColor=white)
[![License: Apache 2.0](https://img.shields.io/badge/license-Apache%202.0-blue)](LICENSE)

[Install](#installation) · [Features](#features) · [How it works](#how-it-works) · [Roadmap](#roadmap)

</div>

<p align="center">
  <img src="docs/screenshot.png" width="900" alt="Storage Explorer next to iOS Simulator">
</p>

https://github.com/user-attachments/assets/f18fe01e-0353-4caf-b9aa-1643b4d0cf97

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/Emin91/StorageExplorer/main/install.sh | bash
```

That's it. The script downloads the latest release, installs **Storage Explorer** into **Applications** and launches it, without the "developer cannot be verified" warning. Run it again any time to update.

<details>
<summary><b>Prefer a manual download?</b></summary>

1. Download `StorageExplorer-<version>.dmg` from [Releases](https://github.com/Emin91/StorageExplorer/releases/latest) and open it.
2. Drag **Storage Explorer** into the **Applications** folder.
3. Launch the app. macOS will say the developer cannot be verified: the app is not yet notarized by Apple.
4. Go to **System Settings → Privacy & Security** and click **Open Anyway** at the bottom. You only need to do this once.

</details>

**First launch:** grant **Accessibility** permission when prompted, so the panel can follow the Simulator window. Then click the orange tab at the edge of the Simulator to open the panel.

## Features

### 🔌 Plugins

| Plugin            | What you see                                              |
| ----------------- | --------------------------------------------------------- |
| **AsyncStorage**  | All keys of regular builds and Expo Go projects           |
| **MMKV**          | Every `react-native-mmkv` instance, labeled with its name |
| **Redux Persist** | `persist:*` entries unpacked into state slices            |

Coming soon: Redux, Zustand, MobX, Realm, Encrypted Storage.

### ⚡ Real-time data

- Key, value, type, size and last-modified columns.
- Updates the moment your app writes data.
- Search across keys and values with highlighted matches.
- Key count and total storage size at a glance.

### 🔍 Value inspector

- Collapsible JSON tree with syntax highlighting.
- JSON nested in strings is decoded automatically.
- Raw mode with pretty-printed JSON.
- One-click copy for keys and values.

### 📱 App selection

- Every app with storage data on all booted simulators: icon, name, version, bundle ID, device and iOS version.
- Follows the app you're running. Pin it to keep the current selection.

### ⚙️ Settings

- Turn plugins on and off.
- Launch at login.
- Menu bar only mode, without a Dock icon.

## Requirements

- macOS 15 or later
- Xcode with iOS Simulator
- A React Native app running in the Simulator

## How it works

Storage Explorer reads data directly from your app's files in the Simulator (`~/Library/Developer/CoreSimulator/Devices/…`), so nothing needs to be installed in your React Native project.

| Storage       | How it's read                                                                                 |
| ------------- | --------------------------------------------------------------------------------------------- |
| AsyncStorage  | `manifest.json` plus separate files for large values; changes tracked with file system events |
| MMKV          | The binary instance format; re-read every second                                              |
| Redux Persist | `persist:*` entries from AsyncStorage and MMKV, with the double JSON encoding unpacked        |

## Limitations

- Read-only: data can't be edited yet.
- iOS Simulator only: physical devices and Android are not supported.
- Encrypted MMKV instances can't be read.
- Redux Persist shows the persisted state, not the current in-memory state.
- Last-modified times are tracked only while Storage Explorer is running.

## Roadmap

- [ ] Editing, adding and deleting keys
- [ ] Redux, Zustand, MobX, Realm, Encrypted Storage and SQLite plugins
- [ ] JSON export and import
- [ ] Sorting by column
- [ ] Keyboard shortcuts

## Project structure

```
App/          entry point, AppDelegate, menu bar icon
Windows/      floating panel and its windows
Services/     app discovery, AsyncStorage/MMKV/Redux Persist readers, Simulator tracking
ViewModels/   app selection, plugin data, panel state
Views/        SwiftUI interface: table, value inspector, settings
Models/       data models
Extensions/   helper extensions
scripts/      DMG build
install.sh    one-command installer
```

## Author

**Emin Zeynalov**

[![Telegram](https://img.shields.io/badge/Telegram-@emin91zeynalov-26A5E4?logo=telegram&logoColor=white)](https://t.me/emin91zeynalov)
[![GitHub](https://img.shields.io/badge/GitHub-Emin91-181717?logo=github&logoColor=white)](https://github.com/Emin91)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-emin91zeynalov-0A66C2?logo=linkedin&logoColor=white)](https://www.linkedin.com/in/emin91zeynalov/)

## License

Storage Explorer is free and open source under the [Apache License 2.0](LICENSE).

You're welcome to use, modify and share it, including in commercial projects. If you distribute it or a modified version, keep the [NOTICE](NOTICE) file with the original attribution and mark the files you changed.

Copyright © 2026 Emin Zeynalov
