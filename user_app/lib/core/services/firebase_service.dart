import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_app/core/config/firebase_config.dart';
import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/features/authentication/data/datasources/auth_remote_datasource.dart';

const _installationKey = 'firebase_installation_id';
const _deviceRecordKey = 'firebase_device_record_id';
const _permissionRequestedKey = 'firebase_notification_permission_requested';
const _outbreakTopicPreferenceKey = 'firebase_outbreak_topic_preference';
const _outbreakTopicSubscribedKey = 'firebase_outbreak_topic_subscribed';
const _publicOutbreakTopic = 'public-outbreaks';

enum AppNotificationPermissionState {
  notDetermined,
  provisional,
  authorized,
  denied,
  permanentlyDenied,
}

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
  final StreamController<RemoteMessage> _foregroundMessages =
      StreamController.broadcast();
  final StreamController<AppNotificationPermissionState> _permissionStates =
      StreamController.broadcast();
  final StreamController<bool> _outbreakBannerStates =
      StreamController<bool>.broadcast();

  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<RemoteConfigUpdate>? _remoteConfigSubscription;
  VoidCallback? _authListener;
  RemoteMessage? _initialMessage;
  bool _enabled = false;
  AppNotificationPermissionState _permissionState =
      AppNotificationPermissionState.notDetermined;

  bool get enabled => _enabled;
  Stream<RemoteMessage> get openedMessages async* {
    final initial = _initialMessage;
    _initialMessage = null;
    if (initial != null) yield initial;
    yield* _openedMessages.stream;
  }

  Stream<RemoteMessage> get foregroundMessages => _foregroundMessages.stream;
  Stream<AppNotificationPermissionState> get permissionStates =>
      _permissionStates.stream;
  AppNotificationPermissionState get permissionState => _permissionState;
  Stream<bool> get outbreakBannerStates async* {
    yield outbreakBannerEnabled;
    yield* _outbreakBannerStates.stream;
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
    final changed = await FirebaseRemoteConfig.instance.fetchAndActivate();
    _outbreakBannerStates.add(outbreakBannerEnabled);
    await _syncPublicOutbreakTopic();
    return changed;
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
    await _syncPublicOutbreakTopic();

    _auth.beforeLogout = unregisterCurrentDevice;
    _authListener = () {
      if (_auth.currentUser.value != null) {
        unawaited(registerCurrentDevice());
        unawaited(syncOutbreakTopicPreferenceFromServer());
      }
    };
    _auth.currentUser.addListener(_authListener!);
    if (_auth.currentUser.value != null) {
      await registerCurrentDevice();
      await syncOutbreakTopicPreferenceFromServer();
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
    _remoteConfigSubscription = config.onConfigUpdated.listen((_) async {
      await config.activate();
      _outbreakBannerStates.add(outbreakBannerEnabled);
      await _syncPublicOutbreakTopic();
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
    final settings = await messaging.getNotificationSettings();
    _setPermissionState(
      permissionStateFor(
        settings.authorizationStatus,
        previouslyRequested:
            _preferences.getBool(_permissionRequestedKey) ?? false,
      ),
    );
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

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
    _foregroundMessages.add(message);
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

  Future<AppNotificationPermissionState> requestNotificationPermission() async {
    if (!_enabled) return _permissionState;
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: Platform.isIOS,
    );
    await _preferences.setBool(_permissionRequestedKey, true);
    final state = permissionStateFor(
      settings.authorizationStatus,
      previouslyRequested: true,
    );
    _setPermissionState(state);
    if (state == AppNotificationPermissionState.authorized ||
        state == AppNotificationPermissionState.provisional) {
      await registerCurrentDevice();
    }
    await _syncPublicOutbreakTopic();
    return state;
  }

  /// Persists the user's outbreak-alert preference and reconciles the public
  /// Firebase topic. Production never subscribes unless permission, Remote
  /// Config and both notification preferences permit it.
  Future<void> setOutbreakTopicPreference({
    required bool outbreakAlerts,
    required bool pushEnabled,
  }) async {
    await _preferences.setBool(
      _outbreakTopicPreferenceKey,
      outbreakAlerts && pushEnabled,
    );
    await _syncPublicOutbreakTopic();
  }

  Future<void> syncOutbreakTopicPreferenceFromServer() async {
    if (!_enabled || _auth.currentUser.value == null) return;
    try {
      final response = await _api.requestJson(
        '/api/v2/notification-preferences',
        method: 'GET',
      );
      final raw = response['data'];
      if (raw is! Map) return;
      final preferences = Map<String, dynamic>.from(raw);
      await setOutbreakTopicPreference(
        outbreakAlerts: preferences['outbreak_alerts'] != false,
        pushEnabled: preferences['push_enabled'] != false,
      );
    } catch (error) {
      debugPrint('Outbreak topic preference sync failed: $error');
    }
  }

  Future<void> _syncPublicOutbreakTopic() async {
    if (!_enabled) return;
    final shouldSubscribe = shouldSubscribeToPublicOutbreaks(
      remoteEnabled: outbreakBannerEnabled,
      pushEnabled: FirebaseRemoteConfig.instance.getBool(
        'enable_push_notifications',
      ),
      userOptedIn: _preferences.getBool(_outbreakTopicPreferenceKey) ?? false,
      permissionState: _permissionState,
    );
    final subscribed =
        _preferences.getBool(_outbreakTopicSubscribedKey) ?? false;
    if (shouldSubscribe == subscribed) return;
    try {
      if (shouldSubscribe) {
        await FirebaseMessaging.instance.subscribeToTopic(_publicOutbreakTopic);
      } else {
        await FirebaseMessaging.instance.unsubscribeFromTopic(
          _publicOutbreakTopic,
        );
      }
      await _preferences.setBool(_outbreakTopicSubscribedKey, shouldSubscribe);
    } catch (error) {
      debugPrint('Outbreak topic reconciliation failed: $error');
    }
  }

  Future<bool> openNotificationSettings() async {
    if (!_enabled) return false;
    try {
      return await const MethodChannel(
            'mediguide/app_settings',
          ).invokeMethod<bool>('openNotificationSettings') ??
          false;
    } on PlatformException {
      return false;
    }
  }

  static AppNotificationPermissionState permissionStateFor(
    AuthorizationStatus status, {
    required bool previouslyRequested,
  }) {
    return switch (status) {
      AuthorizationStatus.notDetermined =>
        AppNotificationPermissionState.notDetermined,
      AuthorizationStatus.provisional =>
        AppNotificationPermissionState.provisional,
      AuthorizationStatus.authorized =>
        AppNotificationPermissionState.authorized,
      AuthorizationStatus.denied =>
        previouslyRequested
            ? AppNotificationPermissionState.permanentlyDenied
            : AppNotificationPermissionState.denied,
    };
  }

  void _setPermissionState(AppNotificationPermissionState value) {
    _permissionState = value;
    _permissionStates.add(value);
  }

  Future<void> registerCurrentDevice() async {
    if (!_enabled || _auth.currentUser.value == null) return;
    if (_permissionState != AppNotificationPermissionState.authorized &&
        _permissionState != AppNotificationPermissionState.provisional) {
      return;
    }
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
    await _preferences.setBool(_outbreakTopicPreferenceKey, false);
    await _syncPublicOutbreakTopic();
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
    await _remoteConfigSubscription?.cancel();
    await _openedMessages.close();
    await _foregroundMessages.close();
    await _permissionStates.close();
    await _outbreakBannerStates.close();
  }
}

@visibleForTesting
bool shouldSubscribeToPublicOutbreaks({
  required bool remoteEnabled,
  required bool pushEnabled,
  required bool userOptedIn,
  required AppNotificationPermissionState permissionState,
}) {
  final permitted =
      permissionState == AppNotificationPermissionState.authorized ||
      permissionState == AppNotificationPermissionState.provisional;
  return remoteEnabled && pushEnabled && userOptedIn && permitted;
}
