import 'dart:async';

import 'package:application/gen/assets.gen.dart';
import 'package:flutter/material.dart';

class OnBoardingScreenFourth extends StatefulWidget {
  const OnBoardingScreenFourth({super.key});

  @override
  State<OnBoardingScreenFourth> createState() => _OnBoardingScreenFourthState();
}

class _OnBoardingScreenFourthState extends State<OnBoardingScreenFourth>
    with AutomaticKeepAliveClientMixin<OnBoardingScreenFourth> {
  @override
  bool get wantKeepAlive => true; // Ensure it rebuilds when revisited
  bool showLoopingGif = false; // Controls which GIF is displayed
  Timer? _gifTimer;


  @override
  void initState() {
    super.initState();
    _restartAnimation();
  }

  void _restartAnimation() {
    setState(() {
      showLoopingGif = false; // Reset to entrance GIF
    });

    _gifTimer?.cancel();
    _gifTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          showLoopingGif = true; // Switch to looping GIF
        });
      }
    });
  }

  @override
  void dispose() {
    _gifTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          SizedBox(height: 30,),
          Container(
            child: Assets.onBoardingImages.page4.image(width: 240, height: 240)
          ),
          SizedBox(height: 30,),
          Column(
            children: [
              Text(
                "Quality Experience",
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(
                      fontSize: 30,
                      fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
              ),
            
          const SizedBox(height: 20),
          Padding(
            padding: EdgeInsetsGeometry.only(left: 12, right: 12),
            child: Text(
             "Rate and review restaurants to help others find the best drive-through experiences" ,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge!
                  .copyWith(),
                  textAlign: TextAlign.center,
            ),
          ),
      
          ],
          ),
          const SizedBox()
        ],
      ),
    );
  }
}
