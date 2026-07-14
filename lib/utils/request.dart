import 'package:get/get_rx/src/rx_typedefs/rx_typedefs.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:auralive/utils/utils.dart';

class AppRequest {
  static Future<void> notificationPermission({Callback? callback}) async {
    PermissionStatus status = await Permission.notification.status;

    if (status.isDenied) {
      PermissionStatus request = await Permission.notification.request();

      if (request != PermissionStatus.denied) {
        callback?.call();
        Utils.showLog("App Permission => Allow Notification");
      } else {
        Utils.showLog("App Permission => Denied Notification");
        Utils.showToast("Please allow notification permission !!");
      }
    } else {
      callback?.call();
      Utils.showLog("App Permission => Allow Notification");
    }
  }

  static Future<bool> storagePermission() async {
    PermissionStatus status = await Permission.storage.status;

    if (status.isDenied) {
      PermissionStatus request = await Permission.storage.request();

      if (request != PermissionStatus.denied) {
        Utils.showLog("App Permission => Allow Storage");
        return true;
      } else {
        Utils.showLog("App Permission => Denied Storage");
        Utils.showToast("Please allow storage permission !!");
        return false;
      }
    } else {
      Utils.showLog("App Permission => Allow Storage");
      return true;
    }
  }

  static Future<bool> microphonePermission() async {
    PermissionStatus status = await Permission.microphone.status;

    if (status.isDenied) {
      PermissionStatus request = await Permission.microphone.request();

      if (request != PermissionStatus.denied) {
        Utils.showLog("App Permission => Allow Microphone");
        return true;
      } else {
        Utils.showLog("App Permission => Denied Microphone");
        Utils.showToast("Please allow microphone permission !!");
        return false;
      }
    } else {
      Utils.showLog("App Permission => Allow Microphone");
      return true;
    }
  }

  static Future<bool> audioPermission() async {
    PermissionStatus status = await Permission.audio.status;

    if (status.isDenied) {
      PermissionStatus request = await Permission.audio.request();

      if (request != PermissionStatus.denied) {
        Utils.showLog("App Permission => Allow Audio");
        return true;
      } else {
        Utils.showLog("App Permission => Denied Audio");
        Utils.showToast("Please allow audio permission !!");
        return false;
      }
    } else {
      Utils.showLog("App Permission => Allow Audio");
      return true;
    }
  }

  static Future<void> cameraPermission({Callback? callback}) async {
    PermissionStatus status = await Permission.camera.request();
    status != PermissionStatus.denied ? callback?.call() : null;
  }

  static Future<bool> phonePermission({Callback? callback}) async {
    PermissionStatus status = await Permission.phone.status;

    if (status.isDenied) {
      PermissionStatus request = await Permission.phone.request();

      if (request != PermissionStatus.denied) {
        Utils.showLog("App Permission => Allow Phone");
        return true;
      } else {
        Utils.showLog("App Permission => Denied Phone");
        Utils.showToast("Please allow phone permission !!");
        return false;
      }
    } else {
      Utils.showLog("App Permission => Allow Phone");
      return true;
    }
  }

  static Future<void> requestLiveStreamingPermissions({Callback? onGranted}) async {
    bool mic = await microphonePermission();
    if (!mic) return;

    bool cam = false;
    await cameraPermission(callback: () {
      cam = true;
    });
    if (!cam) return;

    // REMOVED audioPermission() check here because READ_MEDIA_AUDIO was stripped 
    // from the Android Manifest to comply with Google Play Console requirements.

    // Optional: storage or phone, depending on your use case
    // bool store = await storagePermission();
    // if (!store) return;

    onGranted?.call(); // ✅ All required live streaming permissions granted
  }

}
