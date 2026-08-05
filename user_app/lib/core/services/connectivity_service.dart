import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:user_app/core/network/network_info.dart';

final class ConnectivityService implements NetworkInfo {
  ConnectivityService({
    Connectivity? connectivity,
    InternetConnection? internetConnection,
  }) : _connectivity = connectivity ?? Connectivity(),
       _internetConnection = internetConnection ?? InternetConnection();

  final Connectivity _connectivity;
  final InternetConnection _internetConnection;

  @override
  Future<bool> get isConnected async {
    if (!_hasConnection(await _connectivity.checkConnectivity())) return false;
    return _internetConnection.hasInternetAccess;
  }

  @override
  Stream<bool> get connectionChanges => _internetConnection.onStatusChange
      .map((status) => status == InternetStatus.connected)
      .distinct();

  static bool _hasConnection(List<ConnectivityResult> results) => results.any(
    (result) =>
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet,
  );
}
