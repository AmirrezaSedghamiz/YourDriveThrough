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

  // ------------------- App State Methods -------------------

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

  static Future<bool?> getIsHidden() async {
    return SharedPreferencesManager.instance.getBool('hidden');
  }

  static Future<void> setIsHidden(bool value) async {
    await SharedPreferencesManager.instance.setBool('hidden', value);
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

  static Future<bool?> getShowOfflineDialog() async {
    return SharedPreferencesManager.instance.getBool('offline');
  }

  static Future<void> setShowOfflineDialog(bool value) async {
    await SharedPreferencesManager.instance.setBool('offline', value);
  }

  // ------------------- Persistent Queue Methods -------------------

  static const String _queueKey = 'pendingFunctionsQueue';

  /// Push a map into the queue
  static Future<void> pushQueueItem(Map<String, dynamic> item) async {
    final queue = getQueue();
    queue.add(item);
    await SharedPreferencesManager.instance
        .setString(_queueKey, jsonEncode(queue));
  }

  /// Pop the first map from the queue
  static Future<Map<String, dynamic>?> popQueueItem() async {
    final queue = getQueue();
    if (queue.isEmpty) return null;
    final first = queue.removeAt(0);
    await SharedPreferencesManager.instance
        .setString(_queueKey, jsonEncode(queue));
    return first;
  }

  /// Get the entire queue
  static List<Map<String, dynamic>> getQueue() {
    final jsonString = SharedPreferencesManager.instance.getString(_queueKey);
    if (jsonString == null) return [];
    final decoded = jsonDecode(jsonString) as List<dynamic>;
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
