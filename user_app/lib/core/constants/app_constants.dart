export 'api_constants.dart';
export 'storage_keys.dart';

import 'package:flutter/material.dart';

/// Global application constants.
class AppConstants {
  const AppConstants._();

  /// Application
  static const String appName = 'MediGuide';

  /// Pagination
  static const int pageSize = 10;

  /// UI
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration snackBarDuration = Duration(seconds: 3);

  static const double borderRadius = 12.0;
  static const double dialogBorderRadius = 16.0;

  /// Search
  static const int maxSearchHistory = 20;
  static const Duration searchDebounce = Duration(milliseconds: 500);

  /// Downloads
  static const int downloadChunkSize = 1024 * 1024; // 1 MB

  /// Cache
  static const Duration cacheValidity = Duration(days: 7);

  /// Network
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Sync
  static const Duration syncInterval = Duration(minutes: 15);
}

/// Theme mode values stored in SharedPreferences.
class ThemeModes {
  const ThemeModes._();

  static const String light = 'light';
  static const String dark = 'dark';
  static const String system = 'system';

  static const values = <String>[light, dark, system];
}

/// Supported application locales.
class AppLocales {
  const AppLocales._();

  static const Locale english = Locale('en');
  static const Locale swahili = Locale('sw');

  static const supported = <Locale>[english, swahili];
}
