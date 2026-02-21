import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionManager {
  static Future<bool> requestStorage() async {
    // TODO use another, more privccy friendly permission?
    // Like this? https://developer.android.com/training/data-storage/shared/documents-files
    try {
      final status = await Permission.manageExternalStorage.request();
      return status.isGranted;
    } on MissingPluginException catch (e) {
      // No implementation found for method requestPermissions on channel ??
      // Happens on linux.
      Logger.root.warning(e);
      return true;
    }
  }

  // if (await Permission.manageExternalStorage.isPermanentlyDenied) {
  //   openAppSettings();
  // }
}
