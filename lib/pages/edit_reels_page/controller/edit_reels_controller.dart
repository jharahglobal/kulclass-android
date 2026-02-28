import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:auralive/custom/custom_image_picker.dart';
import 'package:auralive/pages/edit_reels_page/api/edit_reels_api.dart';
import 'package:auralive/pages/edit_reels_page/model/edit_reels_model.dart';
import 'package:auralive/pages/preview_hash_tag_page/api/create_hash_tag_api.dart';
import 'package:auralive/pages/preview_hash_tag_page/api/fetch_hash_tag_api.dart';
import 'package:auralive/pages/preview_hash_tag_page/model/create_hash_tag_model.dart';
import 'package:auralive/pages/preview_hash_tag_page/model/fetch_hash_tag_model.dart';
import 'package:auralive/pages/splash_screen_page/api/upload_file_api.dart';
import 'package:auralive/ui/image_picker_bottom_sheet_ui.dart';
import 'package:auralive/ui/loading_ui.dart';
import 'package:auralive/utils/database.dart';
import 'package:auralive/utils/enums.dart';
import 'package:auralive/utils/internet_connection.dart';
import 'package:auralive/utils/utils.dart';

class EditReelsController extends GetxController {
  EditReelsModel? editReelsModel;

  // --- ADDED THESE VARIABLES TO FIX VIEW ERRORS ---
  bool isLoading = false; 
  String videoPath = ""; // To track the actual file path if needed
  // ------------------------------------------------

  String videoCaption = "";
  String videoUrl = "";
  String videoId = "";
  String videoThumbnail = "";
  String? selectedImage;
  

  TextEditingController captionController = TextEditingController();

  FetchHashTagModel? fetchHashTagModel;
  CreateHashTagModel? createHashTagModel;

  bool isLoadingHashTag = false;
  List<HashTagData> hastTagCollection = [];
  List<HashTagData> filterHashtag = [];

  RxBool isShowHashTag = false.obs;
  List<String> userInputHashtag = [];

  @override
  void onInit() {
    init();
    Utils.showLog("Upload Reels Controller Initialized...");
    super.onInit();
  }

  Future<void> init() async {
    final arguments = Get.arguments;
    Utils.showLog("Selected Video => $arguments");

    videoUrl = arguments["video"] ?? "";
    videoPath = arguments["video"] ?? ""; // Fix: Set videoPath for the View check
    videoThumbnail = arguments["image"] ?? "";
    videoCaption = arguments["caption"] ?? "";
    videoId = arguments["videoId"] ?? "";
    captionController.text = videoCaption;

    onGetHashTag();
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

    Utils.showLog("Caption => ${caption}");
    Utils.showLog("Last Word => ${lastWord}");

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
          selectedImage = imagePath;
          videoThumbnail = imagePath;
          update(["onChangeThumbnail"]);
        }
      },
      onClickGallery: () async {
        final imagePath = await CustomImagePicker.pickImage(ImageSource.gallery);

        if (imagePath != null) {
          selectedImage = imagePath;
          videoThumbnail = imagePath;
          update(["onChangeThumbnail"]);
        }
      },
    );
  }

  Future<void> onEditUploadReels() async {
    Utils.showLog("Reels Uploading Process Started...");
    
    if (InternetConnection.isConnect.value) {
      // 1. UPDATE LOADING STATE
      isLoading = true;
      update(["onUploadProgress"]); 

      // We still use the Dialog for safety, but isLoading handles the button UI
      Get.dialog(const PopScope(canPop: false, child: LoadingUi()), barrierDismissible: false);

      try {
        // 2. Process Hashtags
        List<String> hashTagIds = [];
        String text = captionController.text;
        List<String> parts = text.split(' ');
        userInputHashtag = parts.where((element) => element.startsWith('#')).toList();

        for (var hashTag in userInputHashtag) {
          if (hashTag.length > 1) {
            final cleanTagName = hashTag.substring(1);
            final existingTag = hastTagCollection.firstWhereOrNull(
              (e) => e.hashTag?.toLowerCase() == cleanTagName.toLowerCase()
            );

            if (existingTag != null) {
              hashTagIds.add(existingTag.id ?? "");
            } else {
              var newTag = await CreateHashTagApi.callApi(hashTag: cleanTagName);
              if (newTag?.data?.id != null) {
                hashTagIds.add(newTag!.data!.id!);
              }
            }
          }
        }

        // 3. Handle Thumbnail
        String? finalImageUrl;
        if (selectedImage != null) {
          finalImageUrl = await UploadFileApi.callApi(
            filePath: selectedImage!,
            fileType: 2,
            keyName: "reels_${DateTime.now().millisecondsSinceEpoch}.jpg",
          );
        } else {
          finalImageUrl = videoThumbnail; 
        }

        // 4. Call Edit API
        await onCallEditApi(
          hashTag: hashTagIds.join(','), 
          image: finalImageUrl
        );

      } catch (e) {
        if (Get.isOverlaysOpen) Get.back(); 
        isLoading = false;
        update(["onUploadProgress"]);
        Utils.showLog("Upload Error: $e");
        Utils.showToast("Upload failed. Please try again.");
      }
    } else {
      Utils.showToast(EnumLocal.txtConnectionLost.name.tr);
    }
  }

  Future<void> onCallEditApi({required String hashTag, String? image}) async {
    editReelsModel = await EditReelsApi.callApi(
      loginUserId: Database.loginUserId,
      videoImage: image,
      videoId: videoId,
      hashTag: hashTag,
      caption: captionController.text.trim(),
    );

    // 5. CLEAN UP LOADING STATE
    isLoading = false;
    update(["onUploadProgress"]);
    if (Get.isOverlaysOpen) Get.back(); 

    if (editReelsModel?.status == true) {
      Utils.showToast(EnumLocal.txtReelsUploadSuccessfully.name.tr);
      Get.until((route) => Get.currentRoute == '/MainPage' || route.isFirst); 
    } else {
      Utils.showToast(editReelsModel?.message ?? EnumLocal.txtSomeThingWentWrong.name.tr);
    }
  }
}
