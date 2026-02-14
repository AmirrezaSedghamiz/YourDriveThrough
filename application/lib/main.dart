import 'package:application/GlobalWidgets/AppTheme/Colors.dart';
import 'package:application/GlobalWidgets/AppTheme/Theme.dart';
import 'package:application/GlobalWidgets/NavigationServices/NavigationService.dart';
import 'package:application/GlobalWidgets/Services/Map.dart';
import 'package:application/Handlers/Repository/ManagerRepo.dart';
import 'package:application/Handlers/SharePreferencesManager.dart';
import 'package:application/Handlers/TokenHandler.dart';
import 'package:application/MainProgram/Customer/DashboardCustomer/DashboardCustomer.dart';
import 'package:application/MainProgram/Customer/MainPage/MainPage.dart';
import 'package:application/MainProgram/Customer/Profile/Profile.dart';
import 'package:application/MainProgram/Customer/RestaurantMenu/RestaurantMenu.dart';
import 'package:application/MainProgram/Login/Login.dart';
import 'package:application/MainProgram/Manager/DashboardManager/DashboardManager.dart';
import 'package:application/MainProgram/SplashScreen/SplashScreen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tapsell_plus/tapsell_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferencesManager.instance.init();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await dotenv.load(fileName: ".env");
  try {
    await TapsellPlus.instance.initialize(dotenv.env['TAPSELL_KEY'] ?? "");
    await TapsellPlus.instance.setGDPRConsent(true);
    TapsellPlus.instance.setDebugMode(LogLevel.Debug);
    debugPrint('Tapsell initialized');
  } catch (e) {
    debugPrint('Tapsell failed: $e');
  }
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      systemNavigationBarColor: AppColors.white,
      systemNavigationBarContrastEnforced: false, // 👈 important for Android 14/15
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NavigationService.navigatorKey,
      theme: AppTheme.lightTheme,
      home: SplashScreen(),
    );
  }
}

class InitService {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    debugPrint('InitService started');
    await _safe(_initAds);
    debugPrint('InitService finished');
  }

  static Future<void> _initAds() async {
    if (kIsWeb) return;

    debugPrint('📢 Initializing ads...');

    try {
      await TapsellPlus.instance.initialize(dotenv.env['TAPSELL_KEY'] ?? "");
      await TapsellPlus.instance.setGDPRConsent(true);
      TapsellPlus.instance.setDebugMode(LogLevel.Debug);
      debugPrint('Tapsell initialized');
    } catch (e) {
      debugPrint('Tapsell failed: $e');
    }
  }

  static Future<void> _safe(Future<void> Function() task) async {
    try {
      await task();
    } catch (e, s) {
      debugPrint('InitService error: $e');
      debugPrintStack(stackTrace: s);
    }
  }
}
