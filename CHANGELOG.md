## [0.0.13]

- Fixed a typo in the permission documentation.
- Added support for a new location permission variant on iOS.
- Refactored permission status mapping logic for improved clarity.

## [0.0.12]

- Resolved an issue with permission checks on iOS 17.
- Enhanced error messages for unsupported permissions.
- Optimized the permission request flow for better performance.

## [0.0.11]

- Changed the logger level from debug to info for permission handling operations.

## [0.0.10]

- Fixed a missing implements directive for the Flutter plugin.
- Refactored environment and platform settings in `pubspec.yaml` for better organization.

## [0.0.9]

- Added support for additional permissions: storage, Bluetooth, sensors, contacts, calendar, photos, notifications, and speech recognition.
- Introduced the `"all"` option to enable all supported permissions with a single command.

## [0.0.2]

- Updated the `README.md` file.

## [0.0.1]

- Initial release of `permission_config`.
- Automatically adds Android/iOS permission entries.
- Generates a `permission_handler.dart` file with ready-to-use logic.
