import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'dart:convert'; // ✅ needed for jsonEncode

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';
import 'package:auralive/pages/splash_screen_page/api/admin_setting_api.dart';
import 'package:auralive/localization/locale_constant.dart';
import 'package:auralive/localization/localizations_delegate.dart';
import 'package:auralive/routes/app_pages.dart';
import 'package:auralive/routes/app_routes.dart';
import 'package:auralive/utils/color.dart';
import 'package:auralive/utils/constant.dart';
import 'package:auralive/utils/database.dart';
import 'package:auralive/utils/enums.dart';
import 'package:auralive/utils/internet_connection.dart';
import 'package:auralive/utils/notification_services.dart';
import 'package:auralive/utils/platform_device_id.dart';
import 'package:auralive/utils/utils.dart';

/// ✅ Top-level background handler (required by Firebase)
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    try {
      Utils.showLog(">>> Initializing Firebase in BACKGROUND...");
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      Utils.showLog(">>> Firebase initialized in BACKGROUND");
    } catch (e, s) {
      Utils.showLog("Firebase BACKGROUND init failed: $e");
      await FirebaseCrashlytics.instance.recordError(e, s, fatal: true);
      return;
    }
  }
  Utils.showLog("🔥 Background message: ${message.messageId}");
}


Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }


      // Register background handler ONCE
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      await NotificationServices.init();
      await onInitializeCrashlytics();
    } catch (e, s) {
      Utils.showLog("Firebase Initialization Failed: ${e.runtimeType} - $e");
      Utils.showLog("Stack trace: $s");

      if (kDebugMode) {
        rethrow;
      } else {
        await _logInitFailureRemotely(e, s);
        runApp(MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text(
                "Fatal Error: Could not initialize Firebase.",
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ));
      }
      return;
    }

    // Other async initializations
    await GetStorage.init();
    await InternetConnection.init();
    await onInitializeBranchIo();
    BranchIoServices.onListenBranchIoLinks();

    final identity = await PlatformDeviceId.getDeviceId;
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (identity != null && fcmToken != null) {
      await Database.init(identity, fcmToken);
    }

    if (Platform.isAndroid || Platform.isIOS) {
      await NotificationServices.firebaseInit();
    }

    await AdminSettingsApi.callApi();

    // 2️⃣ Initialize Zego Engine after settings are ready
    if (AdminSettingsApi.adminSettingModel?.data != null) {
      await Utils.onInitCreateEngine();
    } else {
      Utils.showLog("⚠️ Admin settings returned null — Zego init skipped.");
    }

    final initialRoute = (Database.isNewUser == false &&
        Database.fetchLoginUserProfileModel?.user?.id != null)
        ? AppRoutes.bottomBarPage
        : AppRoutes.onBoardingPage;

    runApp(MyApp(initialRoute: initialRoute));
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    Utils.showLog("FATAL ERROR: $error");
  });
}

Future<void> _logInitFailureRemotely(Object e, StackTrace s) async {
  try {
    final url = Uri.parse("https://yourserver.com/firebase-init-logs");
    final req = await HttpClient().postUrl(url);
    req.headers.contentType = ContentType.json;
    req.write(jsonEncode({
      "platform": Platform.operatingSystem,
      "error": e.toString(),
      "stack": s.toString(),
      "timestamp": DateTime.now().toIso8601String(),
    }));
    await req.close();
  } catch (err) {
    debugPrint("Failed to send remote log: $err");
  }
}

class MyApp extends StatefulWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    Utils.isAppOpen.value = true;
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    Utils.isAppOpen.value = false;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Utils.isAppOpen.value = true;
      Utils.showLog("User Back To App...");
    }
    if (state == AppLifecycleState.inactive) {
      Utils.isAppOpen.value = false;
      Utils.showLog("User Try To Exit...");
    }
  }

  @override
  void didChangeDependencies() {
    getLocale().then((locale) {
      setState(() {
        Utils.showLog("Preference LanguageCode => ${locale.languageCode}");
        Get.updateLocale(locale);
      });
    });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColor.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    return GetMaterialApp(
      title: EnumLocal.txtAppName.name.tr,
      debugShowCheckedModeBanner: false,
      color: AppColor.white,
      translations: AppLanguages(),
      fallbackLocale:
      const Locale(AppConstant.languageEn, AppConstant.countryCodeEn),
      locale: const Locale(AppConstant.languageEn),
      defaultTransition: Transition.fade,
      getPages: AppPages.list,
      initialRoute: widget.initialRoute,
    );
  }
}

// >>>>>> SizedBox Extensions <<<<<<
extension HeightExtension on num {
  SizedBox get height => SizedBox(height: toDouble());
}

extension WidthExtension on num {
  SizedBox get width => SizedBox(width: toDouble());
}

// Crashlytics
Future<void> onInitializeCrashlytics() async {
  try {
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      FlutterError.onError = (errorDetails) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    } else {
      Utils.showLog("Crashlytics not supported on this platform");
    }
  } catch (e) {
    Utils.showLog("Initialize Crashlytics Failed !! => $e");
  }
}

// Branch IO
Future<void> onInitializeBranchIo() async {
  try {
    await FlutterBranchSdk.init();

    if (kDebugMode) {
      // Only validate integration when debugging
      FlutterBranchSdk.validateSDKIntegration();
    }
  } catch (e) {
    Utils.showLog("Initialize Branch Io Failed !! => $e");
  }
}
