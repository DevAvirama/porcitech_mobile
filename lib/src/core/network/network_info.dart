import 'package:connectivity_plus/connectivity_plus.dart';

/// Interfaz abstracta para verificación del estado de conexión de red.
abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get onConnectivityChanged;
}

/// Implementación de NetworkInfo usando `connectivity_plus`.
class NetworkInfoImpl implements NetworkInfo {
  final Connectivity _connectivity;

  NetworkInfoImpl({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  @override
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    if (results.isEmpty) return false;
    return !results.contains(ConnectivityResult.none);
  }

  @override
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map((results) {
      if (results.isEmpty) return false;
      return !results.contains(ConnectivityResult.none);
    });
  }
}
