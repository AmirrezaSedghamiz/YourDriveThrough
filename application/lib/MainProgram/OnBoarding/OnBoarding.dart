import 'dart:ui';

import 'package:application/GlobalWidgets/AppTheme/Colors.dart';
import 'package:application/GlobalWidgets/NavigationServices/NavigationService.dart';
import 'package:application/GlobalWidgets/NavigationServices/RouteFactory.dart';
import 'package:application/Handlers/TokenHandler.dart';
import 'package:application/MainProgram/Login/Login.dart';
import 'package:application/MainProgram/OnBoarding/SubPages/OnBoarding1.dart';
import 'package:application/MainProgram/OnBoarding/SubPages/OnBoarding2.dart';
import 'package:application/MainProgram/OnBoarding/SubPages/OnBoarding3.dart';
import 'package:application/MainProgram/OnBoarding/SubPages/OnBoarding4.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  _OnBoardingScreenState createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Scaffold(
          backgroundColor: AppColors.white,
          body: Stack(
            children: [
              ScrollConfiguration(
                behavior: const MaterialScrollBehavior().copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                  },
                ),
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: const [
                    OnBoardingScreenFirst(),
                    OnBoardingScreenSecond(),
                    OnBoardingScreenThird(),
                    OnBoardingScreenFourth(),
                  ],
                ),
              ),
              Positioned(
                bottom: MediaQuery.of(context).size.height * 220 / 900,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SmoothPageIndicator(
                      controller: _pageController,
                      count: 4,
                      effect: SlideEffect(
                        dotHeight: 6,
                        dotWidth: 32,
                        activeDotColor: AppColors.primary,
                        dotColor: AppColors.coal.withOpacity(0.5),
                        // type: WormType.thin, // Keeps dot size consistent
                      ),
                    ),
                  ],
                ),
              ),
              // if (_currentPage == 3)
              Positioned(
                bottom: MediaQuery.of(context).size.height * 130 / 900,
                left: MediaQuery.of(context).size.width * 32 / 412,
                right: MediaQuery.of(context).size.width * 32 / 412,
                child: ElevatedButton(
                  onPressed: _currentPage == 3
                      ? () {
                          TokenStore.setInOnboarding(true);
                          var route = AppRoutes.fade(LoginPage());
                          NavigationService.popAllAndPush(route);
                        }
                      : () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: Size(
                      MediaQuery.of(context).size.width * 348 / 412,
                      50,
                    ),
                  ),
                  child: Text(
                    _currentPage == 3 ? "Get Started" : "Next",
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium!.copyWith(color: Colors.white),
                  ),
                ),
              ),
              if (_currentPage != 3)
                Positioned(
                  bottom: MediaQuery.of(context).size.height * 60 / 900,
                  left: MediaQuery.of(context).size.width * 32 / 412,
                  right: MediaQuery.of(context).size.width * 32 / 412,
                  child: Center(
                    child: TextButton(
                      onPressed: () {
                        TokenStore.setInOnboarding(true);
                        var route = AppRoutes.fade(LoginPage());
                        NavigationService.replace(route);
                      },
                      child: Text(
                        "Skip",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
