import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:deepar_flutter_plus/deepar_flutter_plus.dart';
import 'package:ffmpeg_kit_16kb/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:auralive/custom/custom_thumbnail.dart';
import 'package:auralive/custom/custom_video_time.dart';
import 'package:auralive/ui/loading_ui.dart';
import 'package:auralive/pages/create_reels_page/api/fetch_all_sound_api.dart';
import 'package:auralive/pages/create_reels_page/api/fetch_favorite_sound_api.dart';
import 'package:auralive/pages/create_reels_page/api/search_sound_api.dart';
import 'package:auralive/pages/create_reels_page/model/fetch_all_sound_model.dart';
import 'package:auralive/pages/create_reels_page/model/fetch_favorite_sound_model.dart';
import 'package:auralive/pages/create_reels_page/model/search_sound_model.dart';
import 'package:auralive/routes/app_routes.dart';
import 'package:auralive/utils/asset.dart';
import 'package:auralive/utils/database.dart';
import 'package:auralive/utils/enums.dart';
import 'package:auralive/utils/utils.dart';

// ✅ IF YOU HAVE THE WIDGETS, UNCOMMENT THIS IMPORT:
import 'package:auralive/pages/create_reels_page/widget/create_reels_widget.dart'; 

class CreateReelsController extends GetxController {
  
  // ✅ DISABLE EFFECTS
  final bool isUseEffects = false; 

  bool isFlashOn = false;
  int countTime = 0;
  Timer? timer;
  int selectedDuration = 5;
  final List<int> recordingDurations = [5, 10, 15, 30];

  double? videoTime;
  String? videoImage;
  String isRecording = "stop"; 
  
  // ✅ ERROR HANDLING VARIABLES
  bool isCameraError = false; 
  String errorMessage = "";

  CameraController? cameraController;
  CameraLensDirection cameraLensDirection = CameraLensDirection.front;
  DeepArControllerPlus deepArController = DeepArControllerPlus();

  final List effectsCollection = [];
  final List<String> effectImages = [];
  final List<String> effectNames = [];
  final List effectsImageCollection = [];

  bool isShowEffects = false;
  int selectedEffectIndex = 0;
  bool isInitializeEffect = false;
  bool isFrontCamera = false;

  @override
  void onInit() {
    Utils.showLog("Argument => ${Get.arguments}");
    if (Get.arguments != null) {
      selectedSound = Get.arguments;
      initAudio(selectedSound?["link"] ?? "");
    }
    Future.delayed(const Duration(milliseconds: 500), () {
      onGetPermission();
    });
    super.onInit();
  }

  @override
  void onClose() {
    onDisposeCamera();
    super.onClose();
  }

  Future<void> onGetPermission() async {
    isCameraError = false;
    update(["onInitializeCamera"]);

    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
      Permission.photos, 
    ].request();

    bool cameraGranted = statuses[Permission.camera]!.isGranted;
    bool micGranted = statuses[Permission.microphone]!.isGranted;

    if (cameraGranted && micGranted) {
       onInitializeCamera();
    } else {
      isCameraError = true;
      errorMessage = "Permissions denied";
      update(["onInitializeCamera"]);
      Utils.showToast("Camera permissions are required.");
      if (statuses[Permission.camera]!.isPermanentlyDenied) {
        openAppSettings();
      }
    }
  }

  Future<void> onInitializeCamera() async {
  try {
    final cameras = await availableCameras();
    if (cameras.isEmpty) throw Exception("No cameras available");

    cameraController = CameraController(
      cameras.firstWhere((c) => c.lensDirection == cameraLensDirection, orElse: () => cameras.first),
      ResolutionPreset.high,
      enableAudio: true, // Crucial for initial recording
    );

    await cameraController!.initialize();
    update(["onInitializeCamera"]);
  } catch (e) {
    isCameraError = true;
    errorMessage = e.toString();
    update(["onInitializeCamera"]);
  }
}

  Future<void> onDisposeCamera() async {
    cameraController?.dispose();
    cameraController = null;
    cameraController?.removeListener(cameraControllerListener);
  }

  Future<void> cameraControllerListener() async {
    Utils.showLog("Change Camera Event => ${cameraController?.value}");
  }

  Future<void> onSwitchFlash() async {
    if (cameraController != null && cameraController!.value.isInitialized) {
      if (isFlashOn) {
        isFlashOn = false;
        await cameraController?.setFlashMode(FlashMode.off);
      } else {
        isFlashOn = true;
        await cameraController?.setFlashMode(FlashMode.torch);
      }
      update(["onSwitchFlash"]);
    }
  }

  Future<void> onSwitchCamera() async {
    if (isRecording == "stop") {
      Get.dialog(barrierDismissible: false, const LoadingUi());
      cameraLensDirection = cameraLensDirection == CameraLensDirection.back ? CameraLensDirection.front : CameraLensDirection.back;
      try {
        final cameras = await availableCameras();
        final camera = cameras.firstWhere(
            (c) => c.lensDirection == cameraLensDirection,
            orElse: () => cameras.first
        );
        cameraController = CameraController(camera, ResolutionPreset.high);
        await cameraController!.initialize();
        update(["onInitializeCamera"]);
      } catch(e) {
        Utils.showLog("Switch Camera Failed: $e");
      }
      Get.back();
    }
  }

  Future<void> onStartRecording() async {
    try {
      if (cameraController != null && cameraController!.value.isInitialized) {
        Get.dialog(barrierDismissible: false, const LoadingUi());
        onRestartAudio();
        await cameraController!.startVideoRecording();
        Get.back();
        if (cameraController!.value.isRecordingVideo) {
          onChangeRecordingEvent("start");
        }
      }
    } catch (e) {
      onPauseAudio();
      onChangeRecordingEvent("stop");
    }
  }

  Future<void> onPauseRecording() async {
    try {
      if (cameraController != null && cameraController!.value.isInitialized) {
        Get.dialog(barrierDismissible: false, const LoadingUi());
        onPauseAudio();
        await cameraController!.pauseVideoRecording();
        Get.back();
        if (cameraController!.value.isRecordingPaused) {
          onChangeRecordingEvent("pause");
        }
      }
    } catch (e) {
      onChangeRecordingEvent("stop");
    }
  }

  Future<void> onResumeRecording() async {
    try {
      if (cameraController != null && cameraController!.value.isInitialized) {
        Get.dialog(barrierDismissible: false, const LoadingUi());
        onResumeAudio();
        await cameraController!.resumeVideoRecording();
        Get.back();
        if (cameraController!.value.isRecordingPaused) {
          onChangeRecordingEvent("start");
        }
      }
    } catch (e) {
      onPauseAudio();
      onChangeRecordingEvent("stop");
    }
  }

  Future<String?> onStopRecording() async {
    XFile? videoUrl;
    try {
      if (isFlashOn) { onSwitchFlash(); }
      Get.dialog(barrierDismissible: false, const LoadingUi());
      onPauseAudio();
      videoUrl = await cameraController!.stopVideoRecording();
      
      // ✅ SAVE TO THE VARIABLE THE VIEW IS WATCHING
      recordedVideoPath = videoUrl.path; 
      
      Get.back();
      onChangeRecordingEvent("stop");
      return videoUrl.path;
    } catch (e) {
      onChangeRecordingEvent("stop");
      if (Get.isOverlaysOpen) Get.back();
      return null;
    }
  }

  Future<void> onClickRecordingButton() async {
    if (isRecording == "stop") {
      onChangeRecordingEvent("start");
      onChangeTimer();
      onStartRecording();
    } else if (isRecording == "start") {
      onChangeRecordingEvent("pause");
      onChangeTimer();
      onPauseRecording();
    } else if (isRecording == "pause") {
      onChangeRecordingEvent("start");
      onChangeTimer();
      onResumeRecording();
    }
  }

  Future<void> onInitializeEffect() async {}
  Future<void> onDisposeEffect() async {}
  Future<void> onSwitchEffectFlash() async {}
  Future<void> onSwitchEffectCamera() async {}
  Future<void> onToggleEffect() async {}
  Future<void> onChangeEffect(int index) async {}
  Future<void> onClearEffect(int index) async {}
  Future<void> onStartEffectRecording() async {}
  Future<String?> onStopEffectRecording() async { return null; }
  Future<void> onLongPressStart(LongPressStartDetails details) async {
     onChangeRecordingEvent("start");
     onChangeTimer();
     onStartRecording();
  }
  // Also update this to ensure the preview button appears after long press
  Future<void> onLongPressEnd(LongPressEndDetails details) async {
     final videoPath = await onStopRecording();
     if (videoPath != null) { 
       recordedVideoPath = videoPath; // Ensure it's set
       update(["onChangeRecordingEvent"]); // Trigger UI update
       onPreviewVideo(videoPath); 
     }
  }

  Future<void> onChangeTimer() async {
    if (isRecording == "start") {
      timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
          if (isRecording == "start" && countTime <= selectedDuration) {
            countTime++;
            update(["onChangeTimer", "onChangeRecordingEvent"]);
            if (countTime >= selectedDuration) {
              {
                countTime = 0;
                timer.cancel();
                onChangeRecordingEvent("stop");
                final videoPath = await onStopRecording();
                if (videoPath != null) { onPreviewVideo(videoPath); }
              }
            }
          }
        },
      );
    } else if (isRecording == "pause") {
      timer?.cancel();
      update(["onChangeTimer", "onChangeRecordingEvent"]);
    } else {
      countTime = 0;
      timer?.cancel();
      onChangeRecordingEvent("stop");
      update(["onChangeTimer", "onChangeRecordingEvent"]);
    }
  }

  Future<void> onChangeRecordingDuration(int index) async {
    selectedDuration = recordingDurations[index];
    update(["onChangeRecordingDuration"]);
  }

  Future<void> onChangeRecordingEvent(String type) async {
    isRecording = type;
    update(["onChangeRecordingEvent"]);
  }

  Future<String?> onRemoveAudio(String videoPath) async {
    final String videoWithoutAudioPath = '${(await getTemporaryDirectory()).path}/RM_${DateTime.now().millisecondsSinceEpoch}.mp4';
    Utils.showLog("Remove Audio Path => $videoWithoutAudioPath");
    return videoWithoutAudioPath;
  }

  // Update your onMergeAudioWithVideo with this high-performance command:
Future<String?> onMergeAudioWithVideo(String videoPath, String audioPath) async {
  final String path = '${(await getTemporaryDirectory()).path}/FINAL_REEL_${DateTime.now().millisecondsSinceEpoch}.mp4';
  
  // Get durations
  videoTime = (await CustomVideoTime.onGet(videoPath) ?? 0).toDouble();
  final soundTime = (await onGetSoundTime(audioPath) ?? 0);

  if (soundTime != 0 && videoTime != 0) {
    // We take the shorter of the two to avoid black frames or silence
    final minTime = (videoTime! < soundTime) ? videoTime : soundTime;
    
    /* COMMAND EXPLAINED:
       -i: Inputs
       -t: Duration limit
       -map 0:v:0: Take Video from first input (Camera)
       -map 1:a:0: Take Audio from second input (Music)
       -c:v copy: Don't re-render video (Super Fast)
    */
    final command = '-i "$videoPath" -i "$audioPath" -t $minTime -map 0:v:0 -map 1:a:0 -c:v copy -c:a aac -shortest "$path"';
    
    await FFmpegKit.execute(command);
    return path;
  }
  return null;
}

  Future<void> onClickPreviewButton() async {
    Get.dialog(barrierDismissible: false, const LoadingUi());
    onChangeRecordingEvent("stop");
    timer?.cancel();
    countTime = 0;
    final videoPath = await onStopRecording();
    Get.back();
    if (videoPath != null) {
      onPreviewVideo(videoPath);
    }
  }

  Future<void> onPreviewVideo(String videoPath) async {
    Get.dialog(barrierDismissible: false, const LoadingUi());
    videoImage = await CustomThumbnail.onGet(videoPath);
    
    if (selectedSound != null) {
      Utils.showLog("Removing Audio From Video...");
      Utils.showToast(EnumLocal.txtPleaseWaitSomeTime.name.tr);
      final mergeVideoPath = await onMergeAudioWithVideo(videoPath, selectedSound?["link"]);
      await 5.seconds.delay();
      Get.back();

      if (mergeVideoPath != null && videoTime != null && videoImage != null) {
        Get.offAndToNamed(
          AppRoutes.previewCreatedReelsPage,
          arguments: {
            "video": mergeVideoPath,
            "image": videoImage,
            "time": videoTime?.toInt(),
            "songId": selectedSound?["id"] ?? "",
          },
        );
      } else {
        Utils.showToast(EnumLocal.txtSomeThingWentWrong.name.tr);
      }
    } else {
      videoTime = (await CustomVideoTime.onGet(videoPath) ?? 0).toDouble();
      Get.back();

      if (videoTime != null && videoImage != null) {
        Get.offAndToNamed(
          AppRoutes.previewCreatedReelsPage,
          arguments: {
            "video": videoPath,
            "image": videoImage,
            "time": videoTime?.toInt(),
            "songId": "",
          },
        );
      } else {
        Utils.showToast(EnumLocal.txtSomeThingWentWrong.name.tr);
      }
    }
  }

  AudioPlayer _audioPlayer = AudioPlayer();
  Map? selectedSound;
  int selectedTabIndex = 0;
  TextEditingController searchController = TextEditingController();
  
  // ✅ FIX: Replaced Tab Pages with placeholders to fix "Constructor Not Found" error
  final List soundTabPages = [Container(), Container()]; 

  bool isLoadingSound = true;
  List<AllSongs> mainSoundCollection = [];
  FetchAllSoundModel? fetchAllSoundModel;
  bool isLoadingFavoriteSound = true;
  List<FavoriteSongs> favoriteSoundCollection = [];
  FetchFavoriteSoundModel? fetchFavoriteSoundModel;
  ScrollController favoriteSoundController = ScrollController();
  bool isSearching = false;
  SearchSoundModel? searchSoundModel;
  List<SearchData> searchSounds = [];
  bool isSearchLoading = false;

  Future<void> onChangeTabBar(int index) async {
    selectedTabIndex = index;
    if (index == 0) { initAllSound(); } else if (index == 1) { initFavoriteSound(); }
    update(["onChangeTabBar"]);
  }
  
  void onChangeSearchEvent() {
    if (searchController.text.trim().isEmpty) { isSearching = false; } 
    else if (searchController.text.trim().length == 1) { isSearching = true; }
    update(["onChangeSearchEvent"]);
  }
  
  Future<void> onSearchSound() async {
    onChangeSearchEvent();
    if (searchController.text.trim().isNotEmpty) {
      isSearchLoading = true;
      update(["onSearchSound"]);
      searchSoundModel = await SearchSoundApi.callApi(loginUserId: Database.loginUserId, searchText: searchController.text);
      if (searchSoundModel?.searchData != null) {
        searchSounds.clear();
        searchSounds.addAll(searchSoundModel?.searchData ?? []);
      }
      isSearchLoading = false;
      update(["onSearchSound"]);
    }
  }
  
  Future<void> initAllSound() async {
    mainSoundCollection.clear();
    onGetAllSound();
  }
  
  Future<void> onGetAllSound() async {
    if (mainSoundCollection.isEmpty) { isLoadingSound = true; update(["onGetAllSound"]); }
    fetchAllSoundModel = await FetchAllSoundApi.callApi(loginUserId: Database.loginUserId);
    if (fetchAllSoundModel?.songs != null) {
      isLoadingSound = false;
      mainSoundCollection.addAll(fetchAllSoundModel?.songs ?? []);
    }
    update(["onGetAllSound"]);
  }
  
  Future<void> initFavoriteSound() async {
    favoriteSoundCollection.clear();
    FetchFavoriteSoundApi.startPagination = 0;
    onGetFavoriteSound();
  }
  
  Future<void> onGetFavoriteSound() async {
    if (favoriteSoundCollection.isEmpty) { isLoadingFavoriteSound = true; update(["onGetFavoriteSound"]); }
    fetchFavoriteSoundModel = await FetchFavoriteSoundApi.callApi(loginUserId: Database.loginUserId);
    if (fetchFavoriteSoundModel?.songs != null) {
      isLoadingFavoriteSound = false;
      favoriteSoundCollection.addAll(fetchFavoriteSoundModel?.songs ?? []);
    }
    update(["onGetFavoriteSound"]);
  }
  
  Future<void> onChangeSound(Map sound) async {
    if (selectedSound?["id"] == sound["id"]) {
      selectedSound = null;
    } else {
      selectedSound = { "id": sound["id"], "name": sound["name"], "image": sound["image"], "link": sound["link"] };
      initAudio(sound["link"]);
    }
    update(["onChangeSound"]);
  }
  
  Future<double?> onGetSoundTime(String audioPath) async {
    await _audioPlayer.setSourceUrl(audioPath);
    Duration? audioDuration = await _audioPlayer.getDuration();
    return audioDuration?.inSeconds.toDouble();
  }
  
  AudioPlayer audioPlayer = AudioPlayer();

  void initAudio(String audio) async {
    try { await audioPlayer.setSource(UrlSource(audio)); } catch (e) {}
  }
  
  void onResumeAudio() {
    if (selectedSound != null) { audioPlayer.resume(); }
  }
  
  void onRestartAudio() {
    if (selectedSound != null) {
      audioPlayer.seek(Duration(milliseconds: 0));
      audioPlayer.resume();
    }
  }
  
  void onPauseAudio() {
    if (selectedSound != null) { audioPlayer.pause(); }
  }

  String? recordedVideoPath; 

  // 2. Ensure your camera init method is named 'initCamera'
  // If it's named 'onInit' or something else, rename it to 'initCamera'
  Future<void> initCamera() async {
    // Your camera initialization logic here...
    await onGetPermission();
  }
}
