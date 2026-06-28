import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:video_compress/video_compress.dart';
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
  
  // Subscription handler tracking compression metrics out-of-thread
  Subscription? _compressionSubscription;

  @override
  void onInit() {
    init();
    Utils.showLog("Upload Reels Controller Initialized...");
    super.onInit();
  }

  @override
  void onClose() {
    _compressionSubscription?.unsubscribe();
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
      uploadProgressPercentage.value = "Starting...";
      
      Get.dialog(
        PopScope(
          canPop: false, 
          child: AlertDialog(
            backgroundColor: AppColor.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CupertinoActivityIndicator(radius: 15),
                const SizedBox(height: 15),
                Obx(() => Text(
                  uploadProgressPercentage.value,
                  style: AppFontStyle.styleW600(AppColor.black, 15),
                  textAlign: TextAlign.center,
                )),
              ],
            ),
          )
        ), 
        barrierDismissible: false
      );

      String finalVideoPath = videoPath;

      // --- VIDEO COMPRESSION START ---
      if (videoPath.isNotEmpty && File(videoPath).existsSync()) {
        try {
          final originalSize = File(videoPath).lengthSync();
          Utils.showLog("Original Video Size: ${(originalSize / (1024 * 1024)).toStringAsFixed(2)} MB");

          // ✅ Correct implementation using the package's native observable stream listener
          _compressionSubscription = VideoCompress.compressProgress$.subscribe((progress) {
            uploadProgressPercentage.value = "Compressing: ${progress.toStringAsFixed(0)}%";
          });
          
          final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
            videoPath,
            quality: VideoQuality.MediumQuality, 
            deleteOrigin: false, 
            includeAudio: true,
          );

          // Always cancel the subscription immediately when down stream completes
          _compressionSubscription?.unsubscribe();

          if (mediaInfo != null && mediaInfo.path != null) {
            finalVideoPath = mediaInfo.path!;
            final compressedSize = File(finalVideoPath).lengthSync();
            Utils.showLog("✅ Video Compressed Successfully!");
            Utils.showLog("Compressed Video Size: ${(compressedSize / (1024 * 1024)).toStringAsFixed(2)} MB");
          } else {
            Utils.showLog("⚠️ Compression returned empty media information. Using original file.");
          }
        } catch (e) {
          _compressionSubscription?.unsubscribe();
          Utils.showLog("❌ Error during video compression: $e");
        }
      }
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
        uploadProgressPercentage.value = "Uploading: 0%";
        
        uploadReelsModel = await UploadReelsApi.callApi(
          loginUserId: Database.loginUserId,
          videoImage: finalThumbnail, // ✅ Secure local verified image parameter string path
          videoUrl: finalVideoPath,
          videoTime: videoTime.toString(),
          hashTag: hashTagIds.map((e) => "$e").join(',').toString(),
          caption: captionController.text.trim(),
          songId: songId,
          onProgressUpdate: (progressString) {
            uploadProgressPercentage.value = "Uploading: $progressString";
          }
        );
      } else {
        Utils.showLog("❌ FAIL: Thumb: $finalThumbnail, Path: $finalVideoPath");
        Utils.showToast(EnumLocal.txtSomeThingWentWrong.name.tr);
      }

      if (uploadReelsModel?.status == true && uploadReelsModel?.data?.id != null) {
        isVideoUploadSuccess = true;
        Utils.showToast(EnumLocal.txtReelsUploadSuccessfully.name.tr);
        Get.close(2);
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
