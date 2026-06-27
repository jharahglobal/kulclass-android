import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:auralive/pages/upload_reels_page/widget/upload_reels_widget.dart';
import 'package:auralive/shimmer/caption_shimmer_ui.dart';
import 'package:auralive/ui/app_button_ui.dart';
import 'package:auralive/main.dart';
import 'package:auralive/pages/upload_reels_page/controller/upload_reels_controller.dart';
import 'package:auralive/ui/loading_ui.dart';
import 'package:auralive/ui/simple_app_bar_ui.dart';
import 'package:auralive/utils/asset.dart';
import 'package:auralive/utils/color.dart';
import 'package:auralive/size_extension.dart';
import 'package:auralive/utils/enums.dart';
import 'package:auralive/utils/font_style.dart';

class UploadReelsView extends StatelessWidget {
  const UploadReelsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UploadReelsController>();
    return Scaffold(
      backgroundColor: AppColor.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColor.white,
        shadowColor: AppColor.black.withOpacity(0.4),
        surfaceTintColor: AppColor.transparent,
        flexibleSpace: SimpleAppBarUi(title: EnumLocal.txtUploadReels.name.tr),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            15.height,
            Container(
              height: 210,
              width: 160,
              clipBehavior: Clip.antiAlias,
              margin: EdgeInsets.only(left: 15),
              decoration: BoxDecoration(
                color: AppColor.colorBorder.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: SizedBox(
                height: 210,
                width: 160,
                child: GetBuilder<UploadReelsController>(
                  id: "onChangeThumbnail",
                  builder: (controller) => Image.file(
                    File(controller.videoThumbnail),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            15.height,
            InkWell(
              onTap: () => controller.onChangeThumbnail(context),
              child: Container(
                height: 55,
                width: Get.width,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                margin: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: AppColor.colorBorder.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColor.colorBorder.withOpacity(0.6)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(AppAsset.icChangeThumbnail, width: 20, color: AppColor.primary),
                    15.width,
                    Text(
                      EnumLocal.txtChangeThumbnail.name.tr,
                      style: AppFontStyle.styleW700(AppColor.black, 15),
                    ),
                    Spacer(),
                    Image.asset(AppAsset.icArrowRight, width: 20),
                  ],
                ),
              ),
            ),
            15.height,
            Container(
              color: Colors.transparent,
              width: Get.width,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: RichText(
                      text: TextSpan(
                        text: EnumLocal.txtCaption.name.tr,
                        style: AppFontStyle.styleW700(AppColor.black, 15),
                        children: [
                          TextSpan(
                            text: " ${EnumLocal.txtOptionalInBrackets.name.tr}",
                            style: AppFontStyle.styleW400(AppColor.coloGreyText, 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            5.height,
            GestureDetector(
              onTap: () {
                Get.to(
                  PreviewReelsCaptionUi(),
                  transition: Transition.downToUp,
                  duration: Duration(milliseconds: 300),
                );
              },
              child: GetBuilder<UploadReelsController>(
                id: "onChangeHashtag",
                builder: (controller) => Container(
                  height: 130,
                  width: Get.width,
                  padding: const EdgeInsets.only(left: 15, top: 5),
                  margin: EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: AppColor.colorBorder.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColor.colorBorder.withOpacity(0.8)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: controller.captionController.text.isNotEmpty
                              ? RichText(
                                  text: TextSpan(
                                    children: _buildTextSpans(controller.captionController.text),
                                  ),
                                )
                              : Text(
                                  EnumLocal.txtEnterYourTextWithHashtag.name.tr,
                                  style: AppFontStyle.styleW400(AppColor.coloGreyText, 15),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppButtonUi(
        title: EnumLocal.txtUpload.name.tr,
        gradient: AppColor.primaryLinearGradient,
        callback: () {
          FocusManager.instance.primaryFocus?.unfocus();
          controller.onUploadReels();
        },
      ).paddingSymmetric(horizontal: Get.width / 6.5, vertical: 25),
    );
  }
}

List<TextSpan> _buildTextSpans(String text) {
  List<TextSpan> spans = [];
  final RegExp hashtagRegex = RegExp(r'(#\w+)');
  final List<String> parts = text.split(hashtagRegex);
  final Iterable<RegExpMatch> matches = hashtagRegex.allMatches(text);

  int currentPosition = 0;
  for (final match in matches) {
    // Add text before the hashtag
    if (match.start > currentPosition) {
      spans.add(TextSpan(
        text: text.substring(currentPosition, match.start),
        style: AppFontStyle.styleW600(AppColor.black, 15),
      ));
    }

    // Add the hashtag
    spans.add(TextSpan(
      text: match.group(0),
      style: AppFontStyle.styleW700(AppColor.primary, 15),
    ));

    currentPosition = match.end;
  }

  // Add remaining text after last hashtag
  if (currentPosition < text.length) {
    spans.add(TextSpan(
      text: text.substring(currentPosition),
      style: AppFontStyle.styleW600(AppColor.black, 15),
    ));
  }

  // If no hashtags, just return the whole text as black
  if (spans.isEmpty) {
    spans.add(TextSpan(
      text: text,
      style: AppFontStyle.styleW600(AppColor.black, 15),
    ));
  }

  return spans;
}

// >>>>>>>>>>>>>>>>>>>>>>>> Old Hashtag Function <<<<<<<<<<<<<<<<<<<<<<<<<<<<<

// CaptionTextFieldUi(
//   height: 130,
//   title: EnumLocal.txtCaption.name.tr,
//   maxLines: 4,
//   controller: controller.captionController,
//   enabled: false,
//   onClick: () {
//     Get.to(
//       PreviewReelsCaptionUi(),
//       transition: Transition.downToUp,
//       duration: Duration(milliseconds: 300),
//     );
//   },
// ),

// Container(
//   padding: const EdgeInsets.symmetric(horizontal: 15),
//   margin: const EdgeInsets.only(bottom: 10, top: 10),
//   color: AppColor.colorBorder.withOpacity(0.2),
//   child: TextFormField(
//     maxLines: 5,
//     style: AppFontStyle.styleW600(AppColor.black, 15),
//     controller: controller.captionController,
//     cursorColor: AppColor.primary,
//     keyboardType: TextInputType.multiline,
//     decoration: InputDecoration(
//       hintText: EnumLocal.txtWhatsOnYourMind.name.tr,
//       hintStyle: AppFontStyle.styleW400(AppColor.coloGreyText, 15),
//       border: InputBorder.none,
//     ),
//   ),
// ),

// InkWell(
//   onTap: () {
//     FocusManager.instance.primaryFocus?.unfocus();
//     reelsHashTagBottomSheet();
//   },
//   child: Container(
//     height: 50,
//     width: Get.width,
//     padding: const EdgeInsets.symmetric(horizontal: 15),
//     decoration: BoxDecoration(
//       color: AppColor.transparent,
//       border: Border.symmetric(
//         horizontal: BorderSide(color: AppColor.colorBorderGrey.withOpacity(0.6)),
//       ),
//     ),
//     child: Row(
//       mainAxisAlignment: MainAxisAlignment.start,
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         Text(
//           "#",
//           style: AppFontStyle.styleW600(AppColor.primary, 24),
//         ),
//         18.width,
//         Text(
//           EnumLocal.txtAddTopic.name.tr,
//           style: AppFontStyle.styleW700(AppColor.black, 15),
//         ),
//         Spacer(),
//         Image.asset(AppAsset.icArrowRight, width: 20),
//       ],
//     ),
//   ),
// ),
// UploadTextFiledUi(
// title: EnumLocal.txtHashTag.name.tr,
// maxLines: 1,
// controller: controller.hashTagController,
// onChanged: () => controller.onChangeHashTag(),
// ),
// 10.height,
// GetBuilder<UploadReelsController>(
// id: "onSelectHastTag",
// builder: (logic) => Padding(
// padding: const EdgeInsets.symmetric(horizontal: 15),
// child: Wrap(
// spacing: 15,
// alignment: WrapAlignment.start,
// children: [
// for (int index = 0; index < logic.selectedHashTag.length; index++)
// Chip(
// padding: const EdgeInsets.only(top: 7, bottom: 7, right: 7),
// shape: RoundedRectangleBorder(
// borderRadius: BorderRadius.circular(50),
// ),
// deleteIconColor: AppColor.black,
// onDeleted: () => logic.onCancelHashTag(index),
// elevation: 0,
// autofocus: false,
// deleteIcon: Padding(
// padding: const EdgeInsets.only(right: 4),
// child: Image.asset(AppAsset.icClose),
// ),
// backgroundColor: AppColor.grey_100,
// side: const BorderSide(width: 0.8, color: AppColor.transparent),
// label: RichText(
// text: TextSpan(
// text: " # ",
// style: AppFontStyle.styleW600(AppColor.primary, 16),
// children: [
// TextSpan(
// text: logic.selectedHashTag[index].hashTag,
// style: AppFontStyle.styleW700(AppColor.black, 13),
// ),
// ],
// ),
// ),
// ),
// ],
// ),
// ),
// ),
