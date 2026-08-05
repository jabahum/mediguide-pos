import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/core/network/network_info.dart';
import 'package:user_app/core/services/connectivity_service.dart';

final networkInfoProvider = Provider<NetworkInfo>(
  (ref) => ConnectivityService(),
);

final connectivityProvider = StreamProvider<bool>((ref) async* {
  final networkInfo = ref.watch(networkInfoProvider);
  yield await networkInfo.isConnected;
  yield* networkInfo.connectionChanges;
});

/// Starts token refresh only on an observed offline-to-online transition.
/// Watching this provider at the app root owns and disposes the listener.
final backendReconnectProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<bool>>(connectivityProvider, (previous, next) {
    if (previous?.valueOrNull == false && next.valueOrNull == true) {
      final api = ref.read(backendApiServiceProvider);
      if (api.isAuthenticated) {
        api.refreshAuth().catchError((Object _) {});
      }
    }
  });
});
