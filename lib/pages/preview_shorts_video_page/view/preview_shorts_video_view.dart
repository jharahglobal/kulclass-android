import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:auralive/utils/database.dart';
import 'package:auralive/utils/utils.dart';

class PreviewShortsVideoView extends StatefulWidget {
  const PreviewShortsVideoView({super.key});

  @override
  State<PreviewShortsVideoView> createState() => _PreviewShortsVideoViewState();
}

class _PreviewShortsVideoViewState extends State<PreviewShortsVideoView> {
  WebViewController? webViewController;

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

      final url = "https://kulclass.com/live.php?email=$userEmail&uid=$webUserId&name=$webName";
      Utils.showLog("🎯 Loading Shorts WebView: $url");

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
        ..setBackgroundColor(Colors.black) // Prevents white flash
        ..setUserAgent("Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.5735.196 Mobile Safari/537.36")
        ..loadRequest(Uri.parse(url));

      if (webViewController!.platform is AndroidWebViewController) {
        (webViewController!.platform as AndroidWebViewController).setMediaPlaybackRequiresUserGesture(false);
      }
    } catch (e) {
      Utils.showLog("Shorts WebView Initialization Failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (webViewController != null)
            SizedBox.expand(
              child: WebViewWidget(controller: webViewController!),
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
