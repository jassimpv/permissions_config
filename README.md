# 🚀 Permission Configurator

A Flutter CLI plugin that **automatically adds Android/iOS permissions** (Camera, Microphone, Location) into your Flutter project and generates a runtime permission handler file. Stop manually editing `AndroidManifest.xml` and `Info.plist` — this tool does it for you!

---

/\*\*

- Initializes the platform-specific features for the application.
-
- Currently supports Android and iOS platforms. Support for additional platforms is under development.
-
- @param config Configuration options for platform initialization.
- @returns A promise that resolves when initialization is complete.
  \*/

## ✨ Features

- ✅ Add permissions for **Camera**, **Microphone**, and **Location**
- ✅ Automatically injects required Android and iOS permission entries
- ✅ Creates a pre-written `permission_handler.dart` file under `lib/Utils/`
- ✅ Adds `permission_handler` to your `pubspec.yaml` automatically
- ✅ Backs up original platform config files (`.bak`)
- ✅ Uses `logger` for clean and clear CLI output

---

## 📦 Installation

Activate this plugin globally:

```bash
dart pub global activate permission_configurator
```

---

## 🔧 Usage

Navigate to your Flutter project root and run:

```bash
permission_configurator <permission> [optional-ios-message]
```

Supported values for `<permission>`:

- `camera`
- `microphone` or `mic`
- `location`

**Examples:**

```bash
permission_configurator camera
permission_configurator mic "This app needs mic access for voice chat."
permission_configurator location
```

---

## 📁 What It Does

**Modifies:**

- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`

**Creates:**

- `lib/Utils/permission_handler.dart` file with ready-to-use permission request logic

**Adds:**

- `permission_handler` dependency via `flutter pub add`

**Backups:**

- Creates `.bak` files for AndroidManifest and Info.plist before modifying

---

## 🧠 Internal Logic

| Permission | Android Permissions                              | iOS Keys                                                                              |
| ---------- | ------------------------------------------------ | ------------------------------------------------------------------------------------- |
| Camera     | `android.permission.CAMERA`                      | `NSCameraUsageDescription`                                                            |
| Microphone | `android.permission.RECORD_AUDIO`                | `NSMicrophoneUsageDescription`                                                        |
| Location   | `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` | `NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysAndWhenInUseUsageDescription` |

---

## 📄 permission_handler.dart

The generated file contains:

- Methods to request and check permissions
- Alerts for denied and permanently denied states
- Automatic redirection to app settings if needed

Located at:  
`lib/Utils/permission_handler.dart`

---

## 🧰 Dependencies Used

This plugin uses the following Dart packages:

- `xml`
- `logger`
- `path`

---

## 💻 Development

To run locally:

```bash
dart run bin/main.dart <permission>
```

Or make it executable globally by setting up in your `pubspec.yaml`:

```yaml
executables:
  permission_configurator: bin/main.dart
```

---

## ✅ Example Output

```bash
permission_configurator camera

[✓] permission_handler added successfully.
[✓] Android permission "android.permission.CAMERA" added.
[✓] iOS permission "NSCameraUsageDescription" added.
[✓] Created lib/Utils/permission_handler.dart
```

---

## 📃 License

MIT License  
© 2025 [Your Name]

---

## 🙌 Contribute

Found an issue or want a new permission added? PRs and issues are welcome!

---

## ✍️ Author

Your Name  
GitHub: github.com/yourusername  
Email: [yourname@example.com]
