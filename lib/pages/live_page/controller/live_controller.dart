import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:auralive/pages/connection_page/api/follow_unfollow_api.dart';
import 'package:auralive/ui/loading_ui.dart';
import 'package:auralive/utils/database.dart';
import 'package:auralive/utils/enums.dart';
import 'package:auralive/utils/socket_services.dart';
import 'package:auralive/utils/utils.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

class LiveController extends GetxController {
  bool isFrontCamera = false;
  bool isFlashOn = false;
  bool isMicOn = true;

  String userId = "";
  String image = "";
  String name = "";
  String userName = "";
  bool isFollow = false;
  bool isProfileImageBanned = false;

  int countTime = 0;
  bool isLivePage = false;

  TextEditingController commentController = TextEditingController();


 
  // ==========================================================
  // ADD THIS ONINIT INITIALIZATION BLOCK TO FIX ZEGO STORAGE ERROR
  // ==========================================================
  @override
  void onInit() {
    super.onInit();
    
    // Unpack incoming route parameters safely while the controller boots
    if (Get.arguments != null) {
      userId = Get.arguments["userId"] ?? "";
      image = Get.arguments["image"] ?? "";
      name = Get.arguments["name"] ?? "";
      userName = Get.arguments["userName"] ?? "";
      isFollow = Get.arguments["isFollow"] ?? false;
    }
  }

  @override
  void onReady() {
    super.onReady();
    
    // Initialize Zego configurations safely after the screen layout finishes rendering
    initZegoSafeSettings();

    // Start tracking live room time metrics
    onChangeTime();
  }

  Future<void> initZegoSafeSettings() async {
    try {
      // Configure Zego logger to write directly to clean app-private sandboxed memory arrays
      ZegoLogConfig logConfig = ZegoLogConfig("", 0);
      
      ZegoEngineConfig config = ZegoEngineConfig();
      config.logConfig = logConfig;
      
      await ZegoExpressEngine.setEngineConfig(config);
      Utils.showLog("Zego storage engine configurations bypassed safely on layout ready.");
    } catch (e) {
      Utils.showLog("Zego config error caught: $e");
    }
  }
 

  
  Future<void> onSwitchMic() async {
    isMicOn = !isMicOn;
    ZegoExpressEngine.instance.enableAudioCaptureDevice(isMicOn);
    update(["onSwitchMic"]);
  }

  

  Future<void> onSwitchCamera() async {
    Get.dialog(const LoadingUi(), barrierDismissible: false); // Start Loading...
    if (isFrontCamera) {
      ZegoExpressEngine.instance.useFrontCamera(isFrontCamera);
      isFrontCamera = !isFrontCamera;
      await 200.milliseconds.delay();
      ZegoExpressEngine.instance.useFrontCamera(isFrontCamera);
    } else {
      ZegoExpressEngine.instance.useFrontCamera(isFrontCamera);
      isFrontCamera = !isFrontCamera;
      await 200.milliseconds.delay();
      ZegoExpressEngine.instance.useFrontCamera(isFrontCamera);
    }
    Get.back(); // Stop Loading...
  }

  Future<void> onSendComment() async {
    if (commentController.text.trim().isNotEmpty) {
      SocketServices.onLiveChat(
        loginUserId: Database.fetchLoginUserProfileModel?.user?.id ?? "",
        liveHistoryId: Get.arguments["roomId"],
        userName: Database.fetchLoginUserProfileModel?.user?.name ?? "",
        userImage: Database.fetchLoginUserProfileModel?.user?.image ?? "",
        commentText: commentController.text,
      );
      commentController.clear();
    }
  }

  Future<void> onClickFollow() async {
    if (userId != Database.loginUserId) {
      isFollow = !isFollow;
      update(["onClickFollow"]);
      await FollowUnfollowApi.callApi(loginUserId: Database.loginUserId, userId: userId);
    } else {
      Utils.showToast(EnumLocal.txtYouCantFollowYourOwnAccount.name.tr);
    }
  }

  void onChangeTime() {
    isLivePage = true;

    Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (isLivePage) {
          countTime++;
          Utils.showLog("Live Streaming Time => ${onConvertSecondToHMS(countTime)}");
          update(["onChangeTime"]);
        } else {
          timer.cancel();
          countTime = 0;
          update(["onChangeTime"]);
        }
      },
    );
  }

  String onConvertSecondToHMS(int totalSeconds) {
    Duration duration = Duration(seconds: totalSeconds);

    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    int seconds = duration.inSeconds.remainder(60);

    String time = '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';

    return time;
  }
}
