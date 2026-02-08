import 'package:application/GlobalWidgets/AppTheme/Colors.dart';
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
      duration: Duration(milliseconds: 1200),
    );

    textFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: textController, curve: Curves.easeOut));

    textSlide = Tween<Offset>(
      begin: Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: textController, curve: Curves.easeOut));

    textController.forward();

    bubbleController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 100),
    )..repeat(reverse: true);
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
            decoration: BoxDecoration(
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
                  SizedBox(height: 120),
                  Container(
                    width: 128,
                    height: 128,
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Icon(
                      Icons.directions_car,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    "DriveOrder",
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: AppColors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Drive-Through Made Easy",
                    style: Theme.of(context).textTheme.headlineLarge!
                        .copyWith(color: AppColors.white.withOpacity(0.8)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Order ahead, skip the wait.\nYour food ready when you arrive.",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: AppColors.white.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: 150,
                  child: isLoading ? Center(
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
                          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            color: AppColors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ) : null,),
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
                    SizedBox(height: 40),
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
            child: Icon(icon, color: AppColors.white.withOpacity(0.8), size: 30),
          ),
        ),
        SizedBox(height: 6),
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
