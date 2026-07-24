import 'package:get/get.dart';
import 'package:auralive/pages/audio_wise_videos_page/binding/audio_wise_videos_binding.dart';
import 'package:auralive/pages/audio_wise_videos_page/view/audio_wise_videos_view.dart';
import 'package:auralive/pages/bottom_bar_page/binding/bottom_bar_binding.dart';
import 'package:auralive/pages/bottom_bar_page/view/bottom_bar_view.dart';
import 'package:auralive/pages/chat_page/binding/chat_binding.dart';
import 'package:auralive/pages/chat_page/view/chat_view.dart';
import 'package:auralive/pages/connection_page/binding/connection_binding.dart';
import 'package:auralive/pages/connection_page/view/connection_view.dart';
import 'package:auralive/pages/create_reels_page/binding/create_reels_binding.dart';
import 'package:auralive/pages/create_reels_page/view/create_reels_view.dart';
import 'package:auralive/pages/edit_post_page/binding/edit_post_binding.dart';
import 'package:auralive/pages/edit_post_page/view/edit_post_view.dart';
import 'package:auralive/pages/edit_profile_page/binding/edit_profile_binding.dart';
import 'package:auralive/pages/edit_profile_page/view/edit_profile_view.dart';
import 'package:auralive/pages/edit_reels_page/binding/edit_reels_binding.dart';
import 'package:auralive/pages/edit_reels_page/view/edit_reels_view.dart';
import 'package:auralive/pages/fake_chat_page/binding/fake_chat_binding.dart';
import 'package:auralive/pages/fake_chat_page/view/fake_chat_view.dart';
import 'package:auralive/pages/fake_live_page/binding/fake_live_binding.dart';
import 'package:auralive/pages/fake_live_page/view/fake_live_view.dart';
import 'package:auralive/pages/feed_page/binding/feed_binding.dart';
import 'package:auralive/pages/feed_page/view/feed_view.dart';
import 'package:auralive/pages/fill_profile_page/binding/fill_profile_binding.dart';
import 'package:auralive/pages/fill_profile_page/view/fill_profile_view.dart';
import 'package:auralive/pages/go_live_page/binding/go_live_binding.dart';
import 'package:auralive/pages/go_live_page/view/go_live_view.dart';
import 'package:auralive/pages/help_page/binding/help_binding.dart';
import 'package:auralive/pages/help_page/view/help_view.dart';
import 'package:auralive/pages/language_page/binding/language_binding.dart';
import 'package:auralive/pages/language_page/view/language_view.dart';
import 'package:auralive/pages/live_page/binding/live_binding.dart';
import 'package:auralive/pages/live_page/view/live_view.dart';
import 'package:auralive/pages/login_page/binding/login_binding.dart';
import 'package:auralive/pages/login_page/view/login_view.dart';
import 'package:auralive/pages/message_page/binding/message_binding.dart';
import 'package:auralive/pages/message_page/view/message_view.dart';
import 'package:auralive/pages/message_request_page/binding/message_request_binding.dart';
import 'package:auralive/pages/message_request_page/view/message_request_view.dart';
import 'package:auralive/pages/mobile_num_login_page/binding/mobile_num_login_binding.dart';
import 'package:auralive/pages/mobile_num_login_page/view/mobile_num_login_view.dart';
import 'package:auralive/pages/my_qr_code_page/binding/my_qr_code_binding.dart';
import 'package:auralive/pages/my_qr_code_page/view/my_qr_code_view.dart';
import 'package:auralive/pages/my_wallet_page/binding/my_wallet_binding.dart';
import 'package:auralive/pages/my_wallet_page/view/my_wallet_view.dart';
import 'package:auralive/pages/on_boarding_page/binding/on_boarding_binding.dart';
import 'package:auralive/pages/on_boarding_page/view/on_boarding_view.dart';
import 'package:auralive/pages/payment_page/binding/payment_binding.dart';
import 'package:auralive/pages/payment_page/view/payment_view.dart';
import 'package:auralive/pages/preview_created_reels_page/binding/preview_created_reels_binding.dart';
import 'package:auralive/pages/preview_created_reels_page/view/preview_created_reels_view.dart';
import 'package:auralive/pages/preview_hash_tag_page/binding/preview_hash_tag_binding.dart';
import 'package:auralive/pages/preview_hash_tag_page/view/preview_hash_tag_view.dart';
import 'package:auralive/pages/preview_message_request_page/binding/preview_message_request_binding.dart';
import 'package:auralive/pages/preview_message_request_page/view/preview_message_request_view.dart';
import 'package:auralive/pages/preview_shorts_video_page/binding/preview_shorts_video_binding.dart';
import 'package:auralive/pages/preview_shorts_video_page/view/preview_shorts_video_view.dart';
import 'package:auralive/pages/preview_trim_video_page/binding/preview_trim_video_binding.dart';
import 'package:auralive/pages/preview_trim_video_page/view/preview_trim_video_view.dart';
import 'package:auralive/pages/preview_user_profile_page/binding/preview_user_profile_binding.dart';
import 'package:auralive/pages/preview_user_profile_page/view/preview_user_profile_view.dart';
import 'package:auralive/pages/privacy_policy_page/binding/privacy_policy_binding.dart';
import 'package:auralive/pages/privacy_policy_page/view/privacy_policy_view.dart';
import 'package:auralive/pages/profile_page/binding/profile_binding.dart';
import 'package:auralive/pages/profile_page/view/profile_view.dart';
import 'package:auralive/pages/recharge_page/binding/recharge_binding.dart';
import 'package:auralive/pages/recharge_page/view/recharge_view.dart';
import 'package:auralive/pages/reels_page/binding/reels_binding.dart';
import 'package:auralive/pages/reels_page/view/reels_view.dart';
import 'package:auralive/pages/scan_qr_code_page/binding/scan_qr_code_binding.dart';
import 'package:auralive/pages/scan_qr_code_page/view/scan_qr_code_view.dart';
import 'package:auralive/pages/search_page/binding/search_binding.dart';
import 'package:auralive/pages/search_page/view/search_view.dart';
import 'package:auralive/pages/setting_page/binding/setting_binding.dart';
import 'package:auralive/pages/setting_page/view/setting_view.dart';
import 'package:auralive/pages/splash_screen_page/binding/splash_screen_binding.dart';
import 'package:auralive/pages/splash_screen_page/view/splash_screen_view.dart';
import 'package:auralive/pages/stream_page/binding/stream_binding.dart';
import 'package:auralive/pages/stream_page/view/stream_view.dart';
import 'package:auralive/pages/terms_of_use_page/binding/terms_of_use_binding.dart';
import 'package:auralive/pages/terms_of_use_page/view/terms_of_use_view.dart';
import 'package:auralive/pages/trim_video_page/binding/trim_video_binding.dart';
import 'package:auralive/pages/trim_video_page/view/trim_video_view.dart';
import 'package:auralive/pages/upload_post_page/binding/upload_post_binding.dart';
import 'package:auralive/pages/upload_post_page/view/upload_post_view.dart';
import 'package:auralive/pages/upload_reels_page/binding/upload_reels_binding.dart';
import 'package:auralive/pages/upload_reels_page/view/upload_reels_view.dart';
import 'package:auralive/pages/verification_otp_page/binding/verification_otp_binding.dart';
import 'package:auralive/pages/verification_otp_page/view/verification_otp_view.dart';
import 'package:auralive/pages/verification_request_page/binding/verification_request_binding.dart';
import 'package:auralive/pages/verification_request_page/view/verification_request_view.dart';
import 'package:auralive/pages/withdraw_page/binding/withdraw_binding.dart';
import 'package:auralive/pages/withdraw_page/view/withdraw_view.dart';

import 'app_routes.dart';

class AppPages {
  static var list = [
    GetPage(
      name: AppRoutes.splashScreenPage,
      page: () => const SplashScreenView(),
      binding: SplashScreenBinding(),
    ),

    // >>>>> >>>>> >>>>> Login Pages <<<<< <<<<< <<<<<

    GetPage(
      name: AppRoutes.onBoardingPage,
      page: () => OnBoardingView(),
      binding: OnBoardingBinding(),
    ),
    GetPage(
      name: AppRoutes.loginPage,
      page: () => LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: AppRoutes.mobileNumLoginPage,
      page: () => MobileNumLoginView(),
      binding: MobileNumLoginBinding(),
    ),
    GetPage(
      name: AppRoutes.verificationOtpPage,
      page: () => VerificationOtpView(),
      binding: VerificationOtpBinding(),
    ),
    GetPage(
      name: AppRoutes.fillProfilePage,
      page: () => FillProfileView(),
      binding: FillProfileBinding(),
    ),

    // >>>>> >>>>> >>>>> Main Pages <<<<< <<<<< <<<<<

    GetPage(
      name: AppRoutes.bottomBarPage,
      page: () => const BottomBarView(),
      binding: BottomBarBinding(),
    ),
    GetPage(
      name: AppRoutes.reelsPage,
      page: () => const ReelsWebView(),
      binding: ReelsBinding(),
    ),
    GetPage(
      name: AppRoutes.streamPage,
      page: () => const StreamView(),
      binding: StreamBinding(),
    ),
    GetPage(
      name: AppRoutes.feedPage,
      page: () => const FeedView(),
      binding: FeedBinding(),
    ),
    GetPage(
      name: AppRoutes.messagePage,
      page: () => const MessageView(),
      binding: MessageBinding(),
    ),
    GetPage(
      name: AppRoutes.profilePage,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
    ),

    // >>>>> >>>>> >>>>> Reels Pages <<<<< <<<<< <<<<<

    GetPage(
      name: AppRoutes.createReelsPage,
      page: () => const CreateReelsView(),
      binding: CreateReelsBinding(),
    ),
    GetPage(
      name: AppRoutes.previewCreatedReelsPage,
      page: () => const PreviewCreatedReelsView(),
      binding: PreviewCreatedReelsBinding(),
    ),
    GetPage(
      name: AppRoutes.trimVideoPage,
      page: () => const TrimVideoView(),
      binding: TrimVideoBinding(),
    ),

    GetPage(
      name: AppRoutes.previewTrimVideoPage,
      page: () => const PreviewTrimVideoView(),
      binding: PreviewTrimVideoBinding(),
    ),
    GetPage(
      name: AppRoutes.uploadReelsPage,
      page: () => const UploadReelsView(),
      binding: UploadReelsBinding(),
    ),
    GetPage(
      name: AppRoutes.previewShortsVideoPage,
      page: () => const ShortsWebView(),
      binding: PreviewShortsVideoBinding(),
    ),

    // >>>>> >>>>> >>>>> Post Pages <<<<< <<<<< <<<<<

    GetPage(
      name: AppRoutes.uploadPostPage,
      page: () => const UploadPostView(),
      binding: UploadPostBinding(),
    ),

    // >>>>> >>>>> >>>>> Live Pages <<<<< <<<<< <<<<<

    GetPage(
      name: AppRoutes.goLivePage,
      page: () => const GoLiveView(),
      binding: GoLiveBinding(),
    ),
    GetPage(
      name: AppRoutes.livePage,
      page: () => const LiveView(),
      binding: LiveBinding(),
    ),

    // >>>>> >>>>> >>>>> Setting Pages <<<<< <<<<< <<<<<

    GetPage(
      name: AppRoutes.settingPage,
      page: () => const SettingView(),
      binding: SettingBinding(),
    ),
    GetPage(
      name: AppRoutes.languagePage,
      page: () => const LanguageView(),
      binding: LanguageBinding(),
    ),
    GetPage(
      name: AppRoutes.myWalletPage,
      page: () => const MyWalletView(),
      binding: MyWalletBinding(),
    ),
    GetPage(
      name: AppRoutes.myQrCodePage,
      page: () => const MyQrCodeView(),
      binding: MyQrCodeBinding(),
    ),
    GetPage(
      name: AppRoutes.verificationRequestPage,
      page: () => const VerificationRequestView(),
      binding: VerificationRequestBinding(),
    ),
    GetPage(
      name: AppRoutes.helpPage,
      page: () => const HelpView(),
      binding: HelpBinding(),
    ),
    GetPage(
      name: AppRoutes.privacyPolicyPage,
      page: () => const PrivacyPolicyView(),
      binding: PrivacyPolicyBinding(),
    ),
    GetPage(
      name: AppRoutes.termsOfUsePage,
      page: () => const TermsOfUseView(),
      binding: TermsOfUseBinding(),
    ),
    GetPage(
      name: AppRoutes.withdrawPage,
      page: () => const WithdrawView(),
      binding: WithdrawBinding(),
    ),
    GetPage(
      name: AppRoutes.rechargePage,
      page: () => const RechargeView(),
      binding: RechargeBinding(),
    ),
    GetPage(
      name: AppRoutes.paymentPage,
      page: () => const PaymentView(),
      binding: PaymentBinding(),
    ),

    // >>>>> >>>>> >>>>> Search Pages <<<<< <<<<< <<<<<

    GetPage(
      name: AppRoutes.searchPage,
      page: () => const SearchView(),
      binding: SearchBinding(),
    ),
    GetPage(
      name: AppRoutes.scanQrCodePage,
      page: () => const ScanQrCodeView(),
      binding: ScanQrCodeBinding(),
    ),
    GetPage(
      name: AppRoutes.previewHashTagPage,
      page: () => const PreviewHashTagView(),
      binding: PreviewHashTagBinding(),
    ),

    // >>>>> >>>>> >>>>> Edit Pages <<<<< <<<<< <<<<<

    GetPage(
      name: AppRoutes.editProfilePage,
      page: () => const EditProfileView(),
      binding: EditProfileBinding(),
    ),

    GetPage(
      name: AppRoutes.editReelsPage,
      page: () => const EditReelsView(),
      binding: EditReelsBinding(),
    ),

    GetPage(
      name: AppRoutes.editPostPage,
      page: () => const EditPostView(),
      binding: EditPostBinding(),
    ),

    // >>>>> >>>>> >>>>> Single Pages <<<<< <<<<< <<<<<

    GetPage(
      name: AppRoutes.chatPage,
      page: () => const ChatView(),
      binding: ChatBinding(),
    ),
    GetPage(
      name: AppRoutes.fakeChatPage,
      page: () => const FakeChatView(),
      binding: FakeChatBinding(),
    ),
    GetPage(
      name: AppRoutes.previewUserProfilePage,
      page: () => const PreviewUserProfileView(),
      binding: PreviewUserProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.connectionPage,
      page: () => const ConnectionView(),
      binding: ConnectionBinding(),
    ),
    GetPage(
      name: AppRoutes.fakeLivePage,
      page: () => const FakeLiveView(),
      binding: FakeLiveBinding(),
    ),
    GetPage(
      name: AppRoutes.messageRequestPage,
      page: () => const MessageRequestView(),
      binding: MessageRequestBinding(),
    ),
    GetPage(
      name: AppRoutes.previewMessageRequestPage,
      page: () => const PreviewMessageRequestView(),
      binding: PreviewMessageRequestBinding(),
    ),
    GetPage(
      name: AppRoutes.audioWiseVideosPage,
      page: () => const AudioWiseVideosView(),
      binding: AudioWiseVideosBinding(),
    ),
  ];
}
