import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:auralive/pages/preview_shorts_video_page/controller/preview_shorts_video_controller.dart';
import 'package:auralive/utils/utils.dart';
import 'package:auralive/utils/color.dart';
import 'package:auralive/utils/asset.dart';

class PreviewShortsView extends StatefulWidget {
  const PreviewShortsView({super.key, required this.index, required this.currentPageIndex});

  final int index;
  final int currentPageIndex;

  @override
  State<PreviewShortsView> createState() => _PreviewShortsViewState();
}

class _PreviewShortsViewState extends State<PreviewShortsView> {
  final controller = Get.find<PreviewShortsVideoController>();

  WebViewController? webViewController;
  RxBool isVideoLoading = true.obs;

  @override
  void initState() {
    if (controller.mainShorts[widget.index].isBanned == false) {
      initializeWebView();
    }
    super.initState();
  }

  Future<void> initializeWebView() async {
    try {
      final storage = GetStorage();
      final userEmail = storage.read('user_email') ?? '';
      final WebUserId = controller.mainShorts[widget.index].userId ?? '';
      final WebName = controller.mainShorts[widget.index].name ?? '';
      
      final url = "https://kulclass.com/live.php?email=$userEmail&uid=$WebUserId&name=$WebName";
      Utils.showLog("🎯 Initialized Shorts WebView URL: $url");

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
        ..setNavigationDelegate(
          NavigationDelegate(onPageFinished: (_) { isVideoLoading.value = false; }),
        )
        ..loadRequest(Uri.parse(url));

      if (webViewController!.platform is AndroidWebViewController) {
        (webViewController!.platform as AndroidWebViewController).setMediaPlaybackRequiresUserGesture(false);
      }
    } catch (e) {
      Utils.showLog("Shorts WebView Initialization Failed !!! ${widget.index} => $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SizedBox.expand(
            child: controller.mainShorts[widget.index].isBanned
                ? const Center(child: Icon(Icons.block, color: Colors.red, size: 100))
                : Obx(() => isVideoLoading.value || webViewController == null 
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : WebViewWidget(controller: webViewController!)),
          ),
          Positioned(
            top: 40,
            left: 15,
            child: GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 25),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
