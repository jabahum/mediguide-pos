import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:user_app/core/config/app_keys.dart';
import 'package:user_app/core/utils/app_message.dart';

class Common {
  Common._();

  static void dismissKeyboard() =>
      FocusManager.instance.primaryFocus?.unfocus();

  static String parseApiError(Object error) {
    final message = error.toString().trim();
    if (message.startsWith('Exception:')) {
      return message.substring('Exception:'.length).trim();
    }
    if (message.isEmpty) {
      return 'An error occurred. Please try again.';
    }
    return message;
  }

  /// Make a phone call
  static Future<void> makeCall(
    String phoneNumber, {
    String? contactName,
  }) async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        AppMessage.error(
          AppKeys.navigatorKey.currentContext!,
          'Phone app is not available on this device',
        );
      }
    } catch (e) {
      AppMessage.error(
        AppKeys.navigatorKey.currentContext!,
        'Failed to initiate call: $e',
      );
    }
  }

  /// Send an email
  static Future<void> sendEmail(
    String email, {
    String? subject,
    String? body,
    String? contactName,
  }) async {
    try {
      final Map<String, String> queryParams = {};
      if (subject != null) queryParams['subject'] = subject;
      if (body != null) queryParams['body'] = body;

      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: email,
        query: queryParams.isNotEmpty
            ? queryParams.entries
                  .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
                  .join('&')
            : null,
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        AppMessage.error(
          AppKeys.navigatorKey.currentContext!,
          'Email app is not available on this device',
        );
      }
    } catch (e) {
      AppMessage.error(
        AppKeys.navigatorKey.currentContext!,
        'Failed to open email app: $e',
      );
    }
  }
}
