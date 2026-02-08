// core/navigation/navigation_service.dart
import 'package:flutter/material.dart';

class NavigationService {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static NavigatorState get _navigator =>
      navigatorKey.currentState!;

  static Future<void> push(Route route) {
    return _navigator.push(route);
  }

  static Future<void> replace(Route route) {
    return _navigator.pushReplacement(route);
  }

  static Future<void> popAllAndPush(Route route) {
    return _navigator.pushAndRemoveUntil(
      route,
      (route) => false,
    );
  }

  static void pop() {
    _navigator.pop();
  }
}
