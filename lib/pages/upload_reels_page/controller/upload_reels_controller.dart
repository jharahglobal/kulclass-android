import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart'; // Provides XFile
// ✅ IMPORT
import 'package:video_compress/video_compress.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart'; 
import 'package:path_provider/path_provider.dart';     

import 'package:auralive/custom/custom_image_picker.dart';
import 'package:auralive/pages/preview_hash_tag_page/api/create_hash_tag_api.dart';
import 'package:auralive/pages/preview_hash_tag_page/api/fetch_hash_tag_api.dart';
import 'package:auralive/pages/preview_hash_tag_page/model/create_hash_tag_model.dart';
import 'package:auralive/pages/preview_hash_tag_page/model/fetch_hash_tag_model.dart';
import 'package:auralive/pages/profile_page/api/delete_content_api.dart';
import 'package:auralive/pages/upload_reels_page/api/fetch_ai_caption_api.dart';
import 'package:auralive/pages/upload_reels_page/api/upload_reels_api.dart';
import 'package:auralive/pages/upload_reels_page/model/upload_reels_model.dart';
import 'package:auralive/ui/image_picker_bottom_sheet_ui.dart';
import 'package:auralive/ui/loading_ui.dart';
import 'package:auralive/utils/database.dart';
import 'package:auralive/utils/enums.dart';
import 'package:auralive/utils/internet_connection.dart';
import 'package:auralive/utils/utils.dart';

import '../model/fetch_ai_caption_model.dart';

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

  FetchAiCaptionModel? fetchAiCaptionModel;
  bool isLoadingAiCaption = false;

  bool isAiCaptionSwitchOn = false;

  bool isVideoUploadSuccess = false;

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

    // -----------------------------------------------------------
    // ✅ FIX: Correct Implementation for get_thumbnail_video
    // -----------------------------------------------------------
    if (videoPath.isNotEmpty) {
      bool isThumbValid = false;
      if (videoThumbnail.isNotEmpty) {
        isThumbValid = await File(videoThumbnail).exists();
      }

      if (!isThumbValid) {
        Utils.showLog("⚠️ Thumbnail missing. Generating with VideoThumbnail...");
        try {
          // ✅ FIX 1: Removed 'imageFormat' (defaults to JPEG)
          // ✅ FIX 2: Handle 'XFile' return type instead of String
          final thumbFile = await VideoThumbnail.thumbnailFile(
            video: videoPath,
            thumbnailPath: (await getTemporaryDirectory()).path,
            maxHeight: 500,
            quality: 75,
          );

          // Extract path safely
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
    // -----------------------------------------------------------

    onGetHashTag();
    Utils.showLog("Selected Song Id => $songId");
    onConvertVideoThumbnail();
  }

  Future<void> onConvertVideoThumbnail() async {
    videoThumbnailUrl = videoThumbnail;
    update(["onChangeThumbnail"]);

    if (isAiCaptionSwitchOn) onFetchAiCaption();
  }

  void onChangeAiSwitch({bool? value}) async {
    isAiCaptionSwitchOn = value ?? !isAiCaptionSwitchOn;
    update(["onChangeAiSwitch"]);

    if (isAiCaptionSwitchOn) {
      onFetchAiCaption();
    } else {
      captionController.clear();
      update(["onGenerateAiCaption"]);
    }
  }

  void onFetchAiCaption() async {
    if (videoThumbnailUrl?.trim().isNotEmpty == true) {
      isLoadingAiCaption = true;
      update(["onGenerateAiCaption"]);

      fetchAiCaptionModel = await FetchAiCaptionApi.callApi(contentUrl: videoThumbnailUrl ?? "");

      captionController.clear();
      captionController.text = ((fetchAiCaptionModel?.caption ?? "") + (fetchAiCaptionModel?.hashtags?.join(" ") ?? ""));

      isLoadingAiCaption = false;
      update(["onGenerateAiCaption"]);
    }
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
          update(["onChangeThumbnail"]);
          onConvertVideoThumbnail();
        }
      },
      onClickGallery: () async {
        final imagePath = await CustomImagePicker.pickImage(ImageSource.gallery);
        if (imagePath != null) {
          videoThumbnail = imagePath;
          update(["onChangeThumbnail"]);
          onConvertVideoThumbnail();
        }
      },
    );
  }

  Future<void> onUploadReels() async {
    Utils.showLog("Reels Uploading Process Started...");
    if (InternetConnection.isConnect.value) {
      Get.dialog(PopScope(canPop: false, child: const LoadingUi()), barrierDismissible: false);

      String finalVideoPath = videoPath;

      // --- VIDEO COMPRESSION START ---
   // --- VIDEO COMPRESSION START ---
      if (videoPath.isNotEmpty && File(videoPath).existsSync()) {
        try {
          final originalSize = File(videoPath).lengthSync();
          Utils.showLog("Original Video Size: ${(originalSize / (1024 * 1024)).toStringAsFixed(2)} MB");

          // Open a loading dialog that tells the user compression is active
          Utils.showLog("⚙️ Starting Video Compression via video_compress...");
          
          final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
            videoPath,
            quality: VideoQuality.DefaultQuality, // Balanced compression optimization
            deleteOrigin: false, 
            includeAudio: true,
          );

          if (mediaInfo != null && mediaInfo.path != null) {
            finalVideoPath = mediaInfo.path!;
            final compressedSize = File(finalVideoPath).lengthSync();
            Utils.showLog("✅ Video Compressed Successfully!");
            Utils.showLog("Compressed Video Size: ${(compressedSize / (1024 * 1024)).toStringAsFixed(2)} MB");
          } else {
            Utils.showLog("⚠️ Compression returned empty media information. Using original file.");
          }
        } catch (e) {
          Utils.showLog("❌ Error during video compression: $e");
        }
      }
      // --- VIDEO COMPRESSION END ---
      // --- VIDEO COMPRESSION END ---

      List<String> hashTagIds = [];
      for (int index = 0; index < userInputHashtag.length; index++) {
        final hashTag = userInputHashtag[index];
        if (hashTag != "" && hashTag.startsWith("#")) {
          final searchHashtag = userInputHashtag[index].substring(1);
          createHashTagModel = null;
          final List<HashTagData> selectedHashTag = hastTagCollection.where((element) => (element.hashTag?.toLowerCase() ?? "") == searchHashtag.toLowerCase()).toList();

          if (selectedHashTag.isNotEmpty) {
            hashTagIds.add(selectedHashTag.id ?? "");
          } else {
            createHashTagModel = await CreateHashTagApi.callApi(hashTag: userInputHashtag[index].substring(1));
            if (createHashTagModel?.data?.id != null) {
              hashTagIds.add(createHashTagModel?.data?.id ?? "");
            }
          }
        }
      }

      if (videoThumbnailUrl != null && videoThumbnailUrl!.isNotEmpty && finalVideoPath.isNotEmpty) {
        uploadReelsModel = await UploadReelsApi.callApi(
          loginUserId: Database.loginUserId,
          videoImage: videoThumbnailUrl ?? "",
          videoUrl: finalVideoPath, // ✅ Uses compressed path
          videoTime: videoTime.toString(),
          hashTag: hashTagIds.map((e) => "$e").join(',').toString(),
          caption: captionController.text.trim(),
          songId: songId,
        );
      } else {
        Utils.showLog("❌ FAIL: Thumb: $videoThumbnailUrl, Path: $finalVideoPath");
        Utils.showToast(EnumLocal.txtSomeThingWentWrong.name.tr);
      }

      if (uploadReelsModel?.status == true && uploadReelsModel?.data?.id != null) {
        isVideoUploadSuccess = true;
        Utils.showToast(EnumLocal.txtReelsUploadSuccessfully.name.tr);
        Get.close(2);
      } else if (uploadReelsModel?.status == false && uploadReelsModel?.message == "your duration of Video greater than decided by the admin.") {
        Utils.showToast(uploadReelsModel?.message ?? "");
      } else {
        Utils.showToast(EnumLocal.txtSomeThingWentWrong.name.tr);
      }
      Get.back();
    } else {
      Utils.showToast(EnumLocal.txtConnectionLost.name.tr);
    }
  }
}
