import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:auralive/main.dart';
import 'package:auralive/ui/no_data_found_ui.dart';
import 'package:auralive/pages/reels_page/controller/reels_controller.dart';
import 'package:auralive/pages/reels_page/widget/reels_widget.dart';
import 'package:auralive/routes/app_routes.dart';
import 'package:auralive/shimmer/reels_shimmer_ui.dart';
import 'package:auralive/ui/video_picker_bottom_sheet_ui.dart';
import 'package:auralive/utils/color.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:auralive/utils/constant.dart';
import 'package:auralive/utils/enums.dart';
import 'package:auralive/utils/font_style.dart';

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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  150.height,
                  Spacer(),
                  const NoDataFoundUi(iconSize: 160, fontSize: 19),
                  Spacer(),
                  SizedBox(
                    height: 150,
                    width: Get.width,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(
                          child: Text(
                            EnumLocal.txtUploadYourFirstVideo.name.tr,
                            style: AppFontStyle.styleW500(AppColor.black, 17),
                          ),
                        ),
                        15.height,
                        GestureDetector(
                          onTap: () {
                            VideoPickerBottomSheetUi.show(context: context);
                          },
                          child: Container(
                            height: 45,
                            width: 120,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColor.primary, width: 1.5),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                8.width,
                                Icon(
                                  Icons.add_circle_outline_rounded,
                                  color: AppColor.primary,
                                  size: 27,
                                ),
                                8.width,
                                Text(EnumLocal.txtUpload.name.tr, style: AppFontStyle.styleW700(AppColor.primary, 17)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
            preloadPagesCount: 2,
            scrollDirection: Axis.vertical,
            onPageChanged: (value) async {
              controller.onPagination(value);
              controller.onChangePage(value);
            },
            itemBuilder: (context, index) {
              return


                GetBuilder<ReelsController>(
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
