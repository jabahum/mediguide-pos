import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';

import '../../data/services/backend_api_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/models/models.dart';
import '../../utils/constants.dart';

class UseCalculatorController extends GetxController {
  Calculator? calculator;

  InAppWebViewController? webViewController;

  final isLoading = true.obs;
  final hasError = false.obs;
  final isWebViewReady = false.obs;

  String? htmlContent;
  String? errorMessage;
  String? contentBaseUrl;

  DateTime? sessionStartTime;
  String? currentUsageLogId;

  @override
  void onInit() {
    calculator = Get.arguments as Calculator?;

    if (calculator != null) {
      _startUsageTracking();
      loadCalculatorFile();
    } else {
      hasError.value = true;
      errorMessage = 'No calculator data provided';
      isLoading.value = false;
    }

    super.onInit();
  }

  /// ================================
  /// LOAD FILE (FIXED VERSION)
  /// ================================
  Future<void> loadCalculatorFile() async {
    debugPrint('📁 Loading calculator: ${calculator?.name}');
    debugPrint('📄 appFile from DB: ${calculator?.appFile}');
    debugPrint('📄 recordId: ${calculator?.id}');

    if (calculator?.appFile == null || calculator!.appFile.isEmpty) {
      hasError.value = true;
      errorMessage = 'Calculator file not found';
      isLoading.value = false;
      return;
    }

    try {
      isLoading.value = true;
      hasError.value = false;

      final directory = await getApplicationDocumentsDirectory();
      final localFile = File(
        '${directory.path}/calculator_${calculator!.id}.html',
      );
      final metadataFile = File(
        '${directory.path}/calculator_${calculator!.id}.json',
      );
      const collectionName = 'calculators';

      final downloadUrl = BackendApiService.to.getFileUrl(
        collectionName: collectionName,
        recordId: calculator!.id,
        filename: calculator!.appFile,
      );
      contentBaseUrl = _deriveContentBaseUrl(downloadUrl);

      debugPrint('🔗 FINAL URL: $downloadUrl');

      String? cachedHtml;
      final cacheMetadata = await _readCacheMetadata(metadataFile);

      /// ================================
      /// 1. CHECK CACHE
      /// ================================
      if (await localFile.exists()) {
        final cached = await localFile.readAsString();

        if (cached.trim().startsWith('<')) {
          cachedHtml = cached;
          if (_isCacheCurrent(cacheMetadata, downloadUrl)) {
            htmlContent = cachedHtml;
            errorMessage = null;
            debugPrint('✅ Loaded current calculator file from cache');
            _loadIntoWebViewIfReady();
            isLoading.value = false;
            return;
          }
        } else {
          await localFile.delete();
          if (await metadataFile.exists()) {
            await metadataFile.delete();
          }
        }
      }

      /// ================================
      /// 2. DOWNLOAD OR UPSERT FILE
      /// ================================
      final response = await http.get(Uri.parse(downloadUrl));

      debugPrint('📡 HTTP STATUS: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception('Failed to download file: ${response.statusCode}');
      }

      final body = response.body;

      if (!body.trim().startsWith('<')) {
        throw Exception('Invalid HTML received from server');
      }

      /// ================================
      /// 3. CACHE + STORE
      /// ================================
      await localFile.writeAsString(body);
      await metadataFile.writeAsString(
        jsonEncode({
          'version': calculator!.version,
          'appFile': calculator!.appFile,
          'downloadUrl': downloadUrl,
        }),
      );

      htmlContent = body;
      errorMessage = null;

      debugPrint('✅ Downloaded and upserted calculator cache');

      _loadIntoWebViewIfReady();
    } catch (e) {
      final directory = await getApplicationDocumentsDirectory();
      final localFile = File(
        '${directory.path}/calculator_${calculator!.id}.html',
      );

      if (await localFile.exists()) {
        final cached = await localFile.readAsString();
        if (cached.trim().startsWith('<')) {
          htmlContent = cached;
          hasError.value = false;
          errorMessage = null;
          debugPrint(
            '⚠️ Download failed, loaded calculator from offline cache: $e',
          );
          _loadIntoWebViewIfReady();
          return;
        }
      }

      hasError.value = true;
      errorMessage = 'Failed to load calculator: $e';
      debugPrint('❌ ERROR: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// ================================
  /// WEBVIEW HANDLING
  /// ================================
  void onWebViewCreated(InAppWebViewController controller) {
    webViewController = controller;
    _loadIntoWebViewIfReady();
  }

  Future<void> _loadIntoWebViewIfReady() async {
    if (webViewController == null || htmlContent == null) return;

    await webViewController!.loadData(
      data: htmlContent!,
      baseUrl: WebUri(contentBaseUrl ?? mediguideApiBaseUrl),
    );

    debugPrint('🌐 HTML loaded into WebView');
  }

  void refreshWebView() {
    webViewController?.reload();
  }

  /// ================================
  /// USAGE TRACKING
  /// ================================
  Future<void> _startUsageTracking() async {
    try {
      final user = AuthService.to.currentUser.value;
      if (user == null || calculator == null) return;

      sessionStartTime = DateTime.now();

      final usageLogData = CalculatorUsageLog.forCreate(
        userId: user.id,
        calculatorId: calculator!.id,
        sessionStart: sessionStartTime!,
        calculatorType: calculator!.type,
      );

      final record = await BackendApiService.to.createRecord(
        collectionName: CalculatorUsageLog.collection,
        data: usageLogData,
      );

      currentUsageLogId = record.id;
    } catch (e) {
      debugPrint('⚠️ Usage tracking failed: $e');
    }
  }

  Future<void> _endUsageTracking() async {
    try {
      if (currentUsageLogId == null || sessionStartTime == null) return;

      final end = DateTime.now();
      final duration = end.difference(sessionStartTime!);

      if (duration.inSeconds < 5) return;

      await BackendApiService.to.updateRecord(
        collectionName: CalculatorUsageLog.collection,
        recordId: currentUsageLogId!,
        data: CalculatorUsageLog.forSessionEnd(sessionEnd: end),
      );
    } catch (e) {
      debugPrint('⚠️ End tracking failed: $e');
    }
  }

  @override
  void onClose() {
    _endUsageTracking();
    webViewController = null;
    super.onClose();
  }

  // ==========================================================
  // ✅ COMPATIBILITY LAYER (FIXES YOUR UI ERRORS)
  // ==========================================================

  String? get fileUrl => htmlContent;

  void retry() {
    if (calculator != null) {
      loadCalculatorFile();
    }
  }

  void onLoadStart(InAppWebViewController controller, WebUri? url) {
    isWebViewReady.value = false;
    debugPrint('🌐 WebView start: $url');
  }

  void onLoadStop(InAppWebViewController controller, WebUri? url) {
    isWebViewReady.value = true;
    debugPrint('🌐 WebView stop: $url');
  }

  void onLoadError(
    InAppWebViewController controller,
    WebUri? url,
    int code,
    String message,
  ) {
    hasError.value = true;
    errorMessage = message;
    debugPrint('❌ WebView error [$code]: $message');
  }

  Future<Map<String, dynamic>?> _readCacheMetadata(File file) async {
    if (!await file.exists()) {
      return null;
    }

    try {
      final decoded = jsonDecode(await file.readAsString());
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  bool _isCacheCurrent(Map<String, dynamic>? metadata, String downloadUrl) {
    if (metadata == null) {
      return false;
    }

    return metadata['version']?.toString() == calculator!.version &&
        metadata['appFile']?.toString() == calculator!.appFile &&
        metadata['downloadUrl']?.toString() == downloadUrl;
  }

  String _deriveContentBaseUrl(String downloadUrl) {
    final uri = Uri.parse(downloadUrl);
    final segments = uri.pathSegments.toList();
    if (segments.isEmpty) {
      return mediguideApiBaseUrl;
    }

    segments.removeLast();
    final directoryPath = segments.isEmpty ? '/' : '/${segments.join('/')}';
    return uri
        .replace(path: directoryPath, query: null, fragment: null)
        .toString();
  }
}
