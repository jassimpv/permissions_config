# 🚀 Permission Config

A **Flutter CLI plugin** that **automatically adds Android/iOS permissions** (Camera, Microphone, Location) to your Flutter project and generates a ready-to-use runtime permission handler file.  
Say goodbye to manually editing `AndroidManifest.xml` and `Info.plist` — this tool does it all for you!

---

## ✨ Features

- ✅ Add permissions for **Camera**, **Microphone**, and **Location**
- ⚙️ Automatically injects required Android and iOS permission entries
- 📁 Generates a pre-written `permission_handler.dart` file under `lib/Utils/`
- 📦 Adds `permission_handler` dependency automatically in your `pubspec.yaml`
- 💾 Creates backup files (`.bak`) before modifying platform configs
- 📝 Uses `logger` for clean, informative CLI output

---

## 📦 Installation

Activate the plugin globally with Dart pub:

    dart pub global activate permission_config

---

## 🔧 Usage

Run this command inside your Flutter project root:

    permission_config <permission> [optional-ios-message]

### Supported permissions:

| Permission   | Aliases | Description                        |
| ------------ | ------- | ---------------------------------- |
| `camera`     | -       | Access to the device camera        |
| `microphone` | `mic`   | Access to the microphone           |
| `location`   | -       | Access to device location services |

### Examples:

    permission_config camera
    permission_config mic "This app needs mic access for voice chat."
    permission_config location

---

## 💾 Backup Files

Before applying changes, backups are created:

- `AndroidManifest.xml.bak`
- `Info.plist.bak`

---

## 🙌 Contribution

Found a bug or want to add more permissions?  
Feel free to open an issue or submit a pull request! Your contributions are welcome. 💙

---

### Happy coding! 🚀
