import 'package:flutter/material.dart';

class AnimationNavigation {
  static void navigatePush(
    Widget page,
    BuildContext context,
  ) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => page,
    ));
  }

  static void navigateReplace(
    Widget page,
    BuildContext context,
  ) {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => page,
    ));
  }

  static void navigateMakeFirst(
    Widget page,
    BuildContext context,
  ) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => page),
      (route) => route.isFirst,
    );
  }

  static void navigatePopAllReplace(
    Widget page,
    BuildContext context,
  ) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => page),
      (route) => false, 
    );
  }
}
