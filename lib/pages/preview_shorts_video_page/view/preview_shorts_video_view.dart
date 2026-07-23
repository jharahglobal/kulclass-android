import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:auralive/ui/no_data_found_ui.dart';
import 'package:auralive/pages/preview_shorts_video_page/controller/preview_shorts_video_controller.dart';
import 'package:auralive/pages/preview_shorts_video_page/widget/preview_shorts_video_widget.dart';
import 'package:auralive/shimmer/preview_shorts_video_shimmer_ui.dart';
import 'package:auralive/utils/color.dart';
import 'package:preload_page_view/preload_page_view.dart';

class PreviewShortsVideoView extends GetView<PreviewShortsVideoController> {
  const PreviewShortsVideoView({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(
      Duration(milliseconds: 100),
      () {
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: AppColor.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
        );
      },
    );

    return Scaffold(
      body: GetBuilder<PreviewShortsVideoController>(
        id: "onGetShorts",
        builder: (controller) => controller.isLoading
            ? PreviewShortsVideoShimmerUi()
            : controller.mainShorts.isEmpty
                ? NoDataFoundUi(iconSize: 140, fontSize: 16)
                : PreloadPageView.builder(
                    controller: controller.preloadPageController,
                    itemCount: controller.mainShorts.length,
                    preloadPagesCount: 2,
                    scrollDirection: Axis.vertical,
                    onPageChanged: (value) async {
                      controller.onChangePage(value);
                    },
                    itemBuilder: (context, index) {
                      return GetBuilder<PreviewShortsVideoController>(
                        id: "onChangePage",
                        builder: (controller) => PreviewShortsView(
                          index: index,
                          currentPageIndex: controller.currentPageIndex,
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
