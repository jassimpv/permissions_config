import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Main CLI Integration Tests', () {
    late Directory tempDir;
    late String originalDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('cli_test_');
      originalDir = Directory.current.path;
      Directory.current = tempDir.path;

      // Create a basic Flutter project structure
      await Directory(p.join(tempDir.path, 'android', 'app', 'src', 'main'))
          .create(recursive: true);
      await Directory(p.join(tempDir.path, 'ios', 'Runner'))
          .create(recursive: true);

      // Create basic AndroidManifest.xml
      final androidManifest = '''<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.test">
    <application android:label="test"></application>
</manifest>''';

      await File(p.join(tempDir.path, 'android', 'app', 'src', 'main',
              'AndroidManifest.xml'))
          .writeAsString(androidManifest);

      // Create basic Info.plist
      final infoPlist = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDisplayName</key>
  <string>Test App</string>
</dict>
</plist>''';

      await File(p.join(tempDir.path, 'ios', 'Runner', 'Info.plist'))
          .writeAsString(infoPlist);

      // Create basic pubspec.yaml
      final pubspec = '''name: test_app
description: A test Flutter application.
version: 1.0.0+1

environment:
  sdk: ">=2.17.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
''';
      await File(p.join(tempDir.path, 'pubspec.yaml')).writeAsString(pubspec);
    });

    tearDown(() async {
      Directory.current = originalDir;
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('should handle camera permission request', () async {
      // Execute the main script with camera argument
      await Process.run(
        'dart',
        ['run', p.join(originalDir, 'bin', 'permission_config.dart'), 'camera'],
        workingDirectory: tempDir.path,
      );

      // Check if permissions were added to AndroidManifest.xml
      final manifestContent = await File(p.join(tempDir.path, 'android', 'app',
              'src', 'main', 'AndroidManifest.xml'))
          .readAsString();
      expect(manifestContent.contains('android.permission.CAMERA'), isTrue);

      // Check if permissions were added to Info.plist
      final plistContent =
          await File(p.join(tempDir.path, 'ios', 'Runner', 'Info.plist'))
              .readAsString();
      expect(plistContent.contains('NSCameraUsageDescription'), isTrue);
    });

    test('should handle location permission request', () async {
      await Process.run(
        'dart',
        [
          'run',
          p.join(originalDir, 'bin', 'permission_config.dart'),
          'location'
        ],
        workingDirectory: tempDir.path,
      );

      final manifestContent = await File(p.join(tempDir.path, 'android', 'app',
              'src', 'main', 'AndroidManifest.xml'))
          .readAsString();
      expect(manifestContent.contains('ACCESS_FINE_LOCATION'), isTrue);
      expect(manifestContent.contains('ACCESS_COARSE_LOCATION'), isTrue);

      final plistContent =
          await File(p.join(tempDir.path, 'ios', 'Runner', 'Info.plist'))
              .readAsString();
      expect(
          plistContent.contains('NSLocationWhenInUseUsageDescription'), isTrue);
    });

    test('should create permission handler file', () async {
      await Process.run(
        'dart',
        ['run', p.join(originalDir, 'bin', 'permission_config.dart'), 'camera'],
        workingDirectory: tempDir.path,
      );

      final handlerFile =
          File(p.join(tempDir.path, 'lib', 'utils', 'permission_handler.dart'));
      expect(await handlerFile.exists(), isTrue);

      final content = await handlerFile.readAsString();
      expect(content.contains('class PermissionUtils'), isTrue);
    });

    test('should handle all permissions request', () async {
      await Process.run(
        'dart',
        ['run', p.join(originalDir, 'bin', 'permission_config.dart'), 'all'],
        workingDirectory: tempDir.path,
      );

      final manifestContent = await File(p.join(tempDir.path, 'android', 'app',
              'src', 'main', 'AndroidManifest.xml'))
          .readAsString();

      // Check for multiple Android permissions
      expect(manifestContent.contains('android.permission.CAMERA'), isTrue);
      expect(
          manifestContent.contains('android.permission.RECORD_AUDIO'), isTrue);
      expect(manifestContent.contains('ACCESS_FINE_LOCATION'), isTrue);
      // New Android 13 permission inserted by script
      expect(manifestContent.contains('android.permission.POST_NOTIFICATIONS'),
          isTrue);

      final plistContent =
          await File(p.join(tempDir.path, 'ios', 'Runner', 'Info.plist'))
              .readAsString();

      // Check for multiple iOS permissions
      expect(plistContent.contains('NSCameraUsageDescription'), isTrue);
      expect(plistContent.contains('NSMicrophoneUsageDescription'), isTrue);
      expect(
          plistContent.contains('NSLocationWhenInUseUsageDescription'), isTrue);
    });

    test('should create backups before modifying files', () async {
      await Process.run(
        'dart',
        ['run', p.join(originalDir, 'bin', 'permission_config.dart'), 'camera'],
        workingDirectory: tempDir.path,
      );

      final manifestBackup = File(p.join(tempDir.path, 'android', 'app', 'src',
          'main', 'AndroidManifest.xml.bak'));
      final plistBackup =
          File(p.join(tempDir.path, 'ios', 'Runner', 'Info.plist.bak'));

      expect(await manifestBackup.exists(), isTrue);
      expect(await plistBackup.exists(), isTrue);
    });

    test('should handle unsupported permission gracefully', () async {
      final result = await Process.run(
        'dart',
        [
          'run',
          p.join(originalDir, 'bin', 'permission_config.dart'),
          'unsupported_permission'
        ],
        workingDirectory: tempDir.path,
      );

      // Should not crash and should complete
      expect(result.exitCode, anyOf(equals(0), equals(1)));
    });

    test('should display usage when no arguments provided', () async {
      final result = await Process.run(
        'dart',
        ['run', p.join(originalDir, 'bin', 'permission_config.dart')],
        workingDirectory: tempDir.path,
      );

      expect(result.exitCode, equals(1));
    });

    test('should extract app name from pubspec.yaml', () async {
      // Modify pubspec.yaml to have a specific app name
      final customPubspec = '''name: my_awesome_app
description: A test Flutter application.
version: 1.0.0+1

environment:
  sdk: ">=2.17.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
''';
      await File(p.join(tempDir.path, 'pubspec.yaml'))
          .writeAsString(customPubspec);

      await Process.run(
        'dart',
        ['run', p.join(originalDir, 'bin', 'permission_config.dart'), 'camera'],
        workingDirectory: tempDir.path,
      );

      final plistContent =
          await File(p.join(tempDir.path, 'ios', 'Runner', 'Info.plist'))
              .readAsString();

      // Should contain the app name in the permission message
      expect(plistContent.contains('my_awesome_app'), isTrue);
    });

    test('should handle microphone permission alias', () async {
      await Process.run(
        'dart',
        ['run', p.join(originalDir, 'bin', 'permission_config.dart'), 'mic'],
        workingDirectory: tempDir.path,
      );

      final manifestContent = await File(p.join(tempDir.path, 'android', 'app',
              'src', 'main', 'AndroidManifest.xml'))
          .readAsString();
      expect(
          manifestContent.contains('android.permission.RECORD_AUDIO'), isTrue);

      final plistContent =
          await File(p.join(tempDir.path, 'ios', 'Runner', 'Info.plist'))
              .readAsString();
      expect(plistContent.contains('NSMicrophoneUsageDescription'), isTrue);
    });
  });

  group('Error Handling Tests', () {
    late Directory tempDir;
    late String originalDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('error_test_');
      originalDir = Directory.current.path;
      Directory.current = tempDir.path;
    });

    tearDown(() async {
      Directory.current = originalDir;
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('should handle missing Android directory gracefully', () async {
      // Create only iOS structure
      await Directory(p.join(tempDir.path, 'ios', 'Runner'))
          .create(recursive: true);

      final infoPlist = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDisplayName</key>
  <string>Test App</string>
</dict>
</plist>''';

      await File(p.join(tempDir.path, 'ios', 'Runner', 'Info.plist'))
          .writeAsString(infoPlist);

      final result = await Process.run(
        'dart',
        ['run', p.join(originalDir, 'bin', 'permission_config.dart'), 'camera'],
        workingDirectory: tempDir.path,
      );

      // Should complete without crashing
      expect(result.exitCode, anyOf(equals(0), equals(1)));

      // iOS permission should still be added
      final plistContent =
          await File(p.join(tempDir.path, 'ios', 'Runner', 'Info.plist'))
              .readAsString();
      expect(plistContent.contains('NSCameraUsageDescription'), isTrue);
    });

    test('should handle missing iOS directory gracefully', () async {
      // Create only Android structure
      await Directory(p.join(tempDir.path, 'android', 'app', 'src', 'main'))
          .create(recursive: true);

      final androidManifest = '''<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.test">
    <application android:label="test"></application>
</manifest>''';

      await File(p.join(tempDir.path, 'android', 'app', 'src', 'main',
              'AndroidManifest.xml'))
          .writeAsString(androidManifest);

      final result = await Process.run(
        'dart',
        ['run', p.join(originalDir, 'bin', 'permission_config.dart'), 'camera'],
        workingDirectory: tempDir.path,
      );

      // Should complete without crashing
      expect(result.exitCode, anyOf(equals(0), equals(1)));

      // Android permission should still be added
      final manifestContent = await File(p.join(tempDir.path, 'android', 'app',
              'src', 'main', 'AndroidManifest.xml'))
          .readAsString();
      expect(manifestContent.contains('android.permission.CAMERA'), isTrue);
    });
  });
}
