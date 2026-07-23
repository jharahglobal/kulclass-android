import 'package:get/get.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:auralive/google_ad/google_ad_services.dart';
import 'package:auralive/pages/reels_page/api/fetch_reels_api.dart';
import 'package:auralive/pages/reels_page/model/fetch_reels_model.dart';
import 'package:auralive/routes/app_routes.dart';
import 'package:auralive/utils/branch_io_services.dart';
import 'package:auralive/utils/database.dart';

import '../../bottom_bar_page/controller/bottom_bar_controller.dart';

class ReelsController extends GetxController {
  PreloadPageController preloadPageController = PreloadPageController();

  bool isLoadingReels = false;
  FetchReelsModel? fetchReelsModel;

  bool isPaginationLoading = false;

  List mainReels = []; // *** >>> Google Ad Code <<< ***
  // List<Data> mainReels = [];

  int currentPageIndex = 0;
  final quickAction = QuickActions();
  BottomBarController controller = Get.put(BottomBarController());

  @override
  void onInit() {
    super.onInit();
    init();

    quickAction.setShortcutItems([
      ShortcutItem(
        type: 'reel',
        localizedTitle: 'Reel',
        icon: "reel",
      ),
      ShortcutItem(
        type: 'chat',
        localizedTitle: 'Chat',
        icon: "message",
      ),
      ShortcutItem(
        type: 'feeds',
        localizedTitle: 'Feeds',
        icon: "feed",
      ),
      ShortcutItem(
        type: 'search',
        localizedTitle: 'Search',
        icon: "search",
      ),
    ]);

    quickAction.initialize(
          (type) {
        if (type == 'reel') {
          controller.onChangeBottomBar(0);
        } else if (type == 'chat') {
          controller.onChangeBottomBar(3);
        } else if (type == 'feeds') {
          controller.onChangeBottomBar(2);
        } else if (type == 'search') {
          // controller.onChangeBottomBar(0);
          Get.toNamed(AppRoutes.searchPage);
        }
      },
    );
  }

  @override
  void onReady() {
    super.onReady();
  }

  Future<void> init() async {
    try {
      Utils.showLog("ReelsController init() called. isLoadingReels: $isLoadingReels");
      if (isLoadingReels) return;

      isLoadingReels = true;
      update(["onGetReels"]);
      
      currentPageIndex = 0;
      mainReels.clear();
      FetchReelsApi.startPagination = 0;
      
      await onGetReels();
      Utils.showLog("ReelsController init() completed. mainReels length: ${mainReels.length}");
    } catch (e) {
      Utils.showLog("ReelsController init() error: $e");
    } finally {
      isLoadingReels = false;
      update(["onGetReels"]);
    }
  }

  void onPagination(int value) async {
    if (mainReels.isEmpty) return;
    if ((mainReels.length - 1) == value) {
      if (isPaginationLoading == false) {
        isPaginationLoading = true;
        update(["onPagination"]);
        await onGetReels();
        isPaginationLoading = false;
        update(["onPagination"]);
      }
    }
  }

  void onChangePage(int index) async {
    currentPageIndex = index;
    update(["onChangePage"]);
  }

  Future<void> onGetReels() async {
    try {
      Utils.showLog("ReelsController onGetReels() called. loginUserId: ${Database.loginUserId}, eventId: ${BranchIoServices.eventId}");
      fetchReelsModel = null;
      fetchReelsModel = await FetchReelsApi.callApi(loginUserId: Database.loginUserId, videoId: BranchIoServices.eventId);

      if (fetchReelsModel?.data != null) {
        if (fetchReelsModel!.data!.isNotEmpty) {
          final paginationData = fetchReelsModel?.data ?? [];

          // <<< Code Start *** >>> Google Ad Code <<< ***
          if (GoogleAdServices.isShowFullNativeAdReels) {
            for (int i = 0; i < paginationData.length; i++) {
              if (i != 0 && i % GoogleAdServices.adShowIndex == 0) {
                mainReels.add(null);
                mainReels.add(paginationData[i]);
              } else {
                mainReels.add(paginationData[i]);
              }
            }
          } else {
            mainReels.addAll(paginationData);
          }
          // *** >>> Google Ad Code <<< *** Code End >>>

          update(["onGetReels"]);
        }
      }
      if (mainReels.isEmpty) {
        update(["onGetReels"]);
      }
    } catch (e) {
      Utils.showLog("ReelsController onGetReels() error: $e");
    }
  }
}
