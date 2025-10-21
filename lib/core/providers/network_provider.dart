import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_ai/core/network/network_info.dart';

/// Provider for the Connectivity instance
///
/// Singleton instance used by NetworkInfo
final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

/// Provider for NetworkInfo service
///
/// Provides access to network connectivity status and changes
final networkInfoProvider = Provider<NetworkInfo>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return NetworkInfoImpl(connectivity);
});

/// Provider that streams network connectivity status
///
/// Emits true when connected, false when disconnected
/// Use this to reactively update UI based on connection status
final networkStatusProvider = StreamProvider<bool>((ref) {
  final networkInfo = ref.watch(networkInfoProvider);
  return networkInfo.onConnectivityChanged;
});

/// Provider that checks current connectivity status (one-time check)
///
/// Returns true if device currently has internet connection
final isConnectedProvider = FutureProvider<bool>((ref) async {
  final networkInfo = ref.watch(networkInfoProvider);
  return await networkInfo.isConnected;
});
