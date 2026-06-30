import 'package:blurrycontainer/blurrycontainer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:readmore/readmore.dart';
import 'package:auralive/custom/custom_fetch_user_coin.dart';
import 'package:auralive/custom/custom_icon_button.dart';
import 'package:auralive/custom/custom_share.dart';
import 'package:auralive/main.dart';
import 'package:auralive/pages/bottom_bar_page/controller/bottom_bar_controller.dart';
import 'package:auralive/pages/preview_shorts_video_page/controller/preview_shorts_video_controller.dart';
import 'package:auralive/pages/profile_page/controller/profile_controller.dart';
import 'package:auralive/pages/reels_page/api/reels_like_dislike_api.dart';
import 'package:auralive/pages/reels_page/api/reels_share_api.dart';
import 'package:auralive/pages/splash_screen_page/api/send_gift_api.dart';
import 'package:auralive/routes/app_routes.dart';
import 'package:auralive/ui/comment_bottom_sheet_ui.dart';
import 'package:auralive/ui/loading_ui.dart';
import 'package:auralive/ui/preview_network_image_ui.dart';
import 'package:auralive/ui/preview_profile_bottom_sheet_ui.dart';
import 'package:auralive/ui/reels_more_option_bottom_sheet.dart';
import 'package:auralive/ui/report_bottom_sheet_ui.dart';
import 'package:auralive/ui/video_picker_bottom_sheet_ui.dart';
import 'package:auralive/utils/asset.dart';
import 'package:auralive/utils/branch_io_services.dart';
import 'package:auralive/utils/color.dart';
import 'package:auralive/utils/database.dart';
import 'package:auralive/utils/enums.dart';
import 'package:auralive/utils/font_style.dart';
import 'package:auralive/utils/utils.dart';
import 'package:vibration/vibration.dart';
import 'package:video_player/video_player.dart';

class PreviewShortsView extends StatefulWidget {
  const PreviewShortsView({super.key, required this.index, required this.currentPageIndex});

  final int index;
  final int currentPageIndex;

  @override
  State<PreviewShortsView> createState() => _PreviewShortsViewState();
}

class _PreviewShortsViewState extends State<PreviewShortsView> with SingleTickerProviderStateMixin {
  final controller = Get.find<PreviewShortsVideoController>();

  ChewieController? chewieController;
  VideoPlayerController? videoPlayerController;

  RxBool isPlaying = true.obs;
  RxBool isShowIcon = false.obs;

  RxBool isBuffering = false.obs;
  RxBool isVideoLoading = true.obs;

  RxBool isReelsPage = true.obs; // This is Use to Stop Auto Playing..

  RxBool isLike = false.obs;
  RxMap customChanges = {"like": 0, "comment": 0}.obs;

  RxBool isShowLikeAnimation = false.obs;
  RxBool isShowLikeIconAnimation = false.obs;

  AnimationController? _controller;
  late Animation<double> _animation;

  RxBool isReadMore = false.obs;

  final profileController = Get.find<ProfileController>();

  @override
  void initState() {
    if (controller.mainShorts[widget.index].isBanned == false) {
      initializeVideoPlayer();
    }
    customSetting();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    if (_controller != null) {
      _animation = Tween(begin: 0.0, end: 1.0).animate(_controller!);
    }

    super.initState();
  }

  @override
  void dispose() {
    _controller?.dispose();
    onDisposeVideoPlayer();
    Utils.showLog("Dispose Method Called Success");
    super.dispose();
  }

  Future<void> initializeVideoPlayer() async {
    try {
      String videoPath = controller.mainShorts[widget.index].videoUrl;

      videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(videoPath));

      await videoPlayerController?.initialize();

      if (videoPlayerController != null && (videoPlayerController?.value.isInitialized ?? false)) {
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
          (widget.index == widget.currentPageIndex && isReelsPage.value) ? onPlayVideo() : null; // Use => First Time Video Playing...
        } else {
          isVideoLoading.value = true;
        }

        videoPlayerController?.addListener(
          () {
            // Use => If Video Buffering then show loading....
            videoPlayerController!.value.isBuffering ? isBuffering.value = true : isBuffering.value = false;

            if (isReelsPage.value == false) {
              onStopVideo(); // Use => On Change Routes...
            }
          },
        );
      }
    } catch (e, stack) {
  print("========== VIDEO INIT ERROR ==========");
  print("INDEX: ${widget.index}");
  print("URL: ${controller.mainShorts[widget.index].videoUrl}");
  print("ERROR: $e");
  print("STACK: $stack");
  print("=====================================");

  onDisposeVideoPlayer();
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
      onStopVideo();
      videoPlayerController?.dispose();
      chewieController?.dispose();
      chewieController = null;
      videoPlayerController = null;
      isVideoLoading.value = true;
    } catch (e) {
      Utils.showLog(">>>> On Dispose VideoPlayer Error => $e");
    }
  }

  void customSetting() {
    isLike.value = controller.mainShorts[widget.index].isLike;
    customChanges["like"] = int.parse(controller.mainShorts[widget.index].likes.toString());
    customChanges["comment"] = int.parse(controller.mainShorts[widget.index].comments.toString());
  }

  void onClickVideo() async {
    // Use => Video Banned
    if (controller.mainShorts[widget.index].isBanned == false) {
      if (isVideoLoading.value == false) {
        videoPlayerController!.value.isPlaying ? onStopVideo() : onPlayVideo();
        isShowIcon.value = true;
        await 2.seconds.delay();
        isShowIcon.value = false;
      }
      if (isReelsPage.value == false) {
        isReelsPage.value = true; // Use => On Back Reels Page...
      }
    }
  }

  void onClickPlayPause() async {
    videoPlayerController!.value.isPlaying ? onStopVideo() : onPlayVideo();
    if (isReelsPage.value == false) {
      isReelsPage.value = true; // Use => On Back Reels Page...
    }
  }

  Future<void> onClickShare() async {
    if (controller.mainShorts[widget.index].isBanned == false) {
      isReelsPage.value = false;

      Get.dialog(const LoadingUi(), barrierDismissible: false); // Start Loading...
      await BranchIoServices.onCreateBranchIoLink(
        id: controller.mainShorts[widget.index].videoId,
        name: controller.mainShorts[widget.index].caption,
        image: controller.mainShorts[widget.index].videoImage,
        userId: controller.mainShorts[widget.index].userId,
        pageRoutes: "Video",
      );

      final link = await BranchIoServices.onGenerateLink();

      Get.back(); // Stop Loading...

      if (link != null) {
        CustomShare.onShareLink(link: link);
      }

      await ReelsShareApi.callApi(loginUserId: Database.loginUserId, videoId: controller.mainShorts[widget.index].videoId);
    }
  }

  Future<void> onClickLike() async {
    if (controller.mainShorts[widget.index].isBanned == false) {
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
        videoId: controller.mainShorts[widget.index].videoId,
      );
    }
  }

  Future<void> onDoubleClick() async {
    if (controller.mainShorts[widget.index].isBanned == false) {
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
        videoId: controller.mainShorts[widget.index].videoId,
      );
    }
  }

  Future<void> onClickComment() async {
    if (controller.mainShorts[widget.index].isBanned == false) {
      isReelsPage.value = false;
      customChanges["comment"] = await CommentBottomSheetUi.show(
        context: context,
        commentType: 2,
        commentTypeId: controller.mainShorts[widget.index].videoId,
        totalComments: customChanges["comment"],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Future.delayed(
      Duration(milliseconds: 300),
      () {
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: AppColor.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
        );
      },
    );

    if (widget.index == widget.currentPageIndex) {
      // Use => Play Current Video On Scrolling...
      isReadMore.value = false;
      (isVideoLoading.value == false && isReelsPage.value) ? onPlayVideo() : null;
    } else {
      // Restart Previous Video On Scrolling...
      isVideoLoading.value == false ? videoPlayerController?.seekTo(Duration.zero) : null;
      onStopVideo(); // Stop Previous Video On Scrolling...
    }

    return Scaffold(
      body: SizedBox(
        height: Get.height,
        width: Get.width,
        child: Stack(
          children: [
            Positioned(
              bottom: 0,
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
            controller.mainShorts[widget.index].isBanned
                ? Container(
                    color: AppColor.black,
                    height: Get.height,
                    width: Get.width,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: Get.height,
                          width: Get.width,
                          child: PreviewNetworkImageUi(
                            image: controller.mainShorts[widget.index].videoImage,
                          ),
                        ),
                        Container(
                          color: AppColor.black.withOpacity(0.65),
                          height: Get.height,
                          width: Get.width,
                        ),
                        Image.asset(
                          AppAsset.icNone,
                          height: 150,
                          width: 150,
                          color: AppColor.colorRedContainer,
                        ),
                      ],
                    ),
                  )
                : Obx(
                    () => isVideoLoading.value
                        ? Container(
                            color: AppColor.black,
                            height: Get.height,
                            width: Get.width,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  height: Get.height,
                                  width: Get.width,
                                  child: PreviewNetworkImageUi(
                                    image: controller.mainShorts[widget.index].videoImage,
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: LinearProgressIndicator(
                                    color: AppColor.primary,
                                    backgroundColor: AppColor.white.withOpacity(0.5),
                                  ),
                                )
                              ],
                            ),
                          )
                        : GestureDetector(
                            onTap: onClickVideo,
                            onDoubleTap: onDoubleClick,
                            child: Container(
                              color: AppColor.transparent,
                              height: Get.height,
                              width: Get.width,
                              child: SizedBox.expand(
                                child: FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: videoPlayerController?.value.size.width ?? 0,
                                    height: videoPlayerController?.value.size.height ?? 0,
                                    child: Chewie(controller: chewieController!),
                                  ),
                                ),
                              ),
                            ),
                          ),
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
            Positioned(
              // Logo Water Mark Code
              top: MediaQuery.of(context).viewPadding.top + 50,
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
            Positioned(
              top: 30,
              left: 15,
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  height: 50,
                  width: 50,
                  decoration: const BoxDecoration(
                    color: AppColor.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Image.asset(AppAsset.icBack, color: AppColor.white, width: 25)),
                ),
              ),
            ),
            Positioned(
              right: 0,
              child: Container(
                padding: const EdgeInsets.only(top: 30),
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
                        if (controller.mainShorts[widget.index].isBanned == false) {
                          isReelsPage.value = false;

                          if (controller.mainShorts[widget.index].userId == Database.loginUserId) {
                            ReelsMoreOptionBottomSheet.show(
                                context: context,
                                reportCallBack: () {
                                  Get.back();
                                  ReportBottomSheetUi.show(context: context, eventId: controller.mainShorts[widget.index].videoId, eventType: 1);
                                },
                                deleteCallBack: () {
                                  Get.back();
                                  profileController.onClickDeleteReels(videoId: controller.mainShorts[widget.index].videoId);
                                },
                                editCallBack: () {
                                  Get.back();
                                  Get.toNamed(
                                    AppRoutes.editReelsPage,
                                    arguments: {"video": controller.mainShorts[widget.index].videoUrl, "image": controller.mainShorts[widget.index].videoImage, "caption": controller.mainShorts[widget.index].caption, "videoId": controller.mainShorts[widget.index].videoId},
                                  );
                                });
                          } else {
                            ReportBottomSheetUi.show(context: context, eventId: controller.mainShorts[widget.index].videoId, eventType: 1);
                          }
                        }
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
                padding: const EdgeInsets.only(top: 30, bottom: 20),
                height: Get.height,
                child: Column(
                  children: [
                    const Spacer(),

                    10.height,
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
                            iconSize: 32,
                            iconColor: isLike.value ? AppColor.colorRedContainer : AppColor.white,
                          ),
                        ),
                      ),
                    ),
                    Obx(
                      () => Text(
                        customChanges["like"].toString(),
                        style: AppFontStyle.styleW700(AppColor.white, 14),
                      ),
                    ),
                    15.height,
                    CustomIconButton(
                      circleSize: 40,
                      icon: AppAsset.icComment,
                      callback: onClickComment,
                      iconSize: 32,
                    ),
                    Obx(
                      () => Text(
                        customChanges["comment"].toString(),
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
                      onTap: () async {
                        Utils.showLog("Song Id => ${controller.mainShorts[widget.index].songId}");
                        isReelsPage.value = false;
                        if (controller.previousPageIsAudioWiseVideoPage) {
                          Get.back();
                        } else if (controller.mainShorts[widget.index].songId != "") {
                          Get.offAndToNamed(AppRoutes.audioWiseVideosPage, arguments: controller.mainShorts[widget.index].songId);
                        } else if (controller.mainShorts[widget.index].userId != Database.loginUserId) {
                          PreviewProfileBottomSheetUi.show(
                            context: context,
                            userId: controller.mainShorts[widget.index].userId,
                          );
                        } else {
                          Get.offAllNamed(AppRoutes.bottomBarPage);
                          await 300.milliseconds.delay();
                          final bottomBarController = Get.find<BottomBarController>();
                          bottomBarController.onChangeBottomBar(4);
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
                                    PreviewNetworkImageUi(image: controller.mainShorts[widget.index].userImage),
                                    Visibility(
                                      visible: controller.mainShorts[widget.index].isProfileImageBanned,
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
                      children: [
                        GestureDetector(
                          onTap: () async {
                            isReelsPage.value = false;
                            if (controller.mainShorts[widget.index].userId != Database.loginUserId) {
                              PreviewProfileBottomSheetUi.show(
                                context: context,
                                userId: controller.mainShorts[widget.index].userId,
                              );
                            } else {
                              Get.offAllNamed(AppRoutes.bottomBarPage);
                              await 300.milliseconds.delay();
                              final bottomBarController = Get.find<BottomBarController>();
                              bottomBarController.onChangeBottomBar(4);
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
                                    AspectRatio(
                                      aspectRatio: 1,
                                      child: Image.asset(AppAsset.icProfilePlaceHolder),
                                    ),
                                    AspectRatio(
                                      aspectRatio: 1,
                                      child: PreviewNetworkImageUi(image: controller.mainShorts[widget.index].userImage),
                                    ),
                                    Visibility(
                                      visible: controller.mainShorts[widget.index].isProfileImageBanned,
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
                                    child: Text(
                                      maxLines: 1,
                                      controller.mainShorts[widget.index].name,
                                      style: AppFontStyle.styleW600(AppColor.white, 16.5),
                                    ),
                                  ),
                                  SizedBox(
                                    width: Get.width / 2,
                                    child: Text(
                                      maxLines: 1,
                                      controller.mainShorts[widget.index].userName,
                                      style: AppFontStyle.styleW500(AppColor.white, 13),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                        10.height,
                        Visibility(
                          visible: controller.mainShorts[widget.index].caption.trim().isNotEmpty,
                          child: ReadMoreText(
                            controller.mainShorts[widget.index].caption,
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
          ],
        ),
      ),
    );
  }
}

// Visibility(
//   visible: controller.mainShorts[widget.index].hashTag.isNotEmpty,
//   child: Column(
//     children: [
//       SizedBox(
//         width: Get.width / 2,
//         child: Text(
//           maxLines: 2,
//           controller.mainShorts[widget.index].hashTag.map((e) => "$e").join(',').toString(),
//           style: AppFontStyle.styleW500(AppColor.white, 13),
//         ),
//       ),
//       10.height,
//     ],
//   ),
// ),

// Visibility(
// visible: controller.mainShorts[widget.index].caption.trim().isNotEmpty,
// child: Obx(
// () => GestureDetector(
// onTap: () => isReadMore.value = !isReadMore.value,
// child: AnimatedContainer(
// duration: Duration(milliseconds: 300),
// curve: Curves.linear,
// height: isReadMore.value ? 130 : 52,
// alignment: Alignment.topLeft,
// width: Get.width / 2,
// child: SingleChildScrollView(
// child: Text(
// (controller.mainShorts[widget.index].caption),
// style: AppFontStyle.styleW600(AppColor.white, 13),
// ),
// ),
// ),
// ),
// ),
// ),
