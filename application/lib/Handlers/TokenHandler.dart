import 'dart:convert';

import 'package:application/Handlers/SharePreferencesManager.dart';

class TokenStore {
  // ------------------- Token Methods -------------------

  static Future<void> saveTokens(
      String accessToken, String refreshToken) async {
    await SharedPreferencesManager.instance
        .setString('accessToken', accessToken);
    await SharedPreferencesManager.instance
        .setString('refreshToken', refreshToken);
  }

  static Future<String?> getAccessToken() async {
    return SharedPreferencesManager.instance.getString('accessToken');
  }

  static Future<String?> getRefreshToken() async {
    return SharedPreferencesManager.instance.getString('refreshToken');
  }

  static Future<void> setAccessToken(String token) async {
    await SharedPreferencesManager.instance.setString('accessToken', token);
  }

  static Future<void> setRefreshToken(String token) async {
    await SharedPreferencesManager.instance.setString('refreshToken', token);
  }

  static Future<void> clearTokens() async {
    await SharedPreferencesManager.instance.remove('accessToken');
    await SharedPreferencesManager.instance.remove('refreshToken');
  }

  static Future<bool?> getInOnboarding() async {
    return SharedPreferencesManager.instance.getBool('onBoarding');
  }

  static Future<void> setInOnboarding(bool value) async {
    await SharedPreferencesManager.instance.setBool('onBoarding', value);
  }

  static Future<bool?> getInSignUp() async {
    return SharedPreferencesManager.instance.getBool('login');
  }

  static Future<void> setInSignUp(bool value) async {
    await SharedPreferencesManager.instance.setBool('login', value);
  }

  static Future<String?> getFireBaseToken() async {
    return SharedPreferencesManager.instance.getString('firebase');
  }

  static Future<void> setFireBaseToken(String token) async {
    await SharedPreferencesManager.instance.setString('firebase', token);
  }

  static Future<bool?> getIsFcmEnable() async {
    return SharedPreferencesManager.instance.getBool('isFcmEnable');
  }

  static Future<void> setIsFcmEnable(bool value) async {
    await SharedPreferencesManager.instance.setBool('isFcmEnable', value);
  }

}
