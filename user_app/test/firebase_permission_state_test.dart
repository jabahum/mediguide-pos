import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/core/services/firebase_service.dart';

void main() {
  test('maps every Firebase notification permission state explicitly', () {
    expect(
      MediGuideFirebaseService.permissionStateFor(
        AuthorizationStatus.notDetermined,
        previouslyRequested: false,
      ),
      AppNotificationPermissionState.notDetermined,
    );
    expect(
      MediGuideFirebaseService.permissionStateFor(
        AuthorizationStatus.provisional,
        previouslyRequested: false,
      ),
      AppNotificationPermissionState.provisional,
    );
    expect(
      MediGuideFirebaseService.permissionStateFor(
        AuthorizationStatus.authorized,
        previouslyRequested: true,
      ),
      AppNotificationPermissionState.authorized,
    );
    expect(
      MediGuideFirebaseService.permissionStateFor(
        AuthorizationStatus.denied,
        previouslyRequested: false,
      ),
      AppNotificationPermissionState.denied,
    );
    expect(
      MediGuideFirebaseService.permissionStateFor(
        AuthorizationStatus.denied,
        previouslyRequested: true,
      ),
      AppNotificationPermissionState.permanentlyDenied,
    );
  });
}
