import 'package:flutter/material.dart';

enum AppLanguage {
  english,
  persian,
}

extension AppLanguageX on AppLanguage {
  bool get isRTL => this == AppLanguage.persian;

  Locale get locale {
    switch (this) {
      case AppLanguage.persian:
        return const Locale('fa');
      case AppLanguage.english:
        return const Locale('en');
    }
  }
}

class LanguageController extends ChangeNotifier {
  AppLanguage _current = AppLanguage.english;

  AppLanguage get current => _current;

  void switchLanguage(AppLanguage language) {
    _current = language;
    notifyListeners();
  }

  TextDirection get textDirection =>
      _current.isRTL ? TextDirection.rtl : TextDirection.ltr;
}

class BilingualWrapper extends StatelessWidget {
  final LanguageController controller;
  final Widget child;

  const BilingualWrapper({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Directionality(
          textDirection: controller.textDirection,
          child: child,
        );
      },
    );
  }
}