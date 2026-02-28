import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:auralive/custom/custom_thumbnail.dart';
import 'package:auralive/custom/custom_video_picker.dart';
import 'package:auralive/custom/custom_video_time.dart';
import 'package:auralive/ui/loading_ui.dart';
import 'package:auralive/main.dart';
import 'package:auralive/routes/app_routes.dart';
import 'package:auralive/utils/asset.dart';
import 'package:auralive/utils/color.dart';
import 'package:auralive/size_extension.dart';
import 'package:auralive/utils/enums.dart';
import 'package:auralive/utils/font_style.dart';
import 'package:auralive/utils/internet_connection.dart';
import 'package:auralive/utils/utils.dart';

class VideoPickerBottomSheetUi {
  static Future<void> show({required BuildContext context}) async {
    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: AppColor.transparent,
      builder: (context) => Container(
        height: 200, // You might want to reduce this height since there is only one option now (e.g., 150)
        width: Get.width,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(40),
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 65,
              color: AppColor.grey_100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 4,
                        width: 35,
                        decoration: BoxDecoration(
                          color: AppColor.colorTextDarkGrey,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      10.height,
                      Text(
                        EnumLocal.txtChooseVideo.name.tr,
                        style: AppFontStyle.styleW700(AppColor.black, 17),
                      ),
                    ],
                  ).paddingOnly(left: 50),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      height: 30,
                      width: 30,
                      margin: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColor.transparent,
                        border: Border.all(color: AppColor.black),
                      ),
                      child: Center(
                        child: Image.asset(
                          width: 18,
                          AppAsset.icClose,
                          color: AppColor.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            5.height,

            // ---------------------------------------------------------
            // UPLOAD OPTION
            // ---------------------------------------------------------
            
            GestureDetector(
                  onTap: () async {
                    // 1. Close the Bottom Sheet immediately
                    Get.back(); 

                    if (!InternetConnection.isConnect.value) {
                      Utils.showToast(EnumLocal.txtConnectionLost.name.tr);
                      return;
                    }

                    try {
                      // 2. Start Loading
                      Get.dialog(const LoadingUi(), barrierDismissible: false);

                      // 3. Pick the video
                      final videoPath = await CustomVideoPicker.pickVideo();

                      if (videoPath == null || videoPath.isEmpty) {
                        // User cancelled picking
                        if (Get.isOverlaysOpen) Get.back(); 
                        Utils.showLog("Video Selection Cancelled");
                        return;
                      }

                      // 4. Gather Metadata
                      final videoTime = await CustomVideoTime.onGet(videoPath);
                      final String? videoImage = await CustomThumbnail.onGet(videoPath);

                      // 5. Stop Loading before navigating or showing errors
                      if (Get.isOverlaysOpen) Get.back();

                      if (videoTime != null && videoImage != null) {
                        Get.toNamed(
                          AppRoutes.previewCreatedReelsPage,
                          arguments: {
                            "video": videoPath,
                            "image": videoImage,
                            "time": videoTime,
                            "songId": "",
                          },
                        );
                      } else {
                        Utils.showToast(EnumLocal.txtSomeThingWentWrong.name.tr);
                        Utils.showLog("Metadata extraction failed: Time=$videoTime, Image=$videoImage");
                      }
                    } catch (e) {
                      // Catch-all for unexpected errors (file permissions, etc.)
                      if (Get.isOverlaysOpen) Get.back();
                      Utils.showLog("Error during upload process: $e");
                      Utils.showToast(EnumLocal.txtSomeThingWentWrong.name.tr);
                    }
                  },
                child: Container(
                height: 55,
                color: AppColor.transparent,
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: 25),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(AppAsset.icGallery, color: AppColor.black, width: 26),
                    15.width,
                    Text(
                      EnumLocal.txtUpload.name.tr,
                      style: AppFontStyle.styleW700(AppColor.black, 17),
                    ),
                  ],
                ),
              ),
            ),
            
            

            // ✅ ONLY CREATE REEL OPTION REMAINS
            GestureDetector(
              onTap: () {
                Get.back();
                Get.toNamed(AppRoutes.createReelsPage);
              },
              child: Container(
                height: 55,
                color: AppColor.transparent,
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: 25),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(AppAsset.icCameraGradiant, color: AppColor.black, width: 26),
                    15.width,
                    Text(
                      EnumLocal.txtCreateReels.name.tr,
                      style: AppFontStyle.styleW700(AppColor.black, 17),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
