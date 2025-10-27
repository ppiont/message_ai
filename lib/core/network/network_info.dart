import 'package:connectivity_plus/connectivity_plus.dart';

/// Service for monitoring network connectivity status
///
/// Provides both current connectivity state and a stream of changes.
/// Essential for offline-first functionality and sync operations.
abstract class NetworkInfo {
  /// Checks if device currently has an active network connection
  ///
  /// Returns true if connected to wifi, mobile, or ethernet
  Future<bool> get isConnected;

  /// Stream of network connectivity changes
  ///
  /// Emits whenever network status changes (wifi ↔ mobile ↔ none)
  /// Use for triggering sync operations on reconnection
  Stream<bool> get onConnectivityChanged;

  /// Gets the current connection type
  ///
  /// Returns the specific connectivity type (wifi, mobile, ethernet, none)
  Future<List<ConnectivityResult>> get connectionType;
}

/// Implementation of [NetworkInfo] using connectivity_plus package
class NetworkInfoImpl implements NetworkInfo {
  NetworkInfoImpl(this._connectivity);
  final Connectivity _connectivity;

  @override
  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return _isConnectedResult(result);
  }

  @override
  Stream<bool> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged.map(_isConnectedResult);

  @override
  Future<List<ConnectivityResult>> get connectionType async =>
      _connectivity.checkConnectivity();

  /// Determines if connectivity result represents an active connection
  bool _isConnectedResult(List<ConnectivityResult> results) => results.any(
    (result) =>
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet,
  );
}
