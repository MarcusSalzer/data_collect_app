import 'package:permission_handler/permission_handler.dart';

class PermissionManager {
  static Future<bool> requestStorage() async {
    // TODO use another, more privccy friendly permission?
    // Like this? https://developer.android.com/training/data-storage/shared/documents-files
    final status = await Permission.manageExternalStorage.request();
    return status.isGranted;
  }

  // if (await Permission.manageExternalStorage.isPermanentlyDenied) {
  //   openAppSettings();
  // }
}
