import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_app/core/config/firebase_config.dart';
import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/features/authentication/data/datasources/auth_remote_datasource.dart';

const _installationKey = 'firebase_installation_id';
const _deviceRecordKey = 'firebase_device_record_id';

@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessageHandler(RemoteMessage message) async {
  if (!MediGuideFirebaseConfig.isConfigured) return;
  await Firebase.initializeApp(
    options: MediGuideFirebaseConfig.currentPlatform,
  );
}

final class MediGuideFirebaseService {
  MediGuideFirebaseService(this._api, this._auth, this._preferences);

  final BackendApiService _api;
  final AuthService _auth;
  final SharedPreferences _preferences;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final StreamController<RemoteMessage> _openedMessages =
      StreamController.broadcast();

  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  VoidCallback? _authListener;
  RemoteMessage? _initialMessage;
  bool _enabled = false;

  bool get enabled => _enabled;
  Stream<RemoteMessage> get openedMessages async* {
    final initial = _initialMessage;
    _initialMessage = null;
    if (initial != null) yield initial;
    yield* _openedMessages.stream;
  }

  FirebaseRemoteConfig? get remoteConfig =>
      _enabled ? FirebaseRemoteConfig.instance : null;
  bool get aiAssistantEnabled =>
      !_enabled || FirebaseRemoteConfig.instance.getBool('enable_ai_assistant');
  bool get outbreakBannerEnabled =>
      !_enabled ||
      FirebaseRemoteConfig.instance.getBool('outbreak_banner_enabled');
  bool get maintenanceMode =>
      _enabled && FirebaseRemoteConfig.instance.getBool('maintenance_mode');
  String get maintenanceMessage => _enabled
      ? FirebaseRemoteConfig.instance.getString('maintenance_message')
      : '';

  Map<String, RemoteConfigValue> get remoteConfigValues =>
      _enabled ? FirebaseRemoteConfig.instance.getAll() : const {};
  DateTime? get remoteConfigLastFetchTime =>
      _enabled ? FirebaseRemoteConfig.instance.lastFetchTime : null;
  RemoteConfigFetchStatus? get remoteConfigLastFetchStatus =>
      _enabled ? FirebaseRemoteConfig.instance.lastFetchStatus : null;

  Future<bool> refreshRemoteConfig() async {
    if (!_enabled) return false;
    return FirebaseRemoteConfig.instance.fetchAndActivate();
  }

  Future<MediGuideFirebaseService> init() async {
    if (!MediGuideFirebaseConfig.isConfigured ||
        !(Platform.isAndroid || Platform.isIOS)) {
      debugPrint('Firebase disabled: client configuration is absent.');
      return this;
    }

    await Firebase.initializeApp(
      options: MediGuideFirebaseConfig.currentPlatform,
    );
    _enabled = true;
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessageHandler);

    await _initializeRemoteConfig();
    await _initializeLocalNotifications();
    await _initializeMessaging();

    _auth.beforeLogout = unregisterCurrentDevice;
    _authListener = () {
      if (_auth.currentUser.value != null) {
        unawaited(registerCurrentDevice());
      }
    };
    _auth.currentUser.addListener(_authListener!);
    if (_auth.currentUser.value != null) {
      await registerCurrentDevice();
    }
    return this;
  }

  Future<void> _initializeRemoteConfig() async {
    final config = FirebaseRemoteConfig.instance;
    await config.setDefaults(const {
      'maintenance_mode': false,
      'maintenance_message': '',
      'enable_ai_assistant': true,
      'enable_push_notifications': true,
      'minimum_supported_version': '',
      'outbreak_banner_enabled': true,
    });
    await config.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 30),
        minimumFetchInterval: kDebugMode
            ? const Duration(minutes: 5)
            : const Duration(hours: 1),
      ),
    );
    try {
      await config.fetchAndActivate();
    } catch (error) {
      debugPrint('Remote Config fetch failed; defaults remain active: $error');
    }
    config.onConfigUpdated.listen((_) async {
      await config.activate();
    });
  }

  Future<void> _initializeLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    await _localNotifications.initialize(
      settings: const InitializationSettings(android: android, iOS: darwin),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final data = Map<String, dynamic>.from(jsonDecode(payload) as Map);
          _openedMessages.add(RemoteMessage(data: data));
        } catch (_) {}
      },
    );
    const channel = AndroidNotificationChannel(
      'mediguide_alerts',
      'MediGuide alerts',
      description: 'Clinical updates, reminders, and urgent alerts',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<void> _initializeMessaging() async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: Platform.isIOS,
    );
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    _tokenSubscription = messaging.onTokenRefresh.listen((_) {
      unawaited(registerCurrentDevice());
    });
    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      _showForegroundMessage,
    );
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _openedMessages.add,
    );
    final initial = await messaging.getInitialMessage();
    if (initial != null) _initialMessage = initial;
  }

  Future<void> _showForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await _localNotifications.show(
      id: message.messageId.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'mediguide_alerts',
          'MediGuide alerts',
          channelDescription: 'Clinical updates, reminders, and urgent alerts',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  Future<void> registerCurrentDevice() async {
    if (!_enabled || _auth.currentUser.value == null) return;
    if (!FirebaseRemoteConfig.instance.getBool('enable_push_notifications')) {
      return;
    }
    if (Platform.isIOS) {
      final apns = await FirebaseMessaging.instance.getAPNSToken();
      if (apns == null) return;
    }
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) return;
    final package = await PackageInfo.fromPlatform();
    final installation = _installationID();
    final response = await _api.requestJson(
      '/api/v2/firebase/devices',
      method: 'POST',
      body: {
        'installation_id': installation,
        'registration_token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'app_version': '${package.version}+${package.buildNumber}',
        'locale': Platform.localeName,
      },
    );
    final data = response['data'];
    if (data is Map && data['id'] != null) {
      await _preferences.setString(_deviceRecordKey, data['id'].toString());
    }
  }

  Future<void> unregisterCurrentDevice() async {
    if (!_enabled) return;
    final id = _preferences.getString(_deviceRecordKey);
    if (id != null && id.isNotEmpty) {
      try {
        await _api.requestJson(
          '/api/v2/firebase/devices/${Uri.encodeComponent(id)}',
          method: 'DELETE',
        );
      } catch (_) {}
      await _preferences.remove(_deviceRecordKey);
    }
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }

  String _installationID() {
    final existing = _preferences.getString(_installationKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final random = Random.secure();
    final bytes = List<int>.generate(24, (_) => random.nextInt(256));
    final value = base64UrlEncode(bytes).replaceAll('=', '');
    _preferences.setString(_installationKey, value);
    return value;
  }

  Future<void> dispose() async {
    if (_authListener != null) _auth.currentUser.removeListener(_authListener!);
    await _tokenSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    await _openedMessages.close();
  }
}
