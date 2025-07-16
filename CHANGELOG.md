## [0.0.12]

- Fix: resolve permission check issue on iOS 17
- Update: improve error messages for unsupported permissions
- Refactor: optimize permission request flow for better performance

## [0.0.11]

- Change logger level from debug to info for permission handling operations

## [0.0.10]

- Fix: add missing implements directive for flutter plugin
- Refactor: reorganize environment and platform settings in pubspec.yaml

## [0.0.9]

- Added support for **additional permissions**: storage, Bluetooth, sensors, contacts, calendar, photos, notifications, and speech recognition.
- Introduced `"all"` option to add all supported permissions in one command.

## [0.0.2]

- Update the Readme.md file

## [0.0.1]

- Initial release of `permission_config`.
- Adds Android/iOS permission entries automatically.
- Generates a `permission_handler.dart` with ready-to-use logic.
