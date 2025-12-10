import 'package:application/MainProgram/Login/Login.dart';
import 'package:application/MainProgram/OnBoarding/OnBoarding.dart';
import 'package:application/MainProgram/SplashScreen/SplashScreen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textTheme: TextTheme(
          headlineLarge: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          bodyLarge: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
          bodyMedium: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ),
      home: LoginPage(),
      // home: SplashScreen(),
      // home: OnBoardingScreen(),
    );
  }
}

