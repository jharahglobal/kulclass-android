import 'package:get_storage/get_storage.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:auralive/pages/reels_page/controller/reels_controller.dart';
import 'package:auralive/utils/database.dart';
import 'package:auralive/utils/utils.dart';

class PreviewReelsView extends StatefulWidget {
  const PreviewReelsView({super.key, required this.index, required this.currentPageIndex});

  final int index;
  final int currentPageIndex;

  @override
  State<PreviewReelsView> createState() => _PreviewReelsViewState();
}

class _PreviewReelsViewState extends State<PreviewReelsView> {
  final controller = Get.find<ReelsController>();

  WebViewController? webViewController;
  RxBool isVideoLoading = true.obs;
  String? currentVideoUrl;

  @override
  void initState() {
    initializeWebView();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant PreviewReelsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index < controller.mainReels.length && controller.mainReels[widget.index] != null) {
      String newUserId = controller.mainReels[widget.index].userId ?? "";
      if (newUserId != currentVideoUrl) {
        currentVideoUrl = newUserId;
        isVideoLoading.value = true;
        initializeWebView();
      }
    }
  }

  Future<void> initializeWebView() async {
    try {
      if (widget.index >= controller.mainReels.length || controller.mainReels[widget.index] == null) {
        return;
      }

      final storage = GetStorage();
      final userEmail = storage.read('user_email') ?? '';
      final WebUserId = controller.mainReels[widget.index].userId ?? '';
      final WebName = controller.mainReels[widget.index].name ?? '';
      currentVideoUrl = WebUserId;

      final url = "https://kulclass.com/live.php?email=$userEmail&uid=$WebUserId&name=$WebName";
      Utils.showLog("🎯 Initialized Reels WebView URL: $url");

      webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) {
              isVideoLoading.value = false;
            },
          ),
        )
        ..loadRequest(Uri.parse(url));

      if (webViewController!.platform is AndroidWebViewController) {
        (webViewController!.platform as AndroidWebViewController).setMediaPlaybackRequiresUserGesture(false);
      }
      if (webViewController!.platform is WebKitWebViewController) {
        (webViewController!.platform as WebKitWebViewController).setAllowsInlineMediaPlayback(true);
      }
    } catch (e) {
      Utils.showLog("Reels WebView Initialization Failed !!! ${widget.index} => $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ReelsController>(
      id: "onGetReels",
      builder: (reelsController) {
        if (widget.index >= reelsController.mainReels.length || reelsController.mainReels[widget.index] == null) {
          return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Colors.white)));
        }

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              SizedBox.expand(
                child: Obx(
                  () {
                    if (isVideoLoading.value || webViewController == null) {
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    }
                    return WebViewWidget(controller: webViewController!);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
