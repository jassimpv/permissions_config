/// Adds the given [permissionName] to the platform-specific configuration files.
///
/// This function is intended to encapsulate the permission-adding logic
/// from your CLI entry point (`bin/`).
///
/// Supported values for [permissionName] include:
/// `camera`, `microphone`, `location`, `storage`, `bluetooth`, `sensors`,
/// `contacts`, `calendar`, `photos`, `notifications`, `speech`, or `all`.
///
/// Example:
/// ```dart
/// addPermission('camera');
/// ```
void addPermission(String permissionName) {
  // Actual logic from your bin file
}
