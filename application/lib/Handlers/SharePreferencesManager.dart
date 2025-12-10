import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesManager {
  SharedPreferencesManager._privateConstructor();

  static final SharedPreferencesManager _instance = SharedPreferencesManager._privateConstructor();

  static SharedPreferencesManager get instance => _instance;

  SharedPreferences? _preferences;
  bool _isInitialized = false;

  Future<void> init() async {
    try {
      _preferences = await SharedPreferences.getInstance();
      _isInitialized = true;
      print('SharedPreferences initialized successfully');
    } catch (e) {
      print('Error initializing SharedPreferences: $e');
      _isInitialized = false;
    }
  }

  // Ensure initialization before any operation
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await init();
    }
    if (_preferences == null) {
      throw Exception('SharedPreferences not initialized');
    }
  }

  Future<bool> setString(String key, String value) async {
    try {
      await _ensureInitialized();
      return await _preferences!.setString(key, value);
    } catch (e) {
      print('Error setting string $key: $e');
      return false;
    }
  }

  String? getString(String key) {
    try {
      if (!_isInitialized || _preferences == null) return null;
      return _preferences!.getString(key);
    } catch (e) {
      print('Error getting string $key: $e');
      return null;
    }
  }

  Future<bool> setStringList(String key, List<String> value) async {
    try {
      await _ensureInitialized();
      return await _preferences!.setStringList(key, value);
    } catch (e) {
      print('Error setting string $key: $e');
      return false;
    }
  }

 List<String>? getStringList(String key) {
    try {
      if (!_isInitialized || _preferences == null) return null;
      return _preferences!.getStringList(key);
    } catch (e) {
      print('Error getting string $key: $e');
      return null;
    }
  }

  Future<bool> setBool(String key, bool value) async {
    try {
      await _ensureInitialized();
      return await _preferences!.setBool(key, value);
    } catch (e) {
      print('Error setting bool $key: $e');
      return false;
    }
  }

  bool? getBool(String key) {
    try {
      if (!_isInitialized || _preferences == null) return null;
      return _preferences!.getBool(key);
    } catch (e) {
      print('Error getting bool $key: $e');
      return null;
    }
  }

  Future<bool> setInt(String key, int value) async {
    try {
      await _ensureInitialized();
      return await _preferences!.setInt(key, value);
    } catch (e) {
      print('Error setting int $key: $e');
      return false;
    }
  }

  int? getInt(String key) {
    try {
      if (!_isInitialized || _preferences == null) return null;
      return _preferences!.getInt(key);
    } catch (e) {
      print('Error getting int $key: $e');
      return null;
    }
  }

  Future<bool> remove(String key) async {
    try {
      await _ensureInitialized();
      return await _preferences!.remove(key);
    } catch (e) {
      print('Error removing $key: $e');
      return false;
    }
  }

  Future<bool> pushMap(String key, Map<String, dynamic> value) async {
    try {
      await _ensureInitialized();
      final list = getAllMaps(key);
      list.add(value);
      return await _preferences!.setString(key, jsonEncode(list));
    } catch (e) {
      print('Error pushing map to $key: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> popMap(String key) async {
    try {
      await _ensureInitialized();
      final list = getAllMaps(key);
      if (list.isEmpty) return null;
      final first = list.removeAt(0);
      await _preferences!.setString(key, jsonEncode(list));
      return first;
    } catch (e) {
      print('Error popping map from $key: $e');
      return null;
    }
  }

  List<Map<String, dynamic>> getAllMaps(String key) {
    try {
      if (!_isInitialized || _preferences == null) return [];
      final jsonString = _preferences!.getString(key);
      if (jsonString == null || jsonString.isEmpty) return [];
      final decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('Error getting all maps from $key: $e');
      return [];
    }
  }

  // Clear all data (useful for testing)
  Future<bool> clearAll() async {
    try {
      await _ensureInitialized();
      return await _preferences!.clear();
    } catch (e) {
      print('Error clearing all data: $e');
      return false;
    }
  }

  // Check if a key exists
  bool containsKey(String key) {
    try {
      if (!_isInitialized || _preferences == null) return false;
      return _preferences!.containsKey(key);
    } catch (e) {
      print('Error checking key $key: $e');
      return false;
    }
  }
}

