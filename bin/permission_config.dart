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

void main(List<String> args, message) async {
  var logger = Logger();

  logger.d("Logger is working!");

  if (args.isEmpty) {
    logger.d('Usage: add_permission <camera|microphone|location>');
    exit(1);
  }
  // Add permission_handler to pubspec.yaml using flutter pub add
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
  // Fetch app name from pubspec.yaml
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

  try {
    if (permission == 'camera') {
      final message = (args.length > 1 && args[1].trim().isNotEmpty)
          ? args[1]
          : '$appName requires camera access for proper functionality.';
      await addAndroidPermission('android.permission.CAMERA', logger);
      await addiOSPermission('NSCameraUsageDescription', message, logger);
    } else if (permission == 'mic' || permission == 'microphone') {
      final message = (args.length > 1 && args[1].trim().isNotEmpty)
          ? args[1]
          : '$appName requires microphone access for proper functionality.';
      await addAndroidPermission('android.permission.RECORD_AUDIO', logger);
      await addiOSPermission('NSMicrophoneUsageDescription', message, logger);
    } else if (permission == 'location') {
      final message = (args.length > 1 && args[1].trim().isNotEmpty)
          ? args[1]
          : '$appName requires location access for proper functionality.';
      await addAndroidPermission(
          'android.permission.ACCESS_FINE_LOCATION', logger);
      await addAndroidPermission(
          'android.permission.ACCESS_COARSE_LOCATION', logger);
      await addiOSPermission(
          'NSLocationWhenInUseUsageDescription', message, logger);
      await addiOSPermission(
          'NSLocationAlwaysAndWhenInUseUsageDescription', message, logger);
    } else {
      logger.d('Permission "$permission" not supported yet.');
    }
  } catch (e) {
    logger.d('Error: $e');
  }
}
