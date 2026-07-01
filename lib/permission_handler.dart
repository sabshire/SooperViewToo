//permissions
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

class PermissionHandler {
  static Future<bool> hasNeededPermissions() async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;

    if (await Permission.manageExternalStorage.request().isGranted) {
      // Either the permission was already granted before or the user just granted it.
      return true;
    }

    if (await Permission.storage.request().isGranted) {
      // Either the permission was already granted before or the user just granted it.
      return true;
    }

    return false;
  }
}