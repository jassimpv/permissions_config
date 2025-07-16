import 'dart:io';

import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import 'permissionhandler.dart';

/// Path to the AndroidManifest.xml file
const androidManifestPath = 'android/app/src/main/AndroidManifest.xml';

/// Path to the iOS Info.plist file
const iosPlistPath = 'ios/Runner/Info.plist';

/// Creates the `permission_handler.dart` file inside `lib/utils`
///
/// If the file already exists, it skips creation.
Future<void> createPermissionHandlerFile(
    String projectRoot, Logger logger) async {
  // Use lowercase path to follow Dart package conventions: lib/utils
  final utilsDir = Directory(p.join(projectRoot, 'lib', 'utils'));

  if (!await utilsDir.exists()) {
    await utilsDir.create(recursive: true);
    logger.i('Created folder: ${utilsDir.path}');
  }

  final filePath = p.join(utilsDir.path, 'permission_handler.dart');
  final file = File(filePath);

  if (await file.exists()) {
    logger.i('File already exists at $filePath, skipping creation.');
    return;
  }

  await file.writeAsString(permissionHandlerContent);
  logger.i('Created permission_handler.dart at $filePath');
}

/// Creates a `.bak` backup file of the given [path] if it doesn't already exist.
Future<void> backupFile(String path, Logger logger) async {
  final file = File(path);
  if (await file.exists()) {
    final backupPath = '$path.bak';
    final backupFile = File(backupPath);
    if (!await backupFile.exists()) {
      await file.copy(backupPath);
      logger.i('Backup created at $backupPath');
    }
  }
}

/// Restores a `.bak` backup file to the original [path].
Future<void> restoreBackup(String path, Logger logger) async {
  final backupPath = '$path.bak';
  final backupFile = File(backupPath);
  if (await backupFile.exists()) {
    await backupFile.copy(path);
    logger.i('Restored $path from backup.');
  }
}

/// Adds a permission to AndroidManifest.xml safely if not already present.
///
/// [permissionName] is the full name like `android.permission.CAMERA`.
Future<void> addAndroidPermission(String permissionName, Logger logger) async {
  final file = File(androidManifestPath);
  if (!await file.exists()) {
    logger.i('AndroidManifest.xml not found at $androidManifestPath');
    return;
  }

  await backupFile(androidManifestPath, logger);

  final xmlDoc = XmlDocument.parse(await file.readAsString());
  final manifest = xmlDoc.getElement('manifest');
  if (manifest == null) {
    logger.i('Error: <manifest> element not found in AndroidManifest.xml');
    return;
  }

  final existing = xmlDoc
      .findAllElements('uses-permission')
      .any((e) => e.getAttribute('android:name') == permissionName);

  if (existing) {
    logger.i('✔️ Android permission "$permissionName" already present.');
    return;
  }

  final permissionElement = XmlElement(
    XmlName('uses-permission'),
    [XmlAttribute(XmlName('android:name'), permissionName)],
  );

  final applicationElement = manifest.getElement('application');
  if (applicationElement != null) {
    final appIndex = manifest.children.indexOf(applicationElement);
    manifest.children.insert(appIndex, permissionElement);
  } else {
    manifest.children.insert(0, permissionElement);
  }

  await file.writeAsString(xmlDoc.toXmlString(pretty: true, indent: '  '));
  logger.i('✅ Added Android permission "$permissionName".');
}

/// Adds a permission entry to iOS Info.plist if not already present.
///
/// [key] is the Info.plist permission key, [message] is the user-visible message.
Future<void> addiOSPermission(String key, String message, Logger logger) async {
  final file = File(iosPlistPath);
  if (!await file.exists()) {
    logger.i('Info.plist not found at $iosPlistPath');
    return;
  }

  await backupFile(iosPlistPath, logger);

  final contents = await file.readAsString();
  final xmlDoc = XmlDocument.parse(contents);

  final dict = xmlDoc.findAllElements('dict').first;

  // Check if the key already exists
  final existingKeys = dict.findElements('key');
  if (existingKeys.any((e) => e.innerText == key)) {
    logger.i('✔️ iOS permission "$key" already present.');
    return;
  }

  final keyElement = XmlElement(XmlName('key'), [], [XmlText(key)]);
  final stringElement = XmlElement(XmlName('string'), [], [XmlText(message)]);

  dict.children.add(keyElement);
  dict.children.add(stringElement);

  await file.writeAsString(xmlDoc.toXmlString(pretty: true, indent: '  '));
  logger.i('✅ Added iOS permission "$key".');
}

/// Main CLI entry point to add permissions to Android and iOS projects.
///
/// Usage:
/// ```bash
/// dart run add_permission.dart camera
/// dart run add_permission.dart all
/// ```
void main(List<String> args) async {
  final logger = Logger();

  if (args.isEmpty) {
    logger.i(
        'Usage: add_permission <camera|microphone|location|storage|bluetooth|sensors|contacts|calendar|photos|notifications|speech|all>');
    exit(1);
  }

  logger.i('Adding permission_handler to pubspec.yaml...');
  final result =
      await Process.run('flutter', ['pub', 'add', 'permission_handler']);
  if (result.exitCode == 0) {
    logger.i('permission_handler added successfully.');
  } else {
    logger.i('Failed to add permission_handler: ${result.stderr}');
  }

  final projectRoot = Directory.current.path;
  await createPermissionHandlerFile(projectRoot, logger);

  final permission = args[0].toLowerCase();

  String appName = 'This app';
  final pubspecFile = File('pubspec.yaml');
  if (await pubspecFile.exists()) {
    final lines = await pubspecFile.readAsLines();
    final nameLine = lines.firstWhere(
      (line) => line.trim().startsWith('name:'),
      orElse: () => '',
    );
    if (nameLine.isNotEmpty) {
      appName = nameLine.split(':').last.trim();
    }
  }

  String getMessage(String feature, [int argIndex = -1]) {
    if (argIndex >= 0 &&
        args.length > argIndex &&
        args[argIndex].trim().isNotEmpty) {
      return args[argIndex];
    }
    return '$appName requires $feature access for proper functionality.';
  }

  Future<void> handle(String perm) async {
    switch (perm) {
      case 'camera':
        await addAndroidPermission('android.permission.CAMERA', logger);
        await addiOSPermission(
            'NSCameraUsageDescription', getMessage('camera'), logger);
        break;
      case 'microphone':
      case 'mic':
        await addAndroidPermission('android.permission.RECORD_AUDIO', logger);
        await addiOSPermission(
            'NSMicrophoneUsageDescription', getMessage('microphone'), logger);
        break;
      case 'location':
        await addAndroidPermission(
            'android.permission.ACCESS_FINE_LOCATION', logger);
        await addAndroidPermission(
            'android.permission.ACCESS_COARSE_LOCATION', logger);
        await addiOSPermission('NSLocationWhenInUseUsageDescription',
            getMessage('location'), logger);
        await addiOSPermission('NSLocationAlwaysAndWhenInUseUsageDescription',
            getMessage('location'), logger);
        break;
      case 'storage':
        // Legacy permissions for API < 30
        await addAndroidPermission(
            'android.permission.READ_EXTERNAL_STORAGE', logger);
        await addAndroidPermission(
            'android.permission.WRITE_EXTERNAL_STORAGE', logger);

        // Scoped media permissions introduced in Android 13 (API 33)
        await addAndroidPermission(
            'android.permission.READ_MEDIA_IMAGES', logger);
        await addAndroidPermission(
            'android.permission.READ_MEDIA_VIDEO', logger);
        await addAndroidPermission(
            'android.permission.READ_MEDIA_AUDIO', logger);
        break;
      case 'bluetooth':
        await addAndroidPermission(
            'android.permission.BLUETOOTH_CONNECT', logger);
        await addiOSPermission('NSBluetoothAlwaysUsageDescription',
            getMessage('Bluetooth'), logger);
        break;
      case 'sensors':
        await addAndroidPermission('android.permission.BODY_SENSORS', logger);
        await addiOSPermission(
            'NSMotionUsageDescription', getMessage('sensor data'), logger);
        break;
      case 'contacts':
        await addAndroidPermission('android.permission.READ_CONTACTS', logger);
        await addiOSPermission(
            'NSContactsUsageDescription', getMessage('contacts'), logger);
        break;
      case 'calendar':
        await addAndroidPermission('android.permission.READ_CALENDAR', logger);
        await addAndroidPermission('android.permission.WRITE_CALENDAR', logger);
        await addiOSPermission(
            'NSCalendarsUsageDescription', getMessage('calendar'), logger);
        break;
      case 'photos':
        await addiOSPermission('NSPhotoLibraryUsageDescription',
            getMessage('photo access'), logger);
        break;
      case 'notifications':
        // Android 13+ needs explicit POST_NOTIFICATIONS runtime permission
        await addAndroidPermission(
            'android.permission.POST_NOTIFICATIONS', logger);

        // On iOS permission key is unnecessary for push notifications, but we keep
        // the rationale as an accessibility description for older docs/macOS.
        await addiOSPermission('NSUserNotificationAlertUsageDescription',
            getMessage('notifications'), logger);
        break;
      case 'speech':
        await addiOSPermission('NSSpeechRecognitionUsageDescription',
            getMessage('speech recognition'), logger);
        break;
      default:
        logger.i('Permission "$perm" not supported.');
    }
  }

  try {
    if (permission == 'all') {
      final allPermissions = [
        'camera',
        'microphone',
        'location',
        'storage',
        'bluetooth',
        'sensors',
        'contacts',
        'calendar',
        'photos',
        'notifications',
        'speech'
      ];
      for (final p in allPermissions) {
        await handle(p);
      }
    } else {
      await handle(permission);
    }
  } catch (e) {
    logger.i('Error: $e');
  }
}
