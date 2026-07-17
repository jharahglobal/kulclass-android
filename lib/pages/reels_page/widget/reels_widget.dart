import 'dart:io';
import 'package:auralive/custom/custom_fetch_user_coin.dart';
import 'package:get_storage/get_storage.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb

import 'package:blurrycontainer/blurrycontainer.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:readmore/readmore.dart';
import 'package:auralive/custom/custom_format_number.dart';
import 'package:auralive/custom/custom_share.dart';
import 'package:auralive/pages/bottom_bar_page/controller/bottom_bar_controller.dart';
import 'package:auralive/routes/app_routes.dart';
import 'package:auralive/ui/loading_ui.dart';
import 'package:auralive/ui/preview_network_image_ui.dart';
import 'package:auralive/ui/preview_profile_bottom_sheet_ui.dart';
import 'package:auralive/custom/custom_icon_button.dart';
import 'package:auralive/ui/comment_bottom_sheet_ui.dart';
import 'package:auralive/main.dart';
import 'package:auralive/pages/reels_page/api/reels_like_dislike_api.dart';
import 'package:auralive/pages/reels_page/api/reels_share_api.dart';
import 'package:auralive/pages/reels_page/controller/reels_controller.dart';
import 'package:auralive/ui/report_bottom_sheet_ui.dart';
import 'package:auralive/ui/send_gift_on_video_bottom_sheet_ui.dart';
import 'package:auralive/ui/video_picker_bottom_sheet_ui.dart';
import 'package:auralive/utils/api.dart';
import 'package:auralive/utils/asset.dart';
import 'package:auralive/utils/branch_io_services.dart';
import 'package:auralive/utils/color.dart';
import 'package:auralive/utils/constant.dart';
import 'package:auralive/utils/database.dart';
import 'package:auralive/utils/enums.dart';
import 'package:auralive/utils/font_style.dart';
import 'package:auralive/utils/utils.dart';
import 'package:vibration/vibration.dart';
// Swapped to cached_video_player_plus import to support local caching
import 'package:cached_video_player_plus/cached_video_player_plus.dart'; 
import 'package:video_player/video_player.dart'; // Add this to resolve VideoPlayerOptions

class PreviewReelsView extends StatefulWidget {
  const PreviewReelsView({super.key, required this.index, required this.currentPageIndex});

  final int index;
  final int currentPageIndex;

  @override
  State<PreviewReelsView> createState() => _PreviewReelsViewState();
}

class _PreviewReelsViewState extends State<PreviewReelsView> with SingleTickerProviderStateMixin {
  final controller = Get.find<ReelsController>();

  ChewieController? chewieController;
  // Changed controller type to support CachedVideoPlayerPlus
  CachedVideoPlayerPlusController? videoPlayerController;

  RxBool isPlaying = true.obs;
  RxBool isShowIcon = false.obs;

  RxBool isBuffering = false.obs;
  RxBool isVideoLoading = true.obs;

  RxBool isShowLikeAnimation = false.obs;
  RxBool isShowLikeIconAnimation = false.obs;

  RxBool isReelsPage = true.obs;

  RxBool isLike = false.obs;

  RxMap customChanges = {"like": 0, "comment": 0}.obs;

  Rx<Duration> videoPosition = Duration.zero.obs;

   

  AnimationController? _controller;
  late Animation<double> _animation;

  RxBool isReadMore = false.obs;

  @override
  void initState() {
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    if (_controller != null) {
      _animation = Tween(begin: 0.0, end: 1.0).animate(_controller!);
    }
    initializeVideoPlayer();
    customSetting();
    super.initState();
  }

  @override
  void dispose() {
    _controller?.dispose();
    onDisposeVideoPlayer();
    Utils.showLog("Dispose Method Called Success");
    super.dispose();
  }

  void _videoListener() {
    (videoPlayerController?.value.isBuffering ?? false)
        ? isBuffering.value = true
        : isBuffering.value = false;
    if (videoPlayerController != null) {
      videoPosition.value = videoPlayerController!.value.position;
    }
    if (isReelsPage.value == false) {
      onStopVideo();
    }
  }


  Future<void> initializeVideoPlayer() async {
    try {
      if (widget.index >= controller.mainReels.length || controller.mainReels[widget.index] == null) {
        return;
      }

      // Fixed: Only declare videoPath once, cleanly trimming the string
      String videoPath = controller.mainReels[widget.index].videoUrl!.trim();

      // Resolve path variations cleanly for HLS or progressive network streaming
      final Uri videoUri;
      if (videoPath.contains('http')) {
        videoUri = Uri.parse(videoPath.substring(videoPath.indexOf('http')));
      } else {
        final String cleanPath = videoPath.startsWith('/') ? videoPath : '/$videoPath';
        videoUri = Uri.parse(Api.baseUrl.replaceAll(RegExp(r'/$'), '') + cleanPath);
      }

      Utils.showLog("🎯 Final Initialized Video URL: $videoUri");

      // Changed to networkUrl under CachedVideoPlayerPlusController with custom caching parameters
      videoPlayerController = CachedVideoPlayerPlusController.networkUrl(
        videoUri,
        invalidateCacheIfOlderThan: const Duration(days: 7), // Automatically caches the video on disk
        videoPlayerOptions: VideoPlayerOptions(
          allowBackgroundPlayback: false,
          mixWithOthers: true,
        ),
      );

      await videoPlayerController?.initialize();

      if (videoPlayerController != null && (videoPlayerController?.value.isInitialized ?? false)) {
        // Chewie is fully compatible with CachedVideoPlayerPlus controllers
        chewieController = ChewieController(
          videoPlayerController: videoPlayerController!,
          looping: true,
          allowedScreenSleep: false,
          allowMuting: false,
          showControlsOnInitialize: false,
          showControls: false,
          maxScale: 1,
        );

        if (chewieController != null) {
          isVideoLoading.value = false;
          (widget.index == widget.currentPageIndex && isReelsPage.value) ? onPlayVideo() : null;
        } else {
          isVideoLoading.value = true;
        }

        videoPlayerController?.addListener(_videoListener);
      }
    } catch (e) {
      onDisposeVideoPlayer();
      Utils.showLog("Reels Video Initialization Failed !!! ${widget.index} => $e");
    }
  }

  void onStopVideo() {
    isPlaying.value = false;
    videoPlayerController?.pause();
  }

  void onPlayVideo() {
    isPlaying.value = true;
    videoPlayerController?.play();
  }

  void onDisposeVideoPlayer() {
    try {
      if (videoPlayerController != null) {
        videoPlayerController?.removeListener(_videoListener);
        videoPlayerController?.pause();
        videoPlayerController?.dispose();
        videoPlayerController = null;
      }

      chewieController?.dispose();
      chewieController = null;

      isVideoLoading.value = true;
    } catch (e) {
      Utils.showLog(">>>> On Dispose VideoPlayer Error => $e");
    }
  }


  void customSetting() {
    isLike.value = controller.mainReels[widget.index].isLike!;
    customChanges["like"] = int.parse(controller.mainReels[widget.index].totalLikes.toString());
    customChanges["comment"] = int.parse(controller.mainReels[widget.index].totalComments.toString());
  }

  void onClickVideo() async {
    if (isVideoLoading.value == false) {
      videoPlayerController!.value.isPlaying ? onStopVideo() : onPlayVideo();
      isShowIcon.value = true;
      await 2.seconds.delay();
      isShowIcon.value = false;
    }
    if (isReelsPage.value == false) {
      isReelsPage.value = true;
    }
  }

  void onClickPlayPause() async {
    videoPlayerController!.value.isPlaying ? onStopVideo() : onPlayVideo();
    if (isReelsPage.value == false) {
      isReelsPage.value = true;
    }
  }

  Future<void> onClickShare() async {
    isReelsPage.value = false;

    Get.dialog(const LoadingUi(), barrierDismissible: false);

    await BranchIoServices.onCreateBranchIoLink(
      id: controller.mainReels[widget.index].id ?? "",
      name: controller.mainReels[widget.index].caption ?? "",
      image: controller.mainReels[widget.index].videoImage ?? "",
      userId: controller.mainReels[widget.index].userId ?? "",
      pageRoutes: "Video",
    );

    final link = await BranchIoServices.onGenerateLink();

    Get.back();

    if (link != null) {
      CustomShare.onShareLink(link: link);
    }
    await ReelsShareApi.callApi(loginUserId: Database.loginUserId, videoId: controller.mainReels[widget.index].id!);
  }

  Future<void> onClickLike() async {
    if (isLike.value) {
      isLike.value = false;
      customChanges["like"]--;
    } else {
      isLike.value = true;
      customChanges["like"]++;
    }

    isShowLikeIconAnimation.value = true;
    await 500.milliseconds.delay();
    isShowLikeIconAnimation.value = false;

    await ReelsLikeDislikeApi.callApi(
      loginUserId: Database.loginUserId,
      videoId: controller.mainReels[widget.index].id!,
    );
  }

  Future<void> onDoubleClick() async {
    if (isLike.value) {
      isLike.value = false;
      customChanges["like"]--;
    } else {
      isLike.value = true;
      customChanges["like"]++;

      isShowLikeAnimation.value = true;
      Vibration.vibrate(duration: 50, amplitude: 128);
      await 1200.milliseconds.delay();
      isShowLikeAnimation.value = false;
    }
    await ReelsLikeDislikeApi.callApi(
      loginUserId: Database.loginUserId,
      videoId: controller.mainReels[widget.index].id!,
    );
  }

  Future<void> onClickComment() async {
    isReelsPage.value = false;
    customChanges["comment"] = await CommentBottomSheetUi.show(
      context: context,
      commentType: 2,
      commentTypeId: controller.mainReels[widget.index].id!,
      totalComments: customChanges["comment"],
    );
  }

  // --------------------------------------------------------
  // NEW CART LOGIC START
  // --------------------------------------------------------

  void onClickCart() {
    isReelsPage.value = false;
    onStopVideo();

    // 1. Get Logged-in User's Email
    final storage = GetStorage();
    final userEmail = storage.read('user_email') ?? '';

    // 2. ✅ GET COIN FROM CUSTOM CLASS (The Fix)
    // We use the static reactive variable. It defaults to 0 if not set.
    final int userCoin = CustomFetchUserCoin.coin.value;

    // 2. Get Reel Poster's Details (User ID and Name)
    final shopUserId = controller.mainReels[widget.index].userId ?? '';
    final shopName = controller.mainReels[widget.index].name ?? ''; // Or use .userName for the handle

    // 3. Construct URL
    // Sending both ID and Name so the web page can use whichever it needs
    final webUrl = "https://kulclass.com/shop/buy.php?userEmail=$userEmail&userCoin=$userCoin&shopUserId=$shopUserId&shopName=$shopName";

    Utils.showLog("Opening Shop URL: $webUrl");

    // 4. Open WebView
    _showFullScreenWebView(context, webUrl);
  }

  void _showFullScreenWebView(BuildContext context, String url) {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      _openUrlInBrowser(url);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) {
          bool isLoading = true;

          // --- WEBVIEW CONTROLLER SETUP ---
          final webController = WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setNavigationDelegate(
              NavigationDelegate(
                onPageFinished: (_) {
                  // We need to update the UI (loader) safely
                  // Note: In a stateless/builder context, we might need a safer way to update state,
                  // but for this specific structure, we update the builder's state if possible,
                  // or relying on the initial load.
                  // Exactly using a ValueNotifier for isLoading to avoid complex State logic here.
                  isLoading = false;
                },

                // === NEW: INTERCEPT LINKS (The Fix) ===
                onNavigationRequest: (NavigationRequest request) async {
                  final String url = request.url;

                  // 1. Check for External App Schemes
                  if (url.startsWith('whatsapp:') ||
                      url.startsWith('intent:') ||
                      url.contains('api.whatsapp.com') ||
                      url.contains('wa.me') ||
                      url.startsWith('tg:') ||
                      url.startsWith('tel:') ||
                      url.startsWith('mailto:')) {

                    final Uri uri = Uri.parse(url);

                    // 2. Open Outside the App (in WhatsApp/Telegram/Dialer)
                    try {
                      // We force externalApplication mode
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } catch (e) {
                      debugPrint("Could not launch external app: $e");
                    }

                    // 3. STOP WebView from trying to load it (prevents crash)
                    return NavigationDecision.prevent;
                  }

                  // Allow normal websites to load
                  return NavigationDecision.navigate;
                },
              ),
            )
            ..loadRequest(Uri.parse(url));

          return StatefulBuilder(
            builder: (context, setState) {
              // We inject a listener to refresh the loader state when page finishes
              // This is a quick dirty fix to make the loader disappear inside StatefulBuilder
              webController.setNavigationDelegate(
                  NavigationDelegate(
                      onPageFinished: (_) {
                        if(context.mounted) {
                          setState(() { isLoading = false; });
                        }
                      },
                      // Re-attach the interception logic here because setNavigationDelegate overrides the previous one
                      onNavigationRequest: (NavigationRequest request) async {
                        final String url = request.url;
                        if (url.startsWith('whatsapp:') ||
                            url.startsWith('intent:') ||
                            url.contains('api.whatsapp.com') ||
                            url.startsWith('tg:') ||
                            url.startsWith('tel:')) {
                          try {
                            await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                          } catch (e) { debugPrint("Error: $e"); }
                          return NavigationDecision.prevent;
                        }
                        return NavigationDecision.navigate;
                      }
                  )
              );

              return Scaffold(
                appBar: AppBar(
                  backgroundColor: Colors.white,
                  title: const Text("Shop", style: TextStyle(color: Colors.black)),
                  leading: IconButton(
                    icon: const Icon(Icons.close, color: Colors.black),
                    onPressed: () {
                      Navigator.pop(context);
                      isReelsPage.value = true;
                      onPlayVideo();
                    },
                  ),
                ),
                body: Stack(
                  children: [
                    WebViewWidget(controller: webController),
                    if (isLoading)
                      const Center(child: CircularProgressIndicator()),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openUrlInBrowser(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar("Error", "Could not open the URL");
    }
  }
  // --------------------------------------------------------
  // NEW CART LOGIC END
  // --------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ReelsController>(
      id: "onGetReels",
      builder: (reelsController) {
        // Guard check to skip ad placeholders or invalid null items inserted into the list
        if (widget.index >= reelsController.mainReels.length || reelsController.mainReels[widget.index] == null) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        if (widget.index == widget.currentPageIndex) {
          isReadMore.value = false;
          (isVideoLoading.value == false && isReelsPage.value) ? onPlayVideo() : null;
        } else {
          isVideoLoading.value == false ? videoPlayerController?.seekTo(Duration.zero) : null;
          onStopVideo();
        }

        return Scaffold(
          body: SizedBox(
            height: Get.height,
            width: Get.width,
            child: Stack(
              children: [
                GestureDetector(
                  onTap: onClickVideo,
                  onDoubleTap: onDoubleClick,
                  child: Container(
                    color: AppColor.black,
                    height: (Get.height - AppConstant.bottomBarSize),
                    width: Get.width,
                    child: Obx(
                          () {
                        if (isVideoLoading.value || chewieController == null) {
                          return Align(
                            alignment: Alignment.bottomCenter,
                            child: LinearProgressIndicator(color: AppColor.primary),
                          );
                        }

                        return SizedBox.expand(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: videoPlayerController?.value.size.width ?? 0,
                              height: videoPlayerController?.value.size.height ?? 0,
                              child: Chewie(controller: chewieController!),
                            ),
                          ),
                        );
                      },
                    ),

                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).viewPadding.top + 15,
                  left: 20,
                  child: Visibility(
                      visible: Utils.isShowWaterMark,
                      child: CachedNetworkImage(
                        imageUrl: Utils.waterMarkIcon,
                        fit: BoxFit.contain,
                        imageBuilder: (context, imageProvider) => Image(
                          image: ResizeImage(imageProvider, width: Utils.waterMarkSize, height: Utils.waterMarkSize),
                          fit: BoxFit.contain,
                        ),
                        placeholder: (context, url) => const Offstage(),
                        errorWidget: (context, url, error) => const Offstage(),
                      )),
                ),
                Align(
                  alignment: Alignment.center,
                  child: SendGiftOnVideoBottomSheetUi.onShowGift(),
                ),
                Obx(
                      () => Visibility(
                    visible: isShowLikeAnimation.value,
                    child: Align(alignment: Alignment.center, child: Lottie.asset(AppAsset.lottieLike, fit: BoxFit.cover, height: 300, width: 300)),
                  ),
                ),
                Obx(
                      () => isShowIcon.value
                      ? Align(
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: onClickPlayPause,
                      child: Container(
                        height: 70,
                        width: 70,
                        padding: EdgeInsets.only(left: isPlaying.value ? 0 : 2),
                        decoration: BoxDecoration(color: AppColor.black.withOpacity(0.2), shape: BoxShape.circle),
                        child: Center(
                          child: Image.asset(
                            isPlaying.value ? AppAsset.icPause : AppAsset.icPlay,
                            width: 30,
                            height: 30,
                            color: AppColor.white,
                          ),
                        ),
                      ),
                    ),
                  )
                      : const Offstage(),
                ),
                // --- INTERACTIVE VIDEO PROGRESS SLIDER LAYER ---
                // --- CUSTOM INTERACTIVE VIDEO PROGRESS SLIDER & TIMERS ---

                Positioned(
                  bottom: 0,
                  child: Obx(
                        () => Visibility(
                      visible: (isVideoLoading.value == false),
                      child: Container(
                        height: Get.height / 4,
                        width: Get.width,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColor.transparent, AppColor.black.withOpacity(0.7)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  child: Container(
                    padding: Platform.isAndroid ? EdgeInsets.only(top: 30) : EdgeInsets.only(top: 46),
                    height: Get.height,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomIconButton(
                          circleSize: 40,
                          iconSize: 25,
                          icon: AppAsset.icCreate,
                          callback: () {
                            isReelsPage.value = false;
                            VideoPickerBottomSheetUi.show(context: context);
                          },
                        ),
                        5.width,
                        GestureDetector(
                          onTap: () {
                            isReelsPage.value = false;
                            ReportBottomSheetUi.show(context: context, eventId: reelsController.mainReels[widget.index].id ?? "", eventType: 1);
                          },
                          child: Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.more_vert_rounded,
                              color: AppColor.white,
                              size: 30,
                            ),
                          ),
                        ),
                        8.width,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.only(top: 30, bottom: 100),
                    height: Get.height,
                    child: Column(
                      children: [
                        const Spacer(),

                        5.height,
                        GestureDetector(
                          onTap: onClickCart,
                          child: Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                                Icons.shopping_cart,
                                color: Colors.white,
                                size: 32
                            ),
                          ),
                        ),
                        15.height,

                        Obx(
                              () => SizedBox(
                            height: 40,
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              height: isShowLikeIconAnimation.value ? 15 : 50,
                              width: isShowLikeIconAnimation.value ? 15 : 50,
                              alignment: Alignment.center,
                              child: CustomIconButton(
                                icon: AppAsset.icLike,
                                callback: onClickLike,
                                iconSize: 34,
                                iconColor: isLike.value ? AppColor.colorRedContainer : AppColor.white,
                              ),
                            ),
                          ),
                        ),
                        Obx(
                              () => Text(
                            CustomFormatNumber.convert(customChanges["like"]),
                            style: AppFontStyle.styleW700(AppColor.white, 14),
                          ),
                        ),
                        15.height,
                        CustomIconButton(icon: AppAsset.icComment, circleSize: 40, callback: onClickComment, iconSize: 34),
                        Obx(
                              () => Text(
                            CustomFormatNumber.convert(customChanges["comment"]),
                            style: AppFontStyle.styleW700(AppColor.white, 14),
                          ),
                        ),
                        15.height,
                        CustomIconButton(
                          circleSize: 40,
                          icon: AppAsset.icShare,
                          callback: onClickShare,
                          iconSize: 32,
                          iconColor: AppColor.white,
                        ),
                        Text(
                          "",
                          style: AppFontStyle.styleW700(AppColor.white, 14),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (reelsController.mainReels[widget.index].songId != "" && reelsController.mainReels[widget.index].songId != null) {
                              isReelsPage.value = false;
                              Get.toNamed(AppRoutes.audioWiseVideosPage, arguments: reelsController.mainReels[widget.index].songId);
                            } else if (reelsController.mainReels[widget.index].userId != Database.loginUserId) {
                              isReelsPage.value = false;
                              PreviewProfileBottomSheetUi.show(
                                context: context,
                                userId: reelsController.mainReels[widget.index].userId ?? "",
                              );
                            } else {
                              isReelsPage.value = false;
                              final controller = Get.find<BottomBarController>();
                              controller.onChangeBottomBar(4);
                            }
                          },
                          child: SizedBox(
                            width: 50,
                            child: Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                RotationTransition(turns: _animation, child: Image.asset(AppAsset.icMusicCd)),
                                RotationTransition(
                                  turns: _animation,
                                  child: Container(
                                    width: 30,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(shape: BoxShape.circle),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Image.asset(AppAsset.icProfilePlaceHolder),
                                        PreviewNetworkImageUi(image: reelsController.mainReels[widget.index].userImage),
                                        Visibility(
                                          visible: reelsController.mainReels[widget.index].isProfileImageBanned ?? false,
                                          child: AspectRatio(
                                            aspectRatio: 1,
                                            child: Container(
                                              clipBehavior: Clip.antiAlias,
                                              decoration: BoxDecoration(shape: BoxShape.circle),
                                              child: BlurryContainer(
                                                blur: 3,
                                                borderRadius: BorderRadius.circular(50),
                                                color: AppColor.black.withOpacity(0.3),
                                                child: Offstage(),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 4,
                                  bottom: -4,
                                  child: Image.asset(AppAsset.icMusic, width: 20),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 15,
                  bottom: 20,
                  child: SizedBox(
                    height: 400,
                    width: Get.width / 1.5,
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (reelsController.mainReels[widget.index].userId != Database.loginUserId) {
                                  isReelsPage.value = false;
                                  PreviewProfileBottomSheetUi.show(
                                    context: context,
                                    userId: reelsController.mainReels[widget.index].userId ?? "",
                                  );
                                } else {
                                  isReelsPage.value = false;
                                  final controller = Get.find<BottomBarController>();
                                  controller.onChangeBottomBar(4);
                                }
                              },
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 46,
                                    width: 46,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: const BoxDecoration(shape: BoxShape.circle),
                                    child: Stack(
                                      children: [
                                        AspectRatio(aspectRatio: 1, child: Image.asset(AppAsset.icProfilePlaceHolder)),
                                        AspectRatio(aspectRatio: 1, child: PreviewNetworkImageUi(image: reelsController.mainReels[widget.index].userImage)),
                                        Visibility(
                                          visible: reelsController.mainReels[widget.index].isProfileImageBanned ?? false,
                                          child: AspectRatio(
                                            aspectRatio: 1,
                                            child: Container(
                                              clipBehavior: Clip.antiAlias,
                                              decoration: BoxDecoration(shape: BoxShape.circle),
                                              child: BlurryContainer(
                                                blur: 3,
                                                borderRadius: BorderRadius.circular(50),
                                                color: AppColor.black.withOpacity(0.3),
                                                child: Offstage(),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  10.width,
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: Get.width / 2,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            Text(
                                              maxLines: 1,
                                              reelsController.mainReels[widget.index].name ?? "",
                                              style: AppFontStyle.styleW600(AppColor.white, 16.5),
                                            ),
                                            Visibility(
                                              visible: reelsController.mainReels[widget.index].isVerified ?? false,
                                              child: Padding(
                                                padding: const EdgeInsets.only(left: 3),
                                                child: Image.asset(AppAsset.icBlueTick, width: 20),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        width: Get.width / 2,
                                        child: Text(
                                          maxLines: 1,
                                          reelsController.mainReels[widget.index].userName ?? "",
                                          style: AppFontStyle.styleW500(AppColor.white, 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            10.height,
                            Visibility(
                              visible: reelsController.mainReels[widget.index].caption?.trim().isNotEmpty ?? false,
                              child: ReadMoreText(
                                reelsController.mainReels[widget.index].caption ?? "",
                                trimMode: TrimMode.Line,
                                trimLines: 3,
                                style: AppFontStyle.styleW500(AppColor.white, 13),
                                colorClickableText: AppColor.primary,
                                trimCollapsedText: ' Show more',
                                trimExpandedText: ' Show less',
                                moreStyle: AppFontStyle.styleW500(AppColor.primary, 13.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // --- CUSTOM INTERACTIVE VIDEO PROGRESS SLIDER (PLACED LAST TO PREVENT INTERFERENCE) ---
                Positioned(
                  bottom: 5, // Lays cleanly above bottom navigation bar without overlapping labels
                  left: 0,
                  right: 0,
                  child: Obx(
                        () => Visibility(
                      visible: (isVideoLoading.value == false && videoPlayerController != null),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Theme(
                            data: ThemeData(
                              sliderTheme: SliderThemeData(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                                activeTrackColor: AppColor.primary,
                                inactiveTrackColor: Colors.white.withOpacity(0.25),
                                thumbColor: AppColor.primary,
                                overlayColor: AppColor.primary.withOpacity(0.2),
                              ),
                            ),
                            child: Slider(
                              value: videoPosition.value.inMilliseconds.toDouble().clamp(
                                0.0,
                                videoPlayerController!.value.duration.inMilliseconds.toDouble(),
                              ),
                              min: 0.0,
                              max: videoPlayerController!.value.duration.inMilliseconds.toDouble() == 0.0
                                  ? 1.0
                                  : videoPlayerController!.value.duration.inMilliseconds.toDouble(),
                              onChanged: (value) {
                                final target = Duration(milliseconds: value.toInt());
                                videoPlayerController!.seekTo(target);
                                videoPosition.value = target; // Instant slide UI responsiveness
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(videoPosition.value),
                                  style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  _formatDuration(videoPlayerController!.value.duration),
                                  style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
