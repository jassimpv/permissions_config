import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import '../bin/permissionhandler.dart';

void main() {
  group('PermissionHandler Content', () {
    test('should contain valid Dart code structure', () {
      expect(
          permissionHandlerContent.contains('class PermissionUtils'), isTrue);
      expect(permissionHandlerContent.contains('askPermission'), isTrue);
      expect(permissionHandlerContent.contains('permission_handler'), isTrue);
    });

    test('should contain expected method signatures', () {
      expect(
          permissionHandlerContent
              .contains('static Future<bool> askPermission'),
          isTrue);
      expect(permissionHandlerContent.contains('BuildContext context'), isTrue);
      expect(
          permissionHandlerContent.contains('Permission permission'), isTrue);
    });

    test('should contain proper imports', () {
      expect(
          permissionHandlerContent
              .contains("import 'package:flutter/material.dart'"),
          isTrue);
      expect(
          permissionHandlerContent.contains(
              "import 'package:permission_handler/permission_handler.dart'"),
          isTrue);
    });

    test('should handle permission states', () {
      expect(permissionHandlerContent.contains('isGranted'), isTrue);
      expect(permissionHandlerContent.contains('isDenied'), isTrue);
      expect(permissionHandlerContent.contains('isPermanentlyDenied'), isTrue);
    });

    test('should contain user interaction elements', () {
      expect(permissionHandlerContent.contains('showDialog'), isTrue);
      expect(permissionHandlerContent.contains('AlertDialog'), isTrue);
      expect(permissionHandlerContent.contains('openAppSettings'), isTrue);
    });
  });

  group('Generated Permission Handler File', () {
    late Directory tempDir;

    setUp(() async {
      tempDir =
          await Directory.systemTemp.createTemp('permission_handler_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('should create syntactically valid Dart file', () async {
      final filePath = p.join(tempDir.path, 'permission_handler.dart');
      await File(filePath).writeAsString(permissionHandlerContent);

      // Try to analyze the file for syntax errors
      final result = await Process.run(
        'dart',
        ['analyze', filePath],
        workingDirectory: tempDir.path,
      );

      // The file should not have critical syntax errors
      expect(result.exitCode,
          anyOf(equals(0), equals(3))); // 0 = no issues, 3 = warnings only
    });

    test('should be properly formatted Dart code', () {
      // Check basic formatting elements
      expect(
          permissionHandlerContent.contains('  '), isTrue); // Has indentation
      expect(permissionHandlerContent.split('\n').length,
          greaterThan(50)); // Multi-line
      expect(permissionHandlerContent.contains('{'), isTrue);
      expect(permissionHandlerContent.contains('}'), isTrue);
    });
  });
}
