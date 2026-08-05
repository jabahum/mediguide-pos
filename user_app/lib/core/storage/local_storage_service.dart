import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PreferenceUtils {
  static Future<SharedPreferences> get _instance async =>
      _preferencesInstance ??= await SharedPreferences.getInstance();
  static SharedPreferences? _preferencesInstance;

  static Future<SharedPreferences> init() async {
    _preferencesInstance = await _instance;
    return _preferencesInstance!;
  }

  static String getString(String key, [String defValue = '']) {
    return _preferencesInstance?.getString(key) ?? defValue;
  }

  static Future<bool> setString(String key, String value) async {
    var preference = await _instance;
    return preference.setString(key, value);
  }

  static int getInt(String key, [int defValue = 0]) {
    return _preferencesInstance?.getInt(key) ?? defValue;
  }

  static Future<bool> setInt(String key, int value) async {
    var preference = await _instance;
    return preference.setInt(key, value);
  }

  static double getDouble(String key, [double defValue = 0.0]) {
    return _preferencesInstance?.getDouble(key) ?? defValue;
  }

  static Future<bool> setDouble(String key, double value) async {
    var preference = await _instance;
    return preference.setDouble(key, value);
  }

  static bool getBool(String key, [bool defValue = false]) {
    return _preferencesInstance?.getBool(key) ?? defValue;
  }

  static Future<bool> setBool(String key, bool value) async {
    var preference = await _instance;
    return preference.setBool(key, value);
  }

  static Future<bool> remove(String key) async {
    var preference = await _instance;
    return preference.remove(key);
  }

  static bool containsKey(String key) {
    return _preferencesInstance?.containsKey(key) ?? false;
  }

  static dynamic getJson(String key) {
    String? jsonString = _preferencesInstance?.getString(key);
    return jsonString != null ? jsonDecode(jsonString) : {};
  }

  static Future<bool> setJson(String key, dynamic value) async {
    var preference = await _instance;
    return preference.setString(key, jsonEncode(value));
  }

  static Future<void> reloadPreferences() async {
    var preference = await _instance;
    await preference.reload();
  }

  static Future<void> clear() async {
    await _preferencesInstance?.clear();
  }
}
