// core/navigation/app_routes.dart
import 'package:flutter/material.dart';

class AppRoutes {
  static Route fade(
    Widget page, {
    Duration duration = const Duration(milliseconds: 260),
    Curve curve = Curves.easeOutCubic,
  }) {
    return PageRouteBuilder(
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedIn = CurvedAnimation(parent: animation, curve: curve);
        final curvedOut = CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeInCubic,
        );

        // Fade in the new page, and fade out the old one slightly (feels smoother).
        return FadeTransition(
          opacity: curvedIn,
          child: FadeTransition(
            opacity: Tween<double>(begin: 1, end: 0).animate(curvedOut),
            child: child,
          ),
        );
      },
    );
  }

  static Route slide(
    Widget page, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOutCubic,
  }) {
    return PageRouteBuilder(
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(parent: animation, curve: curve);
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(curved);

        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }
}
