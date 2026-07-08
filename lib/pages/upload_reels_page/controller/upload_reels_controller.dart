import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:dio/dio.dart' as dio_lib;

import 'package:ffmpeg_kit_16kb/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_16kb/return_code.dart';
import 'package:ffmpeg_kit_16kb/ffmpeg_session.dart';
import 'package:ffmpeg_kit_16kb/statistics.dart';

import 'package:get_thumbnail_video/video_thumbnail.dart'; 
import 'package:path_provider/path_provider.dart';      

import 'package:auralive/custom/custom_image_picker.dart';
import 'package:auralive/pages/preview_hash_tag_page/api/create_hash_tag_api.dart';
import 'package:auralive/pages/preview_hash_tag_page/api/fetch_hash_tag_api.dart';
import 'package:auralive/pages/preview_hash_tag_page/model/create_hash_tag_model.dart';
import 'package:auralive/pages/preview_hash_tag_page/model/fetch_hash_tag_model.dart';
import 'package:auralive/pages/profile_page/api/delete_content_api.dart';
import 'package:auralive/pages/upload_reels_page/api/upload_reels_api.dart';
import 'package:auralive/pages/upload_reels_page/model/upload_reels_model.dart';
import 'package:auralive/ui/image_picker_bottom_sheet_ui.dart';
import 'package:auralive/ui/loading_ui.dart';
import 'package:auralive/utils/database.dart';
import 'package:auralive/utils/enums.dart';
import 'package:auralive/utils/internet_connection.dart';
import 'package:auralive/utils/utils.dart';
import 'package:auralive/utils/color.dart';      
import 'package:auralive/utils/font_style.dart'; 
import 'package:auralive/routes/app_routes.dart';

class UploadReelsController extends GetxController {
  UploadReelsModel? uploadReelsModel;
  String? videoThumbnailUrl;

  int videoTime = 0;
  String videoPath = "";
  String videoThumbnail = "";
  String songId = "";

  TextEditingController captionController = TextEditingController();

  FetchHashTagModel? fetchHashTagModel;
  CreateHashTagModel? createHashTagModel;

  bool isLoadingHashTag = false;
  List<HashTagData> hastTagCollection = [];
  List<HashTagData> filterHashtag = [];

  RxBool isShowHashTag = false.obs;
  List<String> userInputHashtag = [];

  bool isVideoUploadSuccess = false;
  RxString uploadProgressPercentage = "0%".obs;
  RxDouble uploadProgress = 0.0.obs;
  
  // Subscription handler tracking compression metrics out-of-thread
   

  @override
  void onInit() {
    init();
    Utils.showLog("Upload Reels Controller Initialized...");
    super.onInit();
  }

  @override
  void onClose() { 
    onCancelVideoContent();
    super.onClose();
  }

  Future<void> init() async {
    final arguments = Get.arguments;

    Utils.showLog("Selected Video => $arguments");

    videoPath = arguments["video"] ?? "";
    videoThumbnail = arguments["image"] ?? "";
    videoTime = arguments["time"] ?? 0;
    songId = arguments["songId"] ?? "";

    if (videoPath.isNotEmpty) {
      bool isThumbValid = false;
      if (videoThumbnail.isNotEmpty) {
        isThumbValid = await File(videoThumbnail).exists();
      }

      if (!isThumbValid) {
        Utils.showLog("⚠️ Thumbnail missing. Generating with VideoThumbnail...");
        try {
          final thumbFile = await VideoThumbnail.thumbnailFile(
            video: videoPath,
            thumbnailPath: (await getTemporaryDirectory()).path,
            maxHeight: 500,
            quality: 75,
          );

          if (thumbFile != null && thumbFile.path.isNotEmpty) {
            videoThumbnail = thumbFile.path;
            Utils.showLog("✅ New Thumbnail Generated: $videoThumbnail");
          } else {
            Utils.showLog("❌ Failed to generate thumbnail");
          }
        } catch (e) {
          Utils.showLog("❌ Error generating thumbnail: $e");
        }
      }
    }

    onGetHashTag();
    Utils.showLog("Selected Song Id => $songId");
    
    videoThumbnailUrl = videoThumbnail;
    update(["onChangeThumbnail"]);
  }

  void onCancelVideoContent() {
    if (isVideoUploadSuccess == false && videoThumbnailUrl?.trim().isNotEmpty == true) {
      // No action needed as file is local
    }
  }

  Future<void> onGetHashTag() async {
    fetchHashTagModel = null;
    isLoadingHashTag = true;
    update(["onGetHashTag"]);
    fetchHashTagModel = await FetchHashTagApi.callApi(hashTag: "");

    if (fetchHashTagModel?.data != null) {
      hastTagCollection.clear();
      hastTagCollection.addAll(fetchHashTagModel?.data ?? []);
      Utils.showLog("Hast Tag Collection Length => ${hastTagCollection.length}");
    }
    isLoadingHashTag = false;
    update(["onGetHashTag"]);
  }

  void onSelectHashtag(int index) {
    String text = captionController.text;
    List<String> words = text.split(' ');
    words.removeLast();
    captionController.text = words.join(' ');
    captionController.text = captionController.text + ' ' + ("#${filterHashtag[index].hashTag} ");
    captionController.selection = TextSelection.fromPosition(TextPosition(offset: captionController.text.length));
    isShowHashTag.value = false;
    update(["onChangeHashtag"]);
  }

  void onChangeHashtag() async {
    String text = captionController.text;
    List<String> words = text.split(' ');
    for (int i = 0; i < words.length; i++) {
      if (words[i].length > 1 && words[i].indexOf('#') == words[i].lastIndexOf('#')) {
        if (words[i].endsWith('#')) {
          words[i] = words[i].replaceFirst('#', ' #');
        }
      }
    }
    captionController.text = words.join(' ');
    captionController.selection = TextSelection.fromPosition(
      TextPosition(offset: captionController.text.length),
    );

    String updatedText = captionController.text;
    List<String> parts = updatedText.split(' ');

    await 10.milliseconds.delay();

    final caption = parts.where((element) => !element.startsWith('#')).join(' ');
    userInputHashtag = parts.where((element) => element.startsWith('#')).toList();
    final lastWord = parts.last;

    if (lastWord.startsWith("#")) {
      final searchHashtag = lastWord.substring(1);
      filterHashtag = hastTagCollection.where((element) => (element.hashTag?.toLowerCase() ?? "").contains(searchHashtag.toLowerCase())).toList();
      isShowHashTag.value = true;
      update(["onGetHashTag"]);
    } else {
      filterHashtag.clear();
      isShowHashTag.value = false;
    }
    update(["onChangeHashtag"]);
  }

  void onToggleHashTag(bool value) {
    isShowHashTag.value = value;
  }

  Future<void> onChangeThumbnail(BuildContext context) async {
    await ImagePickerBottomSheetUi.show(
      context: context,
      onClickCamera: () async {
        final imagePath = await CustomImagePicker.pickImage(ImageSource.camera);
        if (imagePath != null) {
          videoThumbnail = imagePath;
          videoThumbnailUrl = videoThumbnail;
          update(["onChangeThumbnail"]);
        }
      },
      onClickGallery: () async {
        final imagePath = await CustomImagePicker.pickImage(ImageSource.gallery);
        if (imagePath != null) {
          videoThumbnail = imagePath;
          videoThumbnailUrl = videoThumbnail;
          update(["onChangeThumbnail"]);
        }
      },
    );
  }

  Future<void> onUploadReels() async {
    Utils.showLog("Reels Uploading Process Started...");
    if (InternetConnection.isConnect.value) {
      
      uploadProgress.value = 0.0;
      uploadProgressPercentage.value = "Preparing video...";
      
      Get.dialog(
        PopScope(
          canPop: false, 
          child: AlertDialog(
            backgroundColor: AppColor.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            // progress
            content: SizedBox(
  width: 300,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [

      const CupertinoActivityIndicator(radius: 15),

      const SizedBox(height: 20),

      Obx(() => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: uploadProgress.value,
          minHeight: 8,
        ),
      )),

      const SizedBox(height: 15),

      Obx(() => Text(
        uploadProgressPercentage.value,
        style: AppFontStyle.styleW600(AppColor.black, 15),
        textAlign: TextAlign.center,
      )),

    ],
  ),
),
            // end progress
          )
        ), 
        barrierDismissible: false
      );

      String finalVideoPath = videoPath;

      // --- VIDEO COMPRESSION START ---
    

  // ---------------- VIDEO COMPRESSION ----------------

if (videoPath.isNotEmpty && File(videoPath).existsSync()) {
  try {
    final originalSize = File(videoPath).lengthSync();

    Utils.showLog(
      "Original Size: ${(originalSize / (1024 * 1024)).toStringAsFixed(2)} MB",
    );

    uploadProgressPercentage.value = "Compressing video...";

    final tempDir = await getTemporaryDirectory();

    final compressedPath =
        "${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.mp4";

    // --- Encoder start---

  FFmpegSession? session;

final completer = Completer<void>();

session = await FFmpegKit.executeAsync(
  '-y '
  '-i "$videoPath" '
  '-c:v mpeg4 '
  '-qscale:v 5 '
  '-c:a aac '
  '-b:a 128k '
  '"$compressedPath"',

  (session) async {
    completer.complete();
  },

  null,

  (statistics) {
    final currentTime = statistics.getTime();

    if (videoTime > 0) {
      
       final progress =
    (currentTime / (videoTime * 1000)).clamp(0.0, 1.0);

uploadProgress.value = progress * 0.70;

uploadProgressPercentage.value =
    "Compressing ${(progress * 100).toStringAsFixed(0)}%";

      
    }
  },
);
    await completer.future;
    uploadProgress.value = 0.70;
uploadProgressPercentage.value = "Compression complete";
    // --- Encoder Ends ---

    final returnCode = await session.getReturnCode();
    final logs = await session.getLogsAsString();
 

    if (!ReturnCode.isSuccess(returnCode)) {
      Utils.showLog("========== FFMPEG FAILED ==========");
      Utils.showLog(logs);

      Get.back();

      Utils.showToast(
        "Video compression failed.\n\n$logs",
      );

      return;
    }

    if (!File(compressedPath).existsSync()) {
      Get.back();

      Utils.showToast(
          "Compression failed.\nCompressed video was not created.");

      return;
    }

    final compressedSize = File(compressedPath).lengthSync();

    if (compressedSize <= 0) {
      Get.back();

      Utils.showToast(
          "Compression failed.\nCompressed video is empty.");

      return;
    }

    finalVideoPath = compressedPath;

    Utils.showLog(
      "Compressed Size: ${(compressedSize / (1024 * 1024)).toStringAsFixed(2)} MB",
    );

    Utils.showLog("Compression Successful.");

  } catch (e, stack) {

    Utils.showLog("Compression Exception");
    Utils.showLog(e.toString());
    Utils.showLog(stack.toString());

    Get.back();

    Utils.showToast(
      "Compression failed.\n\n${e.toString()}",
    );

    return;
  }
}
else {
  Get.back();

  Utils.showToast("Video file does not exist.");

  return;
}

// ---------------- END VIDEO COMPRESSION ----------------
      // --- VIDEO COMPRESSION END ---

      List<String> hashTagIds = [];
      for (int index = 0; index < userInputHashtag.length; index++) {
        final hashTag = userInputHashtag[index];
        if (hashTag != "" && hashTag.startsWith("#")) {
          final searchHashtag = userInputHashtag[index].substring(1);
          createHashTagModel = null;
          final List<HashTagData> selectedHashTag = hastTagCollection.where((element) => (element.hashTag?.toLowerCase() ?? "") == searchHashtag.toLowerCase()).toList();

          if (selectedHashTag.isNotEmpty) {
            hashTagIds.add(selectedHashTag.first.id ?? "");
          } else {
            createHashTagModel = await CreateHashTagApi.callApi(hashTag: userInputHashtag[index].substring(1));
            if (createHashTagModel?.data?.id != null) {
              hashTagIds.add(createHashTagModel?.data?.id ?? "");
            }
          }
        }
      }

      // Safeguard: explicitly fall back to local videoThumbnail variable if videoThumbnailUrl framework context dropped values
      String finalThumbnail = (videoThumbnailUrl != null && videoThumbnailUrl!.isNotEmpty) ? videoThumbnailUrl! : videoThumbnail;

      if (finalThumbnail.isNotEmpty && finalVideoPath.isNotEmpty) {
        uploadProgressPercentage.value = "Uploading to Video Server: 0%";

        if (!File(finalVideoPath).existsSync()) {
          Get.back();
          Utils.showToast("Compressed video cannot be found.");
          return;
        }

        // --- BUNNY.NET STREAM API INTEGRATION ---
        const String bunnyApiKey = 'ec4a587a-307d-4b30-b3fb86d692d0-deb9-44ff'; 
        const String libraryId = '700372';      
        String finalBunnyStreamUrl = "";

        try {
          final dio = dio_lib.Dio();
          
          // Step 1: Create Video entry placeholder on Bunny.net
          final createVideoResponse = await dio.post(
            "https://video.bunnycdn.com/library/$libraryId/videos",
            data: jsonEncode({"title": "reel_${DateTime.now().millisecondsSinceEpoch}"}),
            options: dio_lib.Options(
              headers: {
                "AccessKey": bunnyApiKey,
                "Content-Type": "application/json",
              },
            ),
          );

          if (createVideoResponse.statusCode != 200) {
            throw Exception("Failed to generate Video entry ID from Bunny Stream.");
          }

          final String bunnyVideoId = createVideoResponse.data["guid"];
          Utils.showLog("✅ Created Bunny Video Registry ID: $bunnyVideoId");

          // Step 2: Upload direct file stream to Bunny.net storage
          final videoFileBytes = await File(finalVideoPath).readAsBytes();
          
          await dio.put(
            "https://video.bunnycdn.com/library/$libraryId/videos/$bunnyVideoId",
            data: Stream.fromIterable(videoFileBytes.map((e) => [e])),
            options: dio_lib.Options(
              headers: {
                "AccessKey": bunnyApiKey,
                "Content-Type": "application/octet-stream",
              },
            ),
            onSendProgress: (sent, total) {
              if (total != -1) {
                double progress = (sent / total) * 100;
                uploadProgressPercentage.value = "Uploading: ${progress.toStringAsFixed(0)}%";
                uploadProgress.value = 0.70 + ((progress / 100) * 0.25);
              }
            },
          );

          // Bunny playout URL framework format: https://[Pull-Zone-Domain]/[Video-ID]/playlist.m3u8
          finalBunnyStreamUrl = "https://video.bunnycdn.com/play/$libraryId/$bunnyVideoId";
          Utils.showLog("✅ Bunny Stream processing url created: $finalBunnyStreamUrl");
        } catch (e) {
          Get.back();
          Utils.showLog("❌ Bunny Upload Failure: $e");
          Utils.showToast("Failed streaming platform asset migration safely.");
          return;
        }

        // Send metadata package downstream containing generated Stream cloud endpoint directly
        uploadReelsModel = await UploadReelsApi.callApi(
          loginUserId: Database.loginUserId,
          videoImage: finalThumbnail,
          videoUrl: finalBunnyStreamUrl, 
          videoTime: videoTime.toString(),
          hashTag: hashTagIds.map((e) => "$e").join(',').toString(),
          caption: captionController.text.trim(),
          songId: songId,
          onProgressUpdate: (progressString) {
            uploadProgressPercentage.value = "Saving post details...";
            uploadProgress.value = 0.95;
          },
        );
      } else {
        Utils.showLog("❌ FAIL: Thumb: $finalThumbnail, Path: $finalVideoPath");
        Utils.showToast(EnumLocal.txtSomeThingWentWrong.name.tr);
      }

      if (uploadReelsModel?.status == true && uploadReelsModel?.data?.id != null) {
        isVideoUploadSuccess = true;
        Utils.showToast(EnumLocal.txtReelsUploadSuccessfully.name.tr);
        
        Get.back();

Future.delayed(const Duration(milliseconds: 100), () {
  Get.offAllNamed(AppRoutes.bottomBarPage);
});
        
      } else if (uploadReelsModel?.status == false && uploadReelsModel?.message == "your duration of Video greater than decided by the admin.") {
        Get.back(); 
        Utils.showToast(uploadReelsModel?.message ?? "");
      } else {
        Get.back(); 
        Utils.showToast(EnumLocal.txtSomeThingWentWrong.name.tr);
      }
    } else {
      Utils.showToast(EnumLocal.txtConnectionLost.name.tr);
    }
  }
}
