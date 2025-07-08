import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionUtils {
  /// Request the specified [permission].
  /// If denied, shows a dialog to inform user.
  /// If permanently denied, prompts to open app settings.
  static Future<bool> askPermission(
    BuildContext context,
    Permission permission, {
    String rationaleMessage = 'This permission is required to continue.',
  }) async {
    final status = await permission.status;

    if (status.isGranted) {
      return true; // Already granted
    }

    if (status.isDenied) {
      // Request permission
      final result = await permission.request();
      if (result.isGranted) {
        return true;
      } else if (result.isDenied) {
        // Show rationale dialog and ask again or cancel
        if(context.mounted){
        return await _showDeniedDialog(context, rationaleMessage);}
      } else if (result.isPermanentlyDenied) {
       if(context.mounted){
        return await _showOpenSettingsDialog(context);}
      }

    }

    if (status.isPermanentlyDenied) {
      // Permission permanently denied, ask to open settings 
      if(context.mounted){
      return await _showOpenSettingsDialog(context);}
      
    }

    return false;
  }

  static Future<bool> _showDeniedDialog(
      BuildContext context, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Permission Required'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Retry'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  static Future<bool> _showOpenSettingsDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
            'Permission permanently denied. Please open settings to grant it manually.'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Open Settings'),
            onPressed: () async {
              Navigator.of(context).pop(true);
              await openAppSettings();
            },
          ),
        ],
      ),
    );

    return result ?? false;
  }
}
