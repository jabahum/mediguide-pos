import 'dart:io';

import 'package:firebase_core/firebase_core.dart';

/// Firebase client identifiers are intentionally supplied at build time.
/// They are not Admin credentials and must never be confused with the
/// backend-only service account.
abstract final class MediGuideFirebaseConfig {
  static const flavor = String.fromEnvironment(
    'MEDIGUIDE_FLAVOR',
    defaultValue: 'development',
  );
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const androidAppId = String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
  static const iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');

  static String get iosBundleId => switch (flavor) {
    'development' => 'com.omarsoft.mediguide.dev',
    'staging' => 'com.omarsoft.mediguide.staging',
    _ => 'com.omarsoft.mediguide',
  };

  static bool get isConfigured =>
      projectId.isNotEmpty &&
      apiKey.isNotEmpty &&
      messagingSenderId.isNotEmpty &&
      ((Platform.isAndroid && androidAppId.isNotEmpty) ||
          (Platform.isIOS && iosAppId.isNotEmpty));

  static FirebaseOptions get currentPlatform {
    if (!isConfigured) {
      throw StateError('Firebase client configuration is incomplete');
    }
    if (Platform.isAndroid) {
      return const FirebaseOptions(
        apiKey: apiKey,
        appId: androidAppId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
      );
    }
    if (Platform.isIOS) {
      return FirebaseOptions(
        apiKey: apiKey,
        appId: iosAppId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        iosBundleId: iosBundleId,
      );
    }
    throw UnsupportedError('Firebase is enabled only for Android and iOS');
  }
}
