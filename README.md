# 🚀 Permission Config

A **Flutter CLI plugin** that **automatically adds Android/iOS permissions** (Camera, Microphone, Location) to your Flutter project and generates a ready-to-use runtime permission handler file.  
Say goodbye to manually editing `AndroidManifest.xml` and `Info.plist` — this tool does it all for you!

---

## ✨ Features

- ✅ ✅ Supports permissions for **Camera**, **Microphone**, **Location**, **Storage**, **Bluetooth**, **Sensors**, **Contacts**, **Calendar**, **Photos**, **Notifications**, and **Speech Recognition**
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

| Permission      | Aliases        | Description                                             |
| --------------- | -------------- | ------------------------------------------------------- |
| `camera`        | -              | Access to the device camera                             |
| `microphone`    | `mic`          | Access to the microphone                                |
| `location`      | -              | Access to device location services (fine & coarse)      |
| `storage`       | -              | Read/write external storage (Android only)              |
| `bluetooth`     | -              | Access Bluetooth and BLE devices                        |
| `sensors`       | -              | Access body sensors and motion data                     |
| `contacts`      | -              | Access the user's contact list                          |
| `calendar`      | -              | Access calendar events and reminders                    |
| `photos`        | -              | Access the photo library (iOS only)                     |
| `notifications` | -              | Access to send and display notifications (iOS only)     |
| `speech`        | -              | Use speech recognition services (iOS only)              |
| `all`           | -              | Adds **all** supported permissions above automatically  |
| --------------  | -------------- | ------------------------------------------------------- |

### Examples:

    permission_config all
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

---

## 👤 Contributors

- [Khurshidddbek](https://github.com/Khurshidddbek)
