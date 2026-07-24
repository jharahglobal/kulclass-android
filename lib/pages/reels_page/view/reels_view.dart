import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:auralive/ui/no_data_found_ui.dart';
import 'package:auralive/pages/reels_page/controller/reels_controller.dart';
import 'package:auralive/pages/reels_page/widget/reels_widget.dart';
import 'package:auralive/routes/app_routes.dart';
import 'package:auralive/shimmer/reels_shimmer_ui.dart';
import 'package:auralive/utils/color.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:auralive/utils/constant.dart';

class ReelsView extends GetView<ReelsController> {
  const ReelsView({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColor.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      body: GetBuilder<ReelsController>(
        id: "onGetReels",
        builder: (controller) => controller.isLoadingReels
            ? ReelsShimmerUi()
            : controller.mainReels.isEmpty
            ? RefreshIndicator(
          color: AppColor.primary,
          onRefresh: () async => await controller.init(),
          child: SingleChildScrollView(
            child: SizedBox(
              height: (Get.height + 1) - AppConstant.bottomBarSize,
              child: const Center(
                child: NoDataFoundUi(iconSize: 160, fontSize: 19),
              ),
            ),
          ),
        )
            : RefreshIndicator(
          color: AppColor.primary,
          onRefresh: () async {
            await 400.milliseconds.delay();
            await controller.init();
          },
          child: PreloadPageView.builder(
            controller: controller.preloadPageController,
            itemCount: controller.mainReels.length,
            preloadPagesCount: 1,
            scrollDirection: Axis.vertical,
            onPageChanged: (value) async {
              controller.onPagination(value);
              controller.onChangePage(value);
            },
            itemBuilder: (context, index) {
              return GetBuilder<ReelsController>(
                id: "onChangePage",
                builder: (controller) => PreviewReelsView(
                  index: index,
                  currentPageIndex: controller.currentPageIndex,
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: GetBuilder<ReelsController>(
        id: "onPagination",
        builder: (controller) => Visibility(
          visible: controller.isPaginationLoading,
          child: LinearProgressIndicator(color: AppColor.primary),
        ),
      ),
    );
  }
}
