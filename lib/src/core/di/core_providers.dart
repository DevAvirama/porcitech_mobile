import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:porcitech_mobile/src/core/network/dio_client.dart';
import 'package:porcitech_mobile/src/core/network/network_info.dart';
import 'package:porcitech_mobile/src/core/storage/local_cache_service.dart';
import 'package:porcitech_mobile/src/core/storage/secure_storage_service.dart';

/// Provider para el almacenamiento seguro (KeyStore/Keychain).
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// Provider para la instancia de SharedPreferences inyectada en el arranque.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences debe inicializarse antes de runApp');
});

/// Provider para el servicio de caché local y cola de sincronización.
final localCacheServiceProvider = Provider<LocalCacheService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalCacheService(prefs);
});

/// Provider para el monitor de conectividad de red.
final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfoImpl();
});

/// Stream provider para observar cambios de conexión en tiempo real.
final connectivityStreamProvider = StreamProvider<bool>((ref) {
  final networkInfo = ref.watch(networkInfoProvider);
  return networkInfo.onConnectivityChanged;
});

/// Bus interno para notificar expiración de sesión (HTTP 401) desde Dio hacia AuthNotifier.
final _sessionExpiredControllerProvider =
    Provider<StreamController<void>>((ref) {
  final controller = StreamController<void>.broadcast();
  ref.onDispose(controller.close);
  return controller;
});

final sessionExpiredStreamProvider = Provider<Stream<void>>((ref) {
  return ref.watch(_sessionExpiredControllerProvider).stream;
});

/// Provider para el cliente HTTP Dio configurado con interceptores y autorización Bearer.
final dioClientProvider = Provider<DioClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  final networkInfo = ref.watch(networkInfoProvider);
  final sessionController = ref.watch(_sessionExpiredControllerProvider);

  return DioClient(
    secureStorage: secureStorage,
    networkInfo: networkInfo,
    onSessionExpired: () {
      if (!sessionController.isClosed) {
        sessionController.add(null);
      }
    },
  );
});

/// Notifier reactivo del interruptor de Modo Offline en campo.
class OfflineModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    final cacheService = ref.watch(localCacheServiceProvider);
    return cacheService.isOfflineModeEnabled();
  }

  Future<void> toggleOffline(bool enabled) async {
    final cacheService = ref.read(localCacheServiceProvider);
    await cacheService.setOfflineMode(enabled);
    state = enabled;
  }
}

final offlineModeProvider =
    NotifierProvider<OfflineModeNotifier, bool>(OfflineModeNotifier.new);
