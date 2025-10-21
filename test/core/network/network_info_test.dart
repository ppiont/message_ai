import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/core/network/network_info.dart';
import 'package:mocktail/mocktail.dart';

class MockConnectivity extends Mock implements Connectivity {}

void main() {
  late NetworkInfo networkInfo;
  late MockConnectivity mockConnectivity;

  setUp(() {
    mockConnectivity = MockConnectivity();
    networkInfo = NetworkInfoImpl(mockConnectivity);
  });

  group('NetworkInfo', () {
    group('isConnected', () {
      test('should return true when connected to wifi', () async {
        when(() => mockConnectivity.checkConnectivity()).thenAnswer(
          (_) async => [ConnectivityResult.wifi],
        );

        final result = await networkInfo.isConnected;

        expect(result, true);
        verify(() => mockConnectivity.checkConnectivity()).called(1);
      });

      test('should return true when connected to mobile', () async {
        when(() => mockConnectivity.checkConnectivity()).thenAnswer(
          (_) async => [ConnectivityResult.mobile],
        );

        final result = await networkInfo.isConnected;

        expect(result, true);
      });

      test('should return true when connected to ethernet', () async {
        when(() => mockConnectivity.checkConnectivity()).thenAnswer(
          (_) async => [ConnectivityResult.ethernet],
        );

        final result = await networkInfo.isConnected;

        expect(result, true);
      });

      test('should return false when not connected', () async {
        when(() => mockConnectivity.checkConnectivity()).thenAnswer(
          (_) async => [ConnectivityResult.none],
        );

        final result = await networkInfo.isConnected;

        expect(result, false);
      });

      test('should return true when connected to multiple networks', () async {
        when(() => mockConnectivity.checkConnectivity()).thenAnswer(
          (_) async => [ConnectivityResult.wifi, ConnectivityResult.mobile],
        );

        final result = await networkInfo.isConnected;

        expect(result, true);
      });

      test('should return true if any connection is active', () async {
        when(() => mockConnectivity.checkConnectivity()).thenAnswer(
          (_) async => [ConnectivityResult.none, ConnectivityResult.wifi],
        );

        final result = await networkInfo.isConnected;

        expect(result, true);
      });
    });

    group('onConnectivityChanged', () {
      test('should emit true when connection becomes available', () {
        final controller = Stream<List<ConnectivityResult>>.fromIterable([
          [ConnectivityResult.none],
          [ConnectivityResult.wifi],
        ]);

        when(() => mockConnectivity.onConnectivityChanged).thenAnswer(
          (_) => controller,
        );

        expect(
          networkInfo.onConnectivityChanged,
          emitsInOrder([false, true]),
        );
      });

      test('should emit false when connection is lost', () {
        final controller = Stream<List<ConnectivityResult>>.fromIterable([
          [ConnectivityResult.wifi],
          [ConnectivityResult.none],
        ]);

        when(() => mockConnectivity.onConnectivityChanged).thenAnswer(
          (_) => controller,
        );

        expect(
          networkInfo.onConnectivityChanged,
          emitsInOrder([true, false]),
        );
      });

      test('should emit changes when switching between connection types', () {
        final controller = Stream<List<ConnectivityResult>>.fromIterable([
          [ConnectivityResult.wifi],
          [ConnectivityResult.mobile],
          [ConnectivityResult.ethernet],
        ]);

        when(() => mockConnectivity.onConnectivityChanged).thenAnswer(
          (_) => controller,
        );

        expect(
          networkInfo.onConnectivityChanged,
          emitsInOrder([true, true, true]),
        );
      });

      test('should handle rapid connectivity changes', () {
        final controller = Stream<List<ConnectivityResult>>.fromIterable([
          [ConnectivityResult.wifi],
          [ConnectivityResult.none],
          [ConnectivityResult.wifi],
          [ConnectivityResult.none],
          [ConnectivityResult.mobile],
        ]);

        when(() => mockConnectivity.onConnectivityChanged).thenAnswer(
          (_) => controller,
        );

        expect(
          networkInfo.onConnectivityChanged,
          emitsInOrder([true, false, true, false, true]),
        );
      });
    });

    group('connectionType', () {
      test('should return wifi connection type', () async {
        when(() => mockConnectivity.checkConnectivity()).thenAnswer(
          (_) async => [ConnectivityResult.wifi],
        );

        final result = await networkInfo.connectionType;

        expect(result, [ConnectivityResult.wifi]);
      });

      test('should return mobile connection type', () async {
        when(() => mockConnectivity.checkConnectivity()).thenAnswer(
          (_) async => [ConnectivityResult.mobile],
        );

        final result = await networkInfo.connectionType;

        expect(result, [ConnectivityResult.mobile]);
      });

      test('should return none connection type', () async {
        when(() => mockConnectivity.checkConnectivity()).thenAnswer(
          (_) async => [ConnectivityResult.none],
        );

        final result = await networkInfo.connectionType;

        expect(result, [ConnectivityResult.none]);
      });

      test('should return multiple connection types', () async {
        when(() => mockConnectivity.checkConnectivity()).thenAnswer(
          (_) async => [ConnectivityResult.wifi, ConnectivityResult.ethernet],
        );

        final result = await networkInfo.connectionType;

        expect(result, [ConnectivityResult.wifi, ConnectivityResult.ethernet]);
      });
    });

    group('Edge Cases', () {
      test('should handle empty connectivity result list', () async {
        when(() => mockConnectivity.checkConnectivity()).thenAnswer(
          (_) async => [],
        );

        final result = await networkInfo.isConnected;

        expect(result, false);
      });

      test('should handle VPN connection type', () async {
        when(() => mockConnectivity.checkConnectivity()).thenAnswer(
          (_) async => [ConnectivityResult.vpn],
        );

        final result = await networkInfo.isConnected;

        // VPN is not considered a direct connection
        expect(result, false);
      });

      test('should handle Bluetooth connection type', () async {
        when(() => mockConnectivity.checkConnectivity()).thenAnswer(
          (_) async => [ConnectivityResult.bluetooth],
        );

        final result = await networkInfo.isConnected;

        // Bluetooth is not considered a typical internet connection
        expect(result, false);
      });
    });

    group('Integration Scenarios', () {
      test('offline to online transition', () async {
        // Start offline
        when(() => mockConnectivity.checkConnectivity()).thenAnswer(
          (_) async => [ConnectivityResult.none],
        );

        final startResult = await networkInfo.isConnected;
        expect(startResult, false);

        // Go online
        when(() => mockConnectivity.checkConnectivity()).thenAnswer(
          (_) async => [ConnectivityResult.wifi],
        );

        final endResult = await networkInfo.isConnected;
        expect(endResult, true);
      });

      test('wifi to mobile handoff', () async {
        // Connected via wifi
        when(() => mockConnectivity.checkConnectivity()).thenAnswer(
          (_) async => [ConnectivityResult.wifi],
        );

        final wifiResult = await networkInfo.isConnected;
        expect(wifiResult, true);

        // Switch to mobile
        when(() => mockConnectivity.checkConnectivity()).thenAnswer(
          (_) async => [ConnectivityResult.mobile],
        );

        final mobileResult = await networkInfo.isConnected;
        expect(mobileResult, true);
      });
    });
  });
}
