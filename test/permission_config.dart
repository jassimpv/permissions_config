import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:logger/logger.dart';
import 'package:xml/xml.dart';
import '../bin/permission_config.dart';

void main() {
  late Directory tempDir;
  late Logger logger;

  setUp(() async {
    // Create a temporary directory for each test
    tempDir = await Directory.systemTemp.createTemp('permission_test_');
    logger = Logger(level: Level.off); // Disable logging during tests
  });

  tearDown(() async {
    // Clean up temporary directory after each test
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('createPermissionHandlerFile', () {
    test('should create Utils directory if it does not exist', () async {
      await createPermissionHandlerFile(tempDir.path, logger);

      final utilsDir = Directory(p.join(tempDir.path, 'lib', 'Utils'));
      expect(await utilsDir.exists(), isTrue);
    });

    test('should create permission_handler.dart file', () async {
      await createPermissionHandlerFile(tempDir.path, logger);

      final filePath =
          p.join(tempDir.path, 'lib', 'Utils', 'permission_handler.dart');
      final file = File(filePath);
      expect(await file.exists(), isTrue);

      final content = await file.readAsString();
      expect(content.contains('class PermissionUtils'), isTrue);
    });

    test('should skip creation if file already exists', () async {
      // First creation
      await createPermissionHandlerFile(tempDir.path, logger);

      final filePath =
          p.join(tempDir.path, 'lib', 'Utils', 'permission_handler.dart');
      final file = File(filePath);

      // Modify the file
      await file.writeAsString('// Modified content');

      // Second creation should not overwrite
      await createPermissionHandlerFile(tempDir.path, logger);

      final content = await file.readAsString();
      expect(content, equals('// Modified content'));
    });
  });

  group('backupFile', () {
    test('should create backup file if original exists', () async {
      final originalPath = p.join(tempDir.path, 'test_file.txt');
      final file = File(originalPath);
      await file.writeAsString('Original content');

      await backupFile(originalPath, logger);

      final backupFileInstance = File('$originalPath.bak');
      expect(await backupFileInstance.exists(), isTrue);
      expect(
          await backupFileInstance.readAsString(), equals('Original content'));
    });

    test('should not create backup if original does not exist', () async {
      final nonExistentPath = p.join(tempDir.path, 'non_existent.txt');

      await backupFile(nonExistentPath, logger);

      final backupFileInstance = File('$nonExistentPath.bak');
      expect(await backupFileInstance.exists(), isFalse);
    });

    test('should not overwrite existing backup', () async {
      final originalPath = p.join(tempDir.path, 'test_file.txt');
      final backupPath = '$originalPath.bak';

      // Create original and backup files
      await File(originalPath).writeAsString('Original content');
      await File(backupPath).writeAsString('Existing backup');

      await backupFile(originalPath, logger);

      final backupContent = await File(backupPath).readAsString();
      expect(backupContent, equals('Existing backup'));
    });
  });

  group('restoreBackup', () {
    test('should restore from backup if backup exists', () async {
      final originalPath = p.join(tempDir.path, 'test_file.txt');
      final backupPath = '$originalPath.bak';

      await File(originalPath).writeAsString('Modified content');
      await File(backupPath).writeAsString('Backup content');

      await restoreBackup(originalPath, logger);

      final restoredContent = await File(originalPath).readAsString();
      expect(restoredContent, equals('Backup content'));
    });

    test('should do nothing if backup does not exist', () async {
      final originalPath = p.join(tempDir.path, 'test_file.txt');
      await File(originalPath).writeAsString('Original content');

      await restoreBackup(originalPath, logger);

      final content = await File(originalPath).readAsString();
      expect(content, equals('Original content'));
    });
  });

  group('addAndroidPermission', () {
    late String manifestPath;

    setUp(() async {
      // Create directory structure for Android manifest
      final androidDir =
          Directory(p.join(tempDir.path, 'android', 'app', 'src', 'main'));
      await androidDir.create(recursive: true);
      manifestPath = p.join(androidDir.path, 'AndroidManifest.xml');

      // Create a basic AndroidManifest.xml
      final basicManifest = '''<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.test">
    
    <application
        android:label="test"
        android:name="\${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme">
        </activity>
    </application>
</manifest>''';

      await File(manifestPath).writeAsString(basicManifest);

      // Change working directory to tempDir for the function to find the manifest
      Directory.current = tempDir.path;
    });

    test('should add permission if not already present', () async {
      await addAndroidPermission('android.permission.CAMERA', logger);

      final manifestContent = await File(manifestPath).readAsString();
      final xmlDoc = XmlDocument.parse(manifestContent);

      final permissions = xmlDoc.findAllElements('uses-permission');
      final hasCamera = permissions.any(
          (e) => e.getAttribute('android:name') == 'android.permission.CAMERA');

      expect(hasCamera, isTrue);
    });

    test('should not duplicate permission if already present', () async {
      // Add permission twice
      await addAndroidPermission('android.permission.CAMERA', logger);
      await addAndroidPermission('android.permission.CAMERA', logger);

      final manifestContent = await File(manifestPath).readAsString();
      final xmlDoc = XmlDocument.parse(manifestContent);

      final cameraPermissions = xmlDoc
          .findAllElements('uses-permission')
          .where((e) =>
              e.getAttribute('android:name') == 'android.permission.CAMERA')
          .toList();

      expect(cameraPermissions.length, equals(1));
    });

    test('should handle missing AndroidManifest.xml gracefully', () async {
      await File(manifestPath).delete();

      // Should not throw an exception
      await addAndroidPermission('android.permission.CAMERA', logger);
    });

    test('should create backup before modifying', () async {
      await addAndroidPermission('android.permission.CAMERA', logger);

      final backupFileInstance = File('$manifestPath.bak');
      expect(await backupFileInstance.exists(), isTrue);
    });
  });

  group('addiOSPermission', () {
    late String plistPath;

    setUp(() async {
      // Create directory structure for iOS Info.plist
      final iosDir = Directory(p.join(tempDir.path, 'ios', 'Runner'));
      await iosDir.create(recursive: true);
      plistPath = p.join(iosDir.path, 'Info.plist');

      // Create a basic Info.plist
      final basicPlist = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleDisplayName</key>
	<string>Test App</string>
</dict>
</plist>''';

      await File(plistPath).writeAsString(basicPlist);

      // Change working directory to tempDir for the function to find the plist
      Directory.current = tempDir.path;
    });

    test('should add permission if not already present', () async {
      await addiOSPermission(
          'NSCameraUsageDescription', 'Camera access needed', logger);

      final plistContent = await File(plistPath).readAsString();
      final xmlDoc = XmlDocument.parse(plistContent);

      final keys = xmlDoc.findAllElements('key');
      final hasCamera =
          keys.any((e) => e.innerText == 'NSCameraUsageDescription');

      expect(hasCamera, isTrue);
    });

    test('should not duplicate permission if already present', () async {
      // Add permission twice
      await addiOSPermission(
          'NSCameraUsageDescription', 'Camera access needed', logger);
      await addiOSPermission(
          'NSCameraUsageDescription', 'Camera access needed', logger);

      final plistContent = await File(plistPath).readAsString();
      final xmlDoc = XmlDocument.parse(plistContent);

      final cameraKeys = xmlDoc
          .findAllElements('key')
          .where((e) => e.innerText == 'NSCameraUsageDescription')
          .toList();

      expect(cameraKeys.length, equals(1));
    });

    test('should handle missing Info.plist gracefully', () async {
      await File(plistPath).delete();

      // Should not throw an exception
      await addiOSPermission(
          'NSCameraUsageDescription', 'Camera access needed', logger);
    });

    test('should create backup before modifying', () async {
      await addiOSPermission(
          'NSCameraUsageDescription', 'Camera access needed', logger);

      final backupFileInstance = File('$plistPath.bak');
      expect(await backupFileInstance.exists(), isTrue);
    });
  });

  group('permission handling integration tests', () {
    late String manifestPath;
    late String plistPath;

    setUp(() async {
      // Set up both Android and iOS files
      final androidDir =
          Directory(p.join(tempDir.path, 'android', 'app', 'src', 'main'));
      await androidDir.create(recursive: true);
      manifestPath = p.join(androidDir.path, 'AndroidManifest.xml');

      final iosDir = Directory(p.join(tempDir.path, 'ios', 'Runner'));
      await iosDir.create(recursive: true);
      plistPath = p.join(iosDir.path, 'Info.plist');

      // Create basic files
      final basicManifest = '''<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.test">
    <application android:label="test"></application>
</manifest>''';

      final basicPlist = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDisplayName</key>
	<string>Test App</string>
</dict>
</plist>''';

      await File(manifestPath).writeAsString(basicManifest);
      await File(plistPath).writeAsString(basicPlist);

      Directory.current = tempDir.path;
    });

    test('should handle camera permission correctly', () async {
      await addAndroidPermission('android.permission.CAMERA', logger);
      await addiOSPermission(
          'NSCameraUsageDescription', 'Camera access needed', logger);

      // Verify Android
      final manifestContent = await File(manifestPath).readAsString();
      expect(manifestContent.contains('android.permission.CAMERA'), isTrue);

      // Verify iOS
      final plistContent = await File(plistPath).readAsString();
      expect(plistContent.contains('NSCameraUsageDescription'), isTrue);
      expect(plistContent.contains('Camera access needed'), isTrue);
    });

    test('should handle location permissions correctly', () async {
      await addAndroidPermission(
          'android.permission.ACCESS_FINE_LOCATION', logger);
      await addAndroidPermission(
          'android.permission.ACCESS_COARSE_LOCATION', logger);
      await addiOSPermission('NSLocationWhenInUseUsageDescription',
          'Location access needed', logger);

      final manifestContent = await File(manifestPath).readAsString();
      expect(manifestContent.contains('ACCESS_FINE_LOCATION'), isTrue);
      expect(manifestContent.contains('ACCESS_COARSE_LOCATION'), isTrue);

      final plistContent = await File(plistPath).readAsString();
      expect(
          plistContent.contains('NSLocationWhenInUseUsageDescription'), isTrue);
    });
  });

  group('XML parsing edge cases', () {
    test('should handle malformed AndroidManifest.xml', () async {
      final androidDir =
          Directory(p.join(tempDir.path, 'android', 'app', 'src', 'main'));
      await androidDir.create(recursive: true);
      final manifestPath = p.join(androidDir.path, 'AndroidManifest.xml');

      // Create malformed XML
      await File(manifestPath).writeAsString('<manifest><unclosed>');
      Directory.current = tempDir.path;

      // Should handle gracefully without throwing
      expect(() => addAndroidPermission('android.permission.CAMERA', logger),
          throwsA(isA<XmlException>()));
    });

    test('should handle AndroidManifest.xml without manifest element',
        () async {
      final androidDir =
          Directory(p.join(tempDir.path, 'android', 'app', 'src', 'main'));
      await androidDir.create(recursive: true);
      final manifestPath = p.join(androidDir.path, 'AndroidManifest.xml');

      // Create XML without manifest element
      await File(manifestPath)
          .writeAsString('<?xml version="1.0"?><root></root>');
      Directory.current = tempDir.path;

      // Should handle gracefully
      await addAndroidPermission('android.permission.CAMERA', logger);

      // Verify file wasn't modified
      final content = await File(manifestPath).readAsString();
      expect(content.contains('android.permission.CAMERA'), isFalse);
    });
  });
}
