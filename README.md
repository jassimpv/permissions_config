# 🚀 Permission Config

A Flutter CLI plugin that **automatically adds Android/iOS permissions** (Camera, Microphone, Location) into your Flutter project and generates a runtime permission handler file. Stop manually editing `AndroidManifest.xml` and `Info.plist` — this tool does it for you!

---

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
dart pub global activate permission_config
```

---

## 🔧 Usage

Navigate to your Flutter project root and run:

```bash
permission_config <permission> [optional-ios-message]
```

Supported values for `<permission>`:

- `camera`
- `microphone` or `mic`
- `location`

**Examples:**

```bash
permission_config camera
permission_config mic "This app needs mic access for voice chat."
permission_config location
```

## 💾 Backups:

`.bak` files for AndroidManifest and Info.plist before any changes

## 📃 License

MIT License  
© 2025 Mohammed Jassim

## 🙌 Contribute

Found an issue or want a new permission added? PRs and issues are welcome!

## ✍️ Author

**Mohammed Jassim**  
Flutter & Dart Developer

GitHub: [jassimpv](https://github.com/jassimpv)

Feel free to reach out for questions, feedback, or contributions!
