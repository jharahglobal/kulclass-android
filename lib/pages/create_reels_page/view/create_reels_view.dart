import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:auralive/ui/circle_icon_button_ui.dart';
import 'package:auralive/ui/preview_network_image_ui.dart';
import 'package:auralive/ui/app_button_ui.dart';
import 'package:auralive/ui/loading_ui.dart';
import 'package:auralive/pages/create_reels_page/controller/create_reels_controller.dart';
import 'package:auralive/pages/create_reels_page/widget/create_reels_widget.dart';
import 'package:auralive/utils/asset.dart';
import 'package:auralive/utils/color.dart';
import 'package:auralive/size_extension.dart';
import 'package:auralive/utils/enums.dart';
import 'package:auralive/utils/font_style.dart';

class CreateReelsView extends GetView<CreateReelsController> {
  const CreateReelsView({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: AppColor.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    // ✅ FORCE USE OF WithOutEffectUi (Standard Camera)
    return Scaffold(
      body: const WithOutEffectUi(),
    );
  }
}

class WithOutEffectUi extends StatelessWidget {
  const WithOutEffectUi({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height,
      width: Get.width,
      color: AppColor.colorGreyBg,
      child: Stack(
        children: [
          // LAYER 1: FIXED CAMERA PREVIEW
          GetBuilder<CreateReelsController>(
            id: "onInitializeCamera",
            builder: (controller) {
              if (controller.cameraController != null && controller.cameraController!.value.isInitialized) {
                // Calculation to ensure 9:16 aspect ratio fill without stretching
                var camera = controller.cameraController!.value;
                final size = MediaQuery.of(context).size;
                var scale = size.aspectRatio * camera.aspectRatio;
                if (scale < 1) scale = 1 / scale;

                return ClipRect(
                  child: Container(
                    width: size.width,
                    height: size.height,
                    child: Transform.scale(
                      scale: scale,
                      child: Center(
                        child: CameraPreview(controller.cameraController!),
                      ),
                    ),
                  ),
                );
              } else if (controller.isCameraError) {
                return _buildErrorUi(controller);
              } else {
                return const LoadingUi();
              }
            },
          ),

          // ------------------------------------------------
          // LAYER 2: VISUAL GRADIENTS
          // ------------------------------------------------
          Positioned(
            top: 0,
            child: Container(
              height: 100,
              width: Get.width,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColor.black.withOpacity(0.7), AppColor.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: Container(
              height: 350,
              width: Get.width,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColor.transparent, AppColor.black.withOpacity(0.6), AppColor.black.withOpacity(0.8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // ------------------------------------------------
          // LAYER 3: PROGRESS BAR (TIMER)
          // ------------------------------------------------
          Positioned(
            top: 35,
            child: GetBuilder<CreateReelsController>(
              id: "onChangeRecordingEvent",
              builder: (controller) => Visibility(
                visible: controller.isRecording != "stop",
                child: SizedBox(
                  width: Get.width,
                  child: GetBuilder<CreateReelsController>(
                    id: "onChangeTimer",
                    builder: (controller) => Container(
                      height: 6,
                      width: Get.width,
                      margin: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppColor.white.withOpacity(0.6),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedContainer(
                          duration: const Duration(seconds: 1),
                          height: 6,
                          width: controller.countTime * ((Get.width - 30) / controller.selectedDuration),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: AppColor.primaryLinearGradient,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ------------------------------------------------
          // LAYER 4: SELECTED MUSIC DISPLAY
          // ------------------------------------------------
          Positioned(
            top: 60,
            child: GetBuilder<CreateReelsController>(
              id: "onChangeSound",
              builder: (controller) => Visibility(
                visible: controller.selectedSound != null,
                child: SizedBox(
                  width: Get.width,
                  child: Center(
                    child: SizedBox(
                      width: Get.width / 2,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 35,
                            width: 35,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: AppColor.white,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Image.asset(AppAsset.icImagePlaceHolder, height: 25),
                                AspectRatio(
                                  aspectRatio: 1,
                                  child: PreviewNetworkImageUi(image: controller.selectedSound?["image"]),
                                ),
                              ],
                            ),
                          ),
                          10.width,
                          Flexible(
                            fit: FlexFit.loose,
                            child: Text(
                              controller.selectedSound?["name"] ?? "",
                              maxLines: 2,
                              style: AppFontStyle.styleW500(AppColor.white, 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ------------------------------------------------
          // LAYER 5: RIGHT SIDE BUTTONS (Close, Flash, Flip, Music)
          // ------------------------------------------------
          Positioned(
            top: 65,
            child: SizedBox(
              width: Get.width,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CircleIconButtonUi(
                      circleSize: 40,
                      iconSize: 20,
                      color: AppColor.white.withOpacity(0.15),
                      icon: AppAsset.icClose,
                      iconColor: AppColor.white,
                      callback: () {
                        Get.back();
                      },
                    ),
                    20.height,
                    GetBuilder<CreateReelsController>(
                      id: "onSwitchFlash",
                      builder: (controller) => CircleIconButtonUi(
                        circleSize: 40,
                        iconSize: 20,
                        gradient: AppColor.primaryLinearGradient,
                        icon: controller.isFlashOn ? AppAsset.icFlashOn : AppAsset.icFlashOff,
                        iconColor: AppColor.white,
                        callback: controller.onSwitchFlash,
                      ),
                    ),
                    20.height,
                    GetBuilder<CreateReelsController>(
                      builder: (controller) => CircleIconButtonUi(
                        circleSize: 40,
                        iconSize: 20,
                        gradient: AppColor.primaryLinearGradient,
                        icon: AppAsset.icRotateCamera,
                        iconColor: AppColor.white,
                        callback: controller.onSwitchCamera,
                      ),
                    ),
                    20.height,
                    CircleIconButtonUi(
                      circleSize: 40,
                      iconSize: 17,
                      gradient: AppColor.primaryLinearGradient,
                      padding: const EdgeInsets.only(right: 2),
                      icon: AppAsset.icMusic,
                      iconColor: AppColor.white,
                      callback: () {
                        AddMusicBottomSheet.show(context: context);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ------------------------------------------------
          // LAYER 6: RECORDING DURATION SELECTOR (15s, 30s...)
          // ------------------------------------------------
          Positioned(
            bottom: 125,
            child: GetBuilder<CreateReelsController>(
              id: "onChangeRecordingEvent",
              builder: (controller) => Visibility(
                visible: controller.isRecording == "stop",
                child: Container(
                  height: 43,
                  width: Get.width,
                  color: AppColor.transparent,
                  child: Center(
                    child: GetBuilder<CreateReelsController>(
                      id: "onChangeRecordingDuration",
                      builder: (logic) => SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(left: 15),
                        child: Row(
                          children: List.generate(logic.recordingDurations.length, (index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 15),
                              child: GestureDetector(
                                onTap: () => logic.onChangeRecordingDuration(index),
                                child: Container(
                                  height: 20,
                                  width: 65,
                                  decoration: BoxDecoration(
                                    gradient: logic.selectedDuration == logic.recordingDurations[index] ? AppColor.primaryLinearGradient : null,
                                    color: logic.selectedDuration == logic.recordingDurations[index] ? null : AppColor.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "${logic.recordingDurations[index]}s",
                                      style: AppFontStyle.styleW500(AppColor.white, 14.5),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ------------------------------------------------
          // LAYER 7: RECORD BUTTON & PREVIEW BUTTON
          // ------------------------------------------------
          Positioned(
            bottom: 20,
            child: Container(
              width: Get.width,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  const Expanded(child: SizedBox()), // Cleaned up Offstage
                  Expanded(
                    child: _buildRecordButton(),
                  ),
                  Expanded(
                    child: GetBuilder<CreateReelsController>(
                      id: "onChangeRecordingEvent",
                      builder: (controller) => Visibility(
                        // Ensure preview button appears immediately after a recording exists
                        visible: controller.isRecording != "stop" || controller.recordedVideoPath != null, 
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () => controller.onClickPreviewButton(),
                            child: Container(
                              height: 43,
                              width: 111,
                              decoration: BoxDecoration(
                                gradient: AppColor.primaryLinearGradient,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Center(
                                child: Text(
                                  EnumLocal.txtPreview.name.tr,
                                  style: AppFontStyle.styleW600(AppColor.white, 16),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildRecordButton() {
    return GetBuilder<CreateReelsController>(
      id: "onChangeRecordingEvent",
      builder: (controller) => Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 73,
            width: 73,
            child: CircularProgressIndicator(
              value: controller.isRecording == "stop" ? 0 : controller.countTime / controller.selectedDuration,
              backgroundColor: AppColor.white.withOpacity(0.2),
              color: AppColor.colorTabBar,
              strokeWidth: 6,
            ),
          ),
          CircleIconButtonUi(
            circleSize: 65,
            icon: controller.isRecording == "start" ? AppAsset.icPause : AppAsset.icPlay,
            iconSize: 35,
            color: AppColor.white,
            gradient: controller.isRecording == "stop" ? AppColor.primaryLinearGradient : null,
            iconColor: controller.isRecording == "stop" ? AppColor.white : AppColor.black,
            callback: () => controller.onClickRecordingButton(),
          )
        ],
      ),
    );
  }

// Add this inside class WithOutEffectUi
  Widget _buildErrorUi(CreateReelsController controller) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.videocam_off, color: AppColor.white, size: 50),
        const SizedBox(height: 10),
        // Ensure AppButtonUi is imported at the top of the file
        AppButtonUi(
          title: "Try Again",
          callback: () => controller.initCamera(),
        ),
      ],
    ),
  );
}
  
}

class _MediaSizeClipper extends CustomClipper<Rect> {
  final Size mediaSize;
  const _MediaSizeClipper(this.mediaSize);
  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, mediaSize.width, mediaSize.height);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return true;
  }
}
