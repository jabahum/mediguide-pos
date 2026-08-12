import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/app/router/route_names.dart';
import 'package:user_app/core/constants/app_constants.dart';
import 'package:user_app/core/storage/local_storage_service.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_state.dart';

String? appRouteGuard(Ref ref, GoRouterState state) {
  final auth = ref.read(authControllerProvider);
  if (auth.isLoading) return null;

  final phase = auth.valueOrNull?.phase ?? AuthPhase.unauthenticated;
  final authenticated = auth.valueOrNull?.isAuthenticated ?? false;
  final location = state.uri.toString();
  final matchedLocation = state.matchedLocation;
  final publicRoute = AppRoutes.isPublic(location);

  if (!PreferenceUtils.containsKey(SharedPreferencesKeys.notFirstTime) &&
      matchedLocation != AppRoutes.onboarding) {
    return '${AppRoutes.onboarding}?redirect=${Uri.encodeComponent(location)}';
  }
  if (!authenticated && !publicRoute && phase != AuthPhase.authenticating) {
    final destination = Uri.encodeComponent(location);
    return '${AppRoutes.login}?redirect=$destination&reason=authentication_required';
  }
  if (authenticated &&
      (matchedLocation == AppRoutes.login ||
          matchedLocation == AppRoutes.register)) {
    final redirect = state.uri.queryParameters['redirect'];
    return AppRoutes.safeDestination(redirect);
  }
  return null;
}
