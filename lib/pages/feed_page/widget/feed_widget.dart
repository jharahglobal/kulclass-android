import 'package:get_storage/get_storage.dart';
import 'package:auralive/custom/custom_fetch_user_coin.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:blurrycontainer/blurrycontainer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:readmore/readmore.dart';
import 'package:auralive/custom/custom_format_number.dart';
import 'package:auralive/custom/custom_share.dart';
import 'package:auralive/main.dart';
import 'package:auralive/pages/bottom_bar_page/controller/bottom_bar_controller.dart';
import 'package:auralive/pages/connection_page/api/follow_unfollow_api.dart';
import 'package:auralive/pages/feed_page/api/post_like_dislike_api.dart';
import 'package:auralive/pages/feed_page/api/post_share_api.dart';
import 'package:auralive/pages/feed_page/controller/feed_controller.dart';
import 'package:auralive/pages/feed_page/model/post_image_model.dart';
import 'package:auralive/routes/app_routes.dart';
import 'package:auralive/ui/comment_bottom_sheet_ui.dart';
import 'package:auralive/ui/gradient_text_ui.dart';
import 'package:auralive/ui/loading_ui.dart';
import 'package:auralive/ui/preview_image_ui.dart';
import 'package:auralive/ui/preview_network_image_ui.dart';
import 'package:auralive/ui/preview_profile_bottom_sheet_ui.dart';
import 'package:auralive/ui/report_bottom_sheet_ui.dart';
import 'package:auralive/utils/asset.dart';
import 'package:auralive/utils/branch_io_services.dart';
import 'package:auralive/utils/color.dart';
import 'package:auralive/utils/constant.dart';
import 'package:auralive/utils/database.dart';
import 'package:auralive/utils/enums.dart';
import 'package:auralive/utils/font_style.dart';
import 'package:auralive/utils/utils.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class PostView extends StatefulWidget {
  const PostView({
    super.key,
    required this.id,
    required this.userId,
    required this.profileImage,
    required this.postImages,
    required this.title,
    required this.subTitle,
    required this.time,
    required this.description,
    required this.hastTag,
    required this.isLike,
    required this.isFollow,
    required this.isVerified,
    required this.likes,
    required this.comments,
    required this.isFakeUser,
    required this.isProfileImageBanned,
  });

  final String id;
  final String userId;
  final String profileImage;
  final bool isProfileImageBanned;
  final List<PostImage> postImages;
  final String title;
  final String subTitle;
  final String time;
  final String description;

  final List hastTag;

  final bool isLike;
  final bool isVerified;
  final bool isFollow;
  final bool isFakeUser;

  final int likes;
  final int comments;

  @override
  State<PostView> createState() => _PostViewState();
}

class _PostViewState extends State<PostView> {
  RxBool isLike = false.obs;
  RxBool isFollow = false.obs;

  RxInt likes = 0.obs;
  RxInt comments = 0.obs;

  RxBool isShowLikeIconAnimation = false.obs;

  @override
  void initState() {
    isLike.value = widget.isLike;
    isFollow.value = widget.isFollow;

    likes.value = widget.likes;
    comments.value = widget.comments;
    super.initState();
  }

  // --------------------------------------------------------
  // NEW CART LOGIC START
  // --------------------------------------------------------
  void onClickCart() {
  final storage = GetStorage();

  final userEmail = storage.read('user_email') ?? '';
  final int userCoin = CustomFetchUserCoin.coin.value;

  final shopUserId = widget.userId;
  final shopName = widget.title;

  final webUrl =
    "https://kulclass.com/shop/buy.php"
    "?userEmail=${Uri.encodeComponent(userEmail)}"
    "&userCoin=$userCoin"
    "&shopUserId=${Uri.encodeComponent(shopUserId)}"
    "&shopName=${Uri.encodeComponent(shopName)}";

  Utils.showLog("Opening Shop URL: $webUrl");

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
                  // Ideally, use a ValueNotifier for isLoading to avoid complex State logic here.
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

  // --------------------------------------------------------
  // NEW CART LOGIC END
  // --------------------------------------------------------
// ADD IT HERE
  Future<void> _openUrlInBrowser(String url) async {
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  
  Future<void> onClickLike() async {
    if (isLike.value) {
      isLike.value = false;
      likes--;
    } else {
      isLike.value = true;
      likes++;
    }

    isShowLikeIconAnimation.value = true;
    await 500.milliseconds.delay();
    isShowLikeIconAnimation.value = false;

    await PostLikeDislikeApi.callApi(loginUserId: Database.loginUserId, postId: widget.id);
  }

  Future<void> onClickFollow() async {
    if (Database.loginUserId != widget.userId) {
      isFollow.value = !isFollow.value;
      await FollowUnfollowApi.callApi(loginUserId: Database.loginUserId, userId: widget.userId);
    } else {
      Utils.showToast(EnumLocal.txtYouCantFollowYourOwnAccount.name.tr);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: AppColor.colorBorderGrey.withOpacity(0.4)),
        ),
        color: AppColor.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              if (widget.userId != Database.loginUserId) {
                PreviewProfileBottomSheetUi.show(context: context, userId: widget.userId);
              } else {
                final bottomBarController = Get.find<BottomBarController>();
                bottomBarController.onChangeBottomBar(4);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              color: AppColor.colorTextGrey.withOpacity(0.12),
              // color: AppColor.colorGreyBg,
              width: Get.width,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    clipBehavior: Clip.antiAlias,
                    height: 42,
                    width: 42,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColor.colorBorder),
                    child: Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: Image.asset(AppAsset.icProfilePlaceHolder),
                        ),
                        AspectRatio(
                          aspectRatio: 1,
                          child: PreviewNetworkImageUi(image: widget.profileImage),
                        ),
                        Visibility(
                          visible: widget.isProfileImageBanned,
                          child: BlurryContainer(
                            height: Get.height,
                            width: Get.width,
                            blur: 3,
                            borderRadius: BorderRadius.circular(50),
                            color: AppColor.black.withOpacity(0.3),
                            child: Offstage(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: Get.width / 2.5,
                          child: Row(
                            children: [
                              Flexible(
                                fit: FlexFit.loose,
                                child: Text(
                                  widget.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppFontStyle.styleW700(AppColor.black, 14),
                                ),
                              ),
                              Visibility(
                                visible: widget.isVerified,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 2),
                                  child: Image.asset(AppAsset.icBlueTick, width: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: Get.width / 2.5,
                          child: Text(
                            maxLines: 1,
                            widget.subTitle,
                            style: AppFontStyle.styleW500(AppColor.colorGreyDarkText, 11),
                          ),
                        )
                      ],
                    ),
                  ),
                  const Spacer(),
                  Visibility(
                    visible: (widget.userId != Database.loginUserId),
                    child: GestureDetector(
                      onTap: onClickFollow,
                      child: Obx(
                        () => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: isFollow.value ? AppColor.primary : AppColor.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isFollow.value ? AppColor.transparent : AppColor.colorBorderGrey,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(isFollow.value ? AppAsset.icFollowing : AppAsset.icFollow, color: isFollow.value ? AppColor.white : null, width: 18),
                              5.width,
                              Text(
                                isFollow.value ? EnumLocal.txtFollowing.name.tr : EnumLocal.txtFollow.name.tr,
                                style: AppFontStyle.styleW500(isFollow.value ? AppColor.white : AppColor.primary, 14),
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
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                15.height,
                SizedBox(
                  height: Get.width / 2,
                  child: ListView.builder(
                    itemCount: widget.postImages.length,
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    scrollDirection: Axis.horizontal,
                    // physics: (),

                    // gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    //   crossAxisCount: 2,
                    //   crossAxisSpacing: 12,
                    //   mainAxisSpacing: 12,
                    //   childAspectRatio: 0.88,
                    // ),
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: () => Get.to(
                        PreviewImageUi(
                          name: widget.title,
                          userName: widget.subTitle,
                          userImage: widget.profileImage,
                          images: widget.postImages,
                          selectedIndex: index,
                          caption: widget.description,
                        ),
                      ),
                      child: Container(
                        clipBehavior: Clip.antiAlias,
                        height: Get.width / 2,
                        width: Get.width / 2.4,
                        margin: EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(color: AppColor.colorTextGrey.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                        child: Stack(
                          fit: StackFit.expand,
                          alignment: Alignment.center,
                          children: [
                            Center(child: Image.asset(AppAsset.icImagePlaceHolder, width: 100)),
                            Container(
                              clipBehavior: Clip.antiAlias,
                              height: Get.width / 2,
                              width: Get.width / 2.4,
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
                              child: PreviewNetworkImageUi(image: widget.postImages[index].url),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                widget.description.trim().isEmpty
                    ? Offstage()
                    : Column(
                        children: [
                          10.height,
                          ReadMoreText(
                            widget.description,
                            trimMode: TrimMode.Line,
                            trimLines: 3,
                            style: AppFontStyle.styleW500(AppColor.black, 15),
                            colorClickableText: AppColor.primary,
                            trimCollapsedText: ' Show more',
                            trimExpandedText: ' Show less',
                            moreStyle: AppFontStyle.styleW500(AppColor.primary, 15),
                          ),
                        ],
                      ),
                widget.hastTag.isEmpty
                    ? Offstage()
                    : Column(
                        children: [
                          8.height,
                          Wrap(
                            spacing: 8.0, // gap between adjacent chips
                            runSpacing: 4.0, // gap between lines
                            children: <Widget>[
                              for (int index = 0; index < widget.hastTag.length; index++)
                                Container(
                                  padding: const EdgeInsets.only(left: 12, right: 12, bottom: 2),
                                  margin: EdgeInsets.only(bottom: 3),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColor.colorBorderGrey, width: 1),
                                  ),
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '# ',
                                          style: AppFontStyle.styleW500(AppColor.primary, 15),
                                        ),
                                        TextSpan(
                                          text: widget.hastTag[index],
                                          style: AppFontStyle.styleW500(AppColor.colorGreyHasTagText, 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                5.height,
                Text(
                  widget.time,
                  style: AppFontStyle.styleW500(AppColor.colorGreyHasTagText.withOpacity(0.8), 12),
                ),
                8.height,
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: onClickLike,
                      child: Obx(
                        () => Container(
                          height: 30,
                          color: AppColor.transparent,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              AnimatedContainer(
                                duration: Duration(milliseconds: 300),
                                height: isShowLikeIconAnimation.value ? 12 : 30,
                                alignment: Alignment.center,
                                child: Image.asset(
                                  AppAsset.icLike,
                                  color: isLike.value ? AppColor.colorRedContainer : AppColor.colorUnselectedIcon,
                                  width: 24,
                                ),
                              ),
                              5.width,
                              Text(
                                CustomFormatNumber.convert(likes.value),
                                style: AppFontStyle.styleW700(AppColor.black, 15),
                              ),
                              5.width
                            ],
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        comments.value = await CommentBottomSheetUi.show(
                          context: context,
                          commentType: 1, // Comment Type 1 Means Post...
                          commentTypeId: widget.id,
                          totalComments: comments.value,
                        );
                      },
                      child: Obx(
                        () => Container(
                          height: 30,
                          color: AppColor.transparent,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Image.asset(
                                AppAsset.icComment,
                                color: AppColor.colorUnselectedIcon,
                                width: 24,
                              ),
                              5.width,
                              Text(
                                CustomFormatNumber.convert(comments.value),
                                style: AppFontStyle.styleW700(AppColor.black, 15),
                              ),
                              8.width
                            ],
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        Get.dialog(const LoadingUi(), barrierDismissible: false); // Start Loading...
                        await BranchIoServices.onCreateBranchIoLink(
                          id: widget.id,
                          name: widget.description,
                          image: widget.postImages[0].url ?? "",
                          userId: widget.userId,
                          pageRoutes: "Post",
                        );

                        final link = await BranchIoServices.onGenerateLink();

                        Get.back(); // Stop Loading...

                        if (link != null) {
                          CustomShare.onShareLink(link: link);
                        }
                        await PostShareApi.callApi(loginUserId: Database.loginUserId, postId: widget.id);
                      },
                      child: Container(
                        height: 30,
                        width: 38,
                        color: AppColor.transparent,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset(
                              AppAsset.icShare,
                              color: AppColor.colorUnselectedIcon,
                              width: 24,
                            ),
                          ],
                        ),
                      ),
                    ),

                     // *************************************
                    // NEW CART ICON ADDED HERE
                    // *************************************
                 
                    GestureDetector(
  onTap: onClickCart,
  child: Container(
    height: 30,
    width: 38,
    color: AppColor.transparent,
    alignment: Alignment.center,
    child: const Icon(
      Icons.shopping_cart,
      color: AppColor.colorUnselectedIcon,
      size: 24,
    ),
  ),
),
                    // *************************************END

                    
                    GestureDetector(
                      onTap: () {
                        ReportBottomSheetUi.show(context: context, eventId: widget.id, eventType: 2); // Post Report...
                      },
                      child: Container(
                        height: 30,
                        width: 50,
                        color: AppColor.transparent,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset(
                              AppAsset.icMore,
                              color: AppColor.colorUnselectedIcon,
                              width: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Visibility(
                      visible: (widget.userId != Database.loginUserId),
                      child: GestureDetector(
                        onTap: () {
                          if (widget.isFakeUser) {
                            Get.toNamed(
                              AppRoutes.fakeChatPage,
                              arguments: {
                                "id": widget.userId,
                                "name": widget.title,
                                "userName": widget.subTitle,
                                "image": widget.profileImage,
                                "isBlueTik": widget.isVerified,
                                "isProfileImageBanned": widget.isProfileImageBanned,
                              },
                            );
                          } else {
                            Get.toNamed(
                              AppRoutes.chatPage,
                              arguments: {
                                "id": widget.userId,
                                "name": widget.title,
                                "userName": widget.subTitle,
                                "image": widget.profileImage,
                                "isBlueTik": widget.isVerified,
                                "isProfileImageBanned": widget.isProfileImageBanned,
                              },
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: AppColor.primaryLinearGradient,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(AppAsset.icSayHey, width: 20),
                              Text(
                                ' ${EnumLocal.txtSayHi.name.tr}',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: AppColor.white,
                                  fontFamily: AppConstant.appFontBold,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget iconView({
  String? countText,
  required String image,
  Color? color,
}) {
  return Row(
    children: [
      Image.asset(image, color: color ?? AppColor.colorUnselectedIcon, width: 24),
      5.width,
      countText != null
          ? Text(
              countText,
              style: AppFontStyle.styleW700(AppColor.black, 15),
            )
          : const Offstage(),
    ],
  );
}

class FeedAppBarView extends GetView<FeedController> {
  const FeedAppBarView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            children: [
              GradientTextUi(
                gradient: AppColor.primaryLinearGradientText,
                EnumLocal.txtFeeds.name.tr,
                style: AppFontStyle.appBarStyle(),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Get.toNamed(AppRoutes.searchPage),
                    child: Container(
                      height: 42,
                      width: 42,
                      decoration: const BoxDecoration(gradient: AppColor.primaryLinearGradient, shape: BoxShape.circle),
                      child: Center(child: Image.asset(AppAsset.icSearch, width: 20)),
                    ),
                  ),
                  10.width,
                  GestureDetector(
                    onTap: () => controller.onPickPost(context),
                    child: Container(
                      height: 42,
                      width: 100,
                      decoration: BoxDecoration(gradient: AppColor.primaryLinearGradient, borderRadius: BorderRadius.circular(24)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(AppAsset.icCreatePlus, width: 24),
                          5.width,
                          Text(
                            EnumLocal.txtCreate.name.tr,
                            style: AppFontStyle.styleW600(AppColor.white, 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
