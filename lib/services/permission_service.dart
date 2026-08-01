import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<void> requestAll() async {
    await [
      Permission.camera,
      Permission.microphone,
      Permission.location,
      Permission.phone,
    ].request();

    if (Platform.isAndroid) {
      await requestManageStorage();
    }
  }

  static Future<bool> requestManageStorage() async {
    if (!await Permission.manageExternalStorage.isGranted) {
      final status = await Permission.manageExternalStorage.request();
      return status.isGranted;
    }
    return true;
  }

  static Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> requestMicrophone() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  static Future<bool> requestLocation() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  static Future<bool> requestPhone() async {
    final status = await Permission.phone.request();
    return status.isGranted;
  }
}
