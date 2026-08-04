import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/core_providers.dart';

final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  yield _hasConnection(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(_hasConnection).distinct();
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

bool _hasConnection(List<ConnectivityResult> results) => results.any(
  (result) =>
      result == ConnectivityResult.mobile ||
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.ethernet,
);
