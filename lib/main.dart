import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'firebase_options.dart';
import 'app/core/utils/ad_service.dart';
import 'app/core/utils/analytics_service.dart';
import 'app/core/utils/auth_service.dart';
import 'app/core/utils/firestore_service.dart';
import 'app/core/utils/iap_service.dart';
import 'app/core/utils/session_service.dart';
import 'app/core/translations/app_translations.dart';
import 'app/routes/app_pages.dart';
import 'app/theme/app_theme.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // Crashlytics — yakalanmamış Flutter hatalarını otomatik raporla
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // ATT: iOS 14.5+ için izin iste (MobileAds.initialize'dan önce)
    if (Platform.isIOS) {
      await AppTrackingTransparency.requestTrackingAuthorization();
    }

    // GDPR/UMP: AB kullanıcıları için onay akışı
    await _requestUmpConsent();

    await MobileAds.instance.initialize();
    await Get.putAsync(() => SessionService().init());
    await Get.putAsync(() => AuthService().init());
    await Get.putAsync(() => FirestoreService().init());
    await Get.putAsync(() => AdService().init());
    await Get.putAsync(() => IAPService().init());
    await Get.putAsync(() => AnalyticsService().init());
    runApp(const OrbriotApp());
  }, (error, stack) {
    // Dart zone'unda yakalanmamış hatalar
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}

Future<void> _requestUmpConsent() async {
  final completer = Completer<void>();
  ConsentInformation.instance.requestConsentInfoUpdate(
    ConsentRequestParameters(),
    () async {
      if (await ConsentInformation.instance.isConsentFormAvailable()) {
        ConsentForm.loadAndShowConsentFormIfRequired((_) {
          if (!completer.isCompleted) completer.complete();
        });
      } else {
        if (!completer.isCompleted) completer.complete();
      }
    },
    (_) {
      if (!completer.isCompleted) completer.complete();
    },
  );
  return completer.future;
}

Locale _deviceLocale() {
  final lang = PlatformDispatcher.instance.locale.languageCode;
  if (lang == 'tr') return const Locale('tr', 'TR');
  return const Locale('en', 'US');
}

class OrbriotApp extends StatelessWidget {
  const OrbriotApp({super.key});

  @override
  Widget build(BuildContext context) {
    final analytics = Get.find<AnalyticsService>();
    return GetMaterialApp(
      title: 'Orbriot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      translations: AppTranslations(),
      locale: _deviceLocale(),
      fallbackLocale: const Locale('en', 'US'),
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      navigatorObservers: [analytics.observer],
    );
  }
}
