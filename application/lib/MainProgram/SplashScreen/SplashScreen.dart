// SplashScreen.dart (adds version-control dialog; keeps your flow)
// NOTE: I only added version check + dialog plumbing. Your routing logic stays the same.

import 'package:application/GlobalWidgets/AppTheme/Colors.dart';
import 'package:application/GlobalWidgets/InternetManager/ConnectionStates.dart';
import 'package:application/GlobalWidgets/NavigationServices/NavigationService.dart';
import 'package:application/GlobalWidgets/NavigationServices/RouteFactory.dart';
import 'package:application/GlobalWidgets/Services/Map.dart';
import 'package:application/Handlers/Repository/LoginRepo.dart';
import 'package:application/Handlers/TokenHandler.dart';
import 'package:application/MainProgram/Customer/DashboardCustomer/DashboardCustomer.dart';
import 'package:application/MainProgram/Login/Login.dart';
import 'package:application/MainProgram/Manager/DashboardManager/DashboardManager.dart';
import 'package:application/MainProgram/OnBoarding/OnBoarding.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:loading_animation_widget/loading_animation_widget.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController textController;
  late AnimationController bubbleController;
  late Animation<double> textFade;
  late Animation<Offset> textSlide;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    textFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: textController, curve: Curves.easeOut),
    );

    textSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(
      CurvedAnimation(parent: textController, curve: Curves.easeOut),
    );

    textController.forward();

    bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 100),
    )..repeat(reverse: true);

    _goNextAfterDelay();
  }

  Future<void> _goNextAfterDelay() async {
    await Future.delayed(const Duration(seconds: 3));

    // ✅ 1) Version check first
    final versionCheck = await LoginRepo().versionCheck();
    if (!mounted) return;

    // if backend says update required => block and show dialog
    if (versionCheck is bool && versionCheck == true) {
      setState(() => isLoading = false);
      await _showForceUpdateDialog(context);
      return; // stop flow
    }

    // optional: if version check failed, let user continue (or you can show a soft banner)
    // if (versionCheck is ConnectionStates) { ... }

    // ✅ 2) Your onboarding + token flow (unchanged)
    final dontGoToOnboarding = (await TokenStore.getInOnboarding() ?? false);
    if (!dontGoToOnboarding) {
      var route = AppRoutes.fade(OnBoardingScreen());
      NavigationService.replace(route);
      return;
    }

    final data = await LoginRepo().verifyToken();
    if (!mounted) return;

    if (data != ConnectionStates && data) {
      final role = await LoginRepo().getRole();

      var route = (role["role"] == "customer"
          ? AppRoutes.fade(DashboardCustomer(initialPage: 0))
          : role["complete"]
              ? AppRoutes.fade(DashboardManager(initialPage: 0))
              : null);

      if (route == null) {
        var firstRoute = AppRoutes.fade(LoginPage());
        var secondRoute = AppRoutes.fade(
          MapBuilder(
            username: role["username"] ?? "",
            callBackFunction: null,
          ),
        );
        NavigationService.replace(firstRoute);
        NavigationService.push(secondRoute);
        return;
      }

      NavigationService.replace(route);
      return;
    } else {
      var route = AppRoutes.fade(LoginPage());
      NavigationService.replace(route);
      return;
    }
  }

  // -------------------------
  // Version control dialog
  // -------------------------

  Future<void> _showForceUpdateDialog(BuildContext context) async {
    final t = Theme.of(context).textTheme;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          surfaceTintColor: AppColors.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.system_update_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Update required",
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          content: Text(
            "A newer version of DriveOrder is available. Please update to continue using the app.",
            style: t.bodyMedium?.copyWith(
              color: Colors.black.withOpacity(0.70),
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () async {
                  // TODO: replace with your real store link
                  // const playStoreUrl =
                  //     "https://play.google.com/store/apps/details?id=com.example.driveThru";
                  // final uri = Uri.parse(playStoreUrl);

                  // await launchUrl(
                  //   uri,
                  //   mode: LaunchMode.externalApplication,
                  // );
                },
                child: Text(
                  "Update now",
                  style: t.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    textController.dispose();
    bubbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF7A00), Color(0xFFFF6200)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: bubbleController,
            builder: (_, __) {
              return Stack(
                children: [
                  _bubble(80, 80, 0.6, 0.15),
                  _bubble(150, 120, 0.2, -0.1),
                  _bubble(300, 70, 0.1, -0.05),
                  _bubble(350, 80, 0.8, -0.05),
                  _bubble(500, 80, 0.05, -0.15),
                  _bubble(650, 100, 0.8, -0.05),
                ],
              );
            },
          ),
          SlideTransition(
            position: textSlide,
            child: FadeTransition(
              opacity: textFade,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 120),
                  Container(
                    width: 128,
                    height: 128,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: const Icon(
                      Icons.directions_car,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "DriveOrder",
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: AppColors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Drive-Through Made Easy",
                    style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                          color: AppColors.white.withOpacity(0.8),
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Order ahead, skip the wait.\nYour food ready when you arrive.",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: AppColors.white.withOpacity(0.7),
                        ),
                  ),
                  SizedBox(
                    height: 150,
                    child: isLoading
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                LoadingAnimationWidget.staggeredDotsWave(
                                  color: AppColors.white.withOpacity(0.7),
                                  size: 60,
                                ),
                                Text(
                                  "Loading your experience",
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .copyWith(
                                        color: AppColors.white.withOpacity(0.7),
                                      ),
                                ),
                              ],
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 35,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        left: MediaQuery.of(context).size.width * 60 / 400,
                        right: MediaQuery.of(context).size.width * 60 / 400,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _features(Icons.alarm, "Save Time"),
                          _features(Icons.route, "Smart Route"),
                          _features(Icons.food_bank, "Fresh Food"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      "Version 1.0.0",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: AppColors.white.withOpacity(0.7),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _features(IconData icon, String text) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              icon,
              color: AppColors.white.withOpacity(0.8),
              size: 30,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontSize: 12,
                color: AppColors.white.withOpacity(0.7),
              ),
        ),
      ],
    );
  }

  Widget _bubble(double top, double size, double leftFactor, double offset) {
    double movement = math.sin(bubbleController.value * math.pi * 2) * 10;

    return Positioned(
      top: top + movement + offset * 40,
      left: MediaQuery.of(context).size.width * leftFactor,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
