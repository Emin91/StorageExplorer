# Changelog

All notable changes to Storage Explorer are listed here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- **Zustand plugin**: live state of the stores registered in `global.__STORAGE_EXPLORER_ZUSTAND__`, without actions. See the [setup guide](docs/plugins/zustand.md).

### Changed

- Redux and Zustand share one debugger connection to the app.
- The Metro Port setting is shown under the first enabled Redux or Zustand plugin.

### Fixed

- Redux and Zustand connect to apps on newer Metro (Expo SDK 52+, React Native 0.76+), which rejected the connection.
- No endless reconnect loop when Redux and Zustand read at the same time.
- A missing Redux store no longer drops the debugger connection on every read.

## [1.1.0] - 2026-11-17

### Added

- **Redux plugin**: live store state through Metro and the Hermes debugger, with state grouped into Slices and RTK Query. Needs [one line in your app](docs/plugins/redux.md).
- **Statistics page**: a bar chart comparing enabled plugins by size and key count. Click a bar to open that plugin's keys.
- Sorting by column and filtering by value type.
- Showing and hiding table columns.
- Highlighting of changed values in the key list, the JSON tree and on the plugin cards.
- Search inside a value, with match navigation and scrolling to the match.
- Button that opens the app's data folder in Finder.
- Settings: Metro port for the Redux plugin; change highlight on/off, color and duration.
- Link to the setup guide in Redux errors.

### Changed

- Reset to Defaults also resets column widths, visible columns and type filters.
- Large values load faster: table rows show a short preview instead of the full text.
- License changed from MIT to Apache 2.0, with a NOTICE file.
- DMG window uses a light background, so Finder's icon labels stay readable.

### Fixed

- Table header and rows no longer misalign when scroll bars are always visible.
- Spacing between the collapsed panel and the Simulator.

## [1.0.0] - 2026-11-15

First release.

- Floating panel docked to iOS Simulator, following its window; detached, minimized and hidden modes.
- AsyncStorage (regular builds and Expo Go), MMKV and Redux Persist plugins, with no setup in the app.
- Real-time updates, search across keys and values, key count and total size.
- Value inspector with a collapsible JSON tree, raw mode and one-click copy.
- App picker for every app on all booted simulators, following the running app, with pinning.
- Settings: plugins, launch at login, Dock icon, panel spacing, background and opacity.
- Menu bar icon.

[Unreleased]: https://github.com/Emin91/StorageExplorer/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/Emin91/StorageExplorer/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/Emin91/StorageExplorer/releases/tag/v1.0.0
