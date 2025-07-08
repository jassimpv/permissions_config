import 'dart:io';
import 'package:xml/xml.dart';
import 'package:path/path.dart' as p;
import 'permissionhandler.dart';
import 'package:logger/logger.dart';

const androidManifestPath = 'android/app/src/main/AndroidManifest.xml';
const iosPlistPath = 'ios/Runner/Info.plist';

Future<void> createPermissionHandlerFile(
    String projectRoot, Logger logger) async {
  final utilsDir = Directory(p.join(projectRoot, 'lib', 'Utils'));

  if (!await utilsDir.exists()) {
    await utilsDir.create(recursive: true);
    logger.d('Created folder: ${utilsDir.path}');
  }

  final filePath = p.join(utilsDir.path, 'permission_handler.dart');
  final file = File(filePath);

  if (await file.exists()) {
    logger.d('File already exists at $filePath, skipping creation.');
    return;
  }

  await file.writeAsString(permissionHandlerContent);
  logger.d('Created permission_handler.dart at $filePath');
}

// Backup file utility
Future<void> backupFile(String path, Logger logger) async {
  final file = File(path);
  if (await file.exists()) {
    final backupPath = '$path.bak';
    final backupFile = File(backupPath);
    if (!await backupFile.exists()) {
      await file.copy(backupPath);
      logger.d('Backup created at $backupPath');
    }
  }
}

// Restore backup utility
Future<void> restoreBackup(String path, Logger logger) async {
  final backupPath = '$path.bak';
  final backupFile = File(backupPath);
  if (await backupFile.exists()) {
    await backupFile.copy(path);
    logger.d('Restored $path from backup.');
  }
}

// Add Android permission safely
Future<void> addAndroidPermission(String permissionName, Logger logger) async {
  final file = File(androidManifestPath);
  if (!await file.exists()) {
    logger.d('AndroidManifest.xml not found at $androidManifestPath');
    return;
  }

  await backupFile(androidManifestPath, logger);

  final xmlDoc = XmlDocument.parse(await file.readAsString());

  final manifest = xmlDoc.getElement('manifest');
  if (manifest == null) {
    logger.d('Error: <manifest> element not found in AndroidManifest.xml');
    return;
  }

  final existing = xmlDoc
      .findAllElements('uses-permission')
      .any((e) => e.getAttribute('android:name') == permissionName);

  if (existing) {
    logger.d('✔️ Android permission "$permissionName" already present.');
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
  logger.d('✅ Added Android permission "$permissionName".');
}

// Add iOS permission safely (using XML parsing)

Future<void> addiOSPermission(String key, String message, Logger logger) async {
  final file = File(iosPlistPath);
  if (!await file.exists()) {
    logger.d('Info.plist not found at $iosPlistPath');
    return;
  }

  await backupFile(iosPlistPath, logger);

  final contents = await file.readAsString();
  final xmlDoc = XmlDocument.parse(contents);

  final dict = xmlDoc.findAllElements('dict').first;

  // Check if the key already exists
  final keys = dict.findElements('key').map((e) => e.text).toList();
  if (keys.contains(key)) {
    logger.d('✔️ iOS permission "$key" already present.');
    return;
  }

  // Create new key and string elements
  final keyElement = XmlElement(XmlName('key'), [], [XmlText(key)]);
  final stringElement = XmlElement(XmlName('string'), [], [XmlText(message)]);

  // Insert before the closing </dict> tag
  // In XML DOM, append to the dict's children
  dict.children.add(keyElement);
  dict.children.add(stringElement);

  await file.writeAsString(xmlDoc.toXmlString(pretty: true, indent: '  '));
  logger.d('✅ Added iOS permission "$key".');
}

void main(List<String> args) async {
  final logger = Logger();

  if (args.isEmpty) {
    logger.d(
        'Usage: add_permission <camera|microphone|location|storage|bluetooth|sensors|contacts|calendar|photos|notifications|speech|all>');
    exit(1);
  }

  logger.d('Adding permission_handler to pubspec.yaml...');
  final result =
      await Process.run('flutter', ['pub', 'add', 'permission_handler']);
  if (result.exitCode == 0) {
    logger.d('permission_handler added successfully.');
  } else {
    logger.d('Failed to add permission_handler: ${result.stderr}');
  }

  final projectRoot = Directory.current.path;
  await createPermissionHandlerFile(projectRoot, logger);

  final permission = args[0].toLowerCase();

  // Get app name
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
        await addAndroidPermission(
            'android.permission.READ_EXTERNAL_STORAGE', logger);
        await addAndroidPermission(
            'android.permission.WRITE_EXTERNAL_STORAGE', logger);
        // No iOS permission required for storage
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
        await addiOSPermission('NSUserNotificationAlertUsageDescription',
            getMessage('notifications'), logger);
        break;
      case 'speech':
        await addiOSPermission('NSSpeechRecognitionUsageDescription',
            getMessage('speech recognition'), logger);
        break;
      default:
        logger.d('Permission "$perm" not supported.');
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
    logger.d('Error: $e');
  }
}
