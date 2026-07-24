import 'package:blurrycontainer/blurrycontainer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:auralive/custom/custom_format_number.dart';
import 'package:auralive/main.dart';
import 'package:auralive/pages/profile_page/controller/profile_controller.dart';
import 'package:auralive/routes/app_routes.dart';
import 'package:auralive/shimmer/grid_view_shimmer_ui.dart';
import 'package:auralive/shimmer/post_list_shimmer_ui.dart';
import 'package:auralive/ui/no_data_found_ui.dart';
import 'package:auralive/ui/preview_image_ui.dart';
import 'package:auralive/ui/preview_network_image_ui.dart';
import 'package:auralive/utils/asset.dart';
import 'package:auralive/utils/color.dart';
import 'package:auralive/utils/database.dart';
import 'package:auralive/utils/font_style.dart';
import 'package:auralive/utils/utils.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:auralive/custom/svga_simple_image.dart';

class ProfileAppBarUi extends StatelessWidget {
  const ProfileAppBarUi({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();
    return SafeArea(
      bottom: false,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            40.width,
            Spacer(),
            Obx(
              () => Visibility(
                visible: controller.isTabBarPinned.value,
                child: Text(
                  controller.fetchProfileModel?.userProfileData?.user?.name ?? "",
                  style: AppFontStyle.styleW700(AppColor.black, 19),
                ),
              ),
            ),
            Spacer(),
            GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.settingPage),
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(border: Border.all(color: AppColor.colorBorder), shape: BoxShape.circle),
                child: Center(child: Image.asset(AppAsset.icSetting, width: 20)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReelsTabView extends StatefulWidget {
  const ReelsTabView({super.key});

  @override
  State<ReelsTabView> createState() => _ReelsTabViewState();
}

class _ReelsTabViewState extends State<ReelsTabView> {
  WebViewController? webViewController;
  bool isPageLoading = true;

  @override
  void initState() {
    super.initState();
    initializeWebView();
  }

  Future<void> initializeWebView() async {
    try {
      final storage = GetStorage();
      final userEmail = storage.read('user_email') ?? '';
      final webUserId = Database.loginUserId;
      final webName = Database.fetchLoginUserProfileModel?.user?.name ?? '';

      final url = "https://kulclass.com/profile_reels.php?email=$userEmail&uid=$webUserId&name=$webName";
      Utils.showLog("🎯 Loading Profile Reels WebView: $url");

      late final PlatformWebViewControllerCreationParams params;
      if (WebViewPlatform.instance is WebKitWebViewPlatform) {
        params = WebKitWebViewControllerCreationParams(
          allowsInlineMediaPlayback: true,
        );
      } else {
        params = const PlatformWebViewControllerCreationParams();
      }

      webViewController = WebViewController.fromPlatformCreationParams(params)
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setUserAgent("Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.5735.196 Mobile Safari/537.36")
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) {
              if (mounted) setState(() => isPageLoading = false);
            },
          ),
        )
        ..loadRequest(Uri.parse(url));

      if (webViewController!.platform is AndroidWebViewController) {
        (webViewController!.platform as AndroidWebViewController).setMediaPlaybackRequiresUserGesture(false);
      }
    } catch (e) {
      Utils.showLog("Profile Reels WebView Initialization Failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (webViewController != null)
          WebViewWidget(controller: webViewController!),
        if (isPageLoading)
          const Center(child: CircularProgressIndicator(color: AppColor.primary)),
      ],
    );
  }
}

class FeedsTabView extends StatelessWidget {
  const FeedsTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      id: "onGetPost",
      builder: (controller) => controller.isLoadingPost
          ? PostListShimmerUi()
          : controller.postCollection.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    child: const NoDataFoundUi(
                      iconSize: 140,
                      fontSize: 16,
                    ),
                  ),
                )
              : GridView.builder(
                  itemCount: controller.postCollection.length,
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.88,
                  ),
                  itemBuilder: (context, index) {
                    return AspectRatio(
                      aspectRatio: 0.88,
                      child: GestureDetector(
                        onTap: () {
                          Get.to(
                            PreviewImageUi(
                              name: Database.fetchLoginUserProfileModel?.user?.name ?? "",
                              userName: Database.fetchLoginUserProfileModel?.user?.userName ?? "",
                              userImage: Database.fetchLoginUserProfileModel?.user?.image ?? "",
                              images: controller.postCollection[index].postImage ?? [],
                              id: controller.postCollection[index].id,
                              caption: controller.postCollection[index].caption,
                              selectedIndex: 0,
                            ),
                          );
                        },
                        child: Container(
                          color: AppColor.colorTextGrey.withOpacity(0.1),
                          child: AspectRatio(
                            aspectRatio: 0.88,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Image.asset(AppAsset.icImagePlaceHolder, width: 70),
                                AspectRatio(
                                  aspectRatio: 0.88,
                                  child: PreviewNetworkImageUi(image: controller.postCollection[index].mainPostImage),
                                ),
                                Align(
                                  alignment: Alignment.topCenter,
                                  child: Container(
                                    height: Get.height,
                                    width: Get.width,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [AppColor.transparent, AppColor.black.withOpacity(0.5)],
                                        end: Alignment.topCenter,
                                        begin: Alignment.bottomCenter,
                                      ),
                                    ),
                                  ),
                                ),
                                // Visibility(
                                //   visible: (controller.postCollection[index].postImage?.any((item) => item.isBanned == true) ?? false),
                                //   child: Container(
                                //     height: Get.height,
                                //     alignment: Alignment.bottomRight,
                                //     decoration: BoxDecoration(
                                //       color: AppColor.black.withOpacity(0.65),
                                //     ),
                                //     child: Padding(
                                //       padding: const EdgeInsets.all(8.0),
                                //       child: Image.asset(AppAsset.icNone, color: AppColor.colorRedContainer, width: 20),
                                //     ),
                                //   ),
                                // ),
                                Visibility(
                                  visible: (controller.postCollection[index].postImage?.any((item) => item.isBanned == true) ?? false),
                                  child: BlurryContainer(
                                    height: Get.height,
                                    width: Get.width,
                                    blur: 5,
                                    borderRadius: BorderRadius.zero,
                                    color: AppColor.black.withOpacity(0.3),
                                    child: Offstage(),
                                  ),
                                ),
                                Visibility(
                                  visible: !(controller.postCollection[index].postImage?.length == 1),
                                  child: Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Image.asset(
                                      AppAsset.icMultipleImage,
                                      color: AppColor.white,
                                      width: 25,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class CollectionsTabView extends StatelessWidget {
  const CollectionsTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      id: "onGetCollection",
      builder: (controller) => controller.isLoadingCollection
          ? GridViewShimmerUi()
          : controller.giftCollection.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    child: const NoDataFoundUi(
                      iconSize: 140,
                      fontSize: 16,
                    ),
                  ),
                )
              : GridView.builder(
                  itemCount: controller.giftCollection.length,
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  itemBuilder: (context, index) {
                    return Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: AppColor.white,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: AppColor.colorBorder),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          5.height,
                          controller.giftCollection[index].giftType == 1 || controller.giftCollection[index].giftType == 2
                              ? Expanded(
                                  child: PreviewNetworkImageUi(image: controller.giftCollection[index].giftImage ?? ""),
                                )
                              : controller.giftCollection[index].giftType == 3
                                  ? Expanded(child: SizedBox(width: Get.width, child: SVGAImageWrapper(resUrl: controller.giftCollection[index].giftImage ?? "")))
                                  : Offstage(),
                          5.height,
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColor.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "${CustomFormatNumber.convert(controller.giftCollection[index].giftCoin ?? 0)} Coins",
                              style: AppFontStyle.styleW700(AppColor.primary, 12),
                            ),
                          ),
                          8.height,
                          Container(
                            height: 35,
                            width: Get.width,
                            decoration: const BoxDecoration(
                              gradient: AppColor.primaryLinearGradient,
                              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                            ),
                            child: Center(
                              child: Text(
                                "X ${CustomFormatNumber.convert(controller.giftCollection[index].total ?? 0)}",
                                style: AppFontStyle.styleW600(AppColor.white, 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
