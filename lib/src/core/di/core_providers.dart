import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:porcitech_mobile/src/core/constants/api_constants.dart';
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

/// Notifier para gestionar dinámicamente la IP/URL del servidor desde el teléfono.
class ApiBaseUrlNotifier extends Notifier<String> {
  static const String _prefKey = 'porcitech_custom_api_base_url';

  @override
  String build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final saved = prefs.getString(_prefKey);
    if (saved != null && saved.trim().isNotEmpty) {
      return normalizeServerInput(saved);
    }
    return ApiConstants.defaultBaseUrl;
  }

  static String normalizeServerInput(String raw) {
    var v = raw.trim();
    if (v.isEmpty) return ApiConstants.defaultBaseUrl;
    if (!v.startsWith('http://') && !v.startsWith('https://')) {
      v = 'http://$v';
    }
    while (v.endsWith('/')) {
      v = v.substring(0, v.length - 1);
    }
    final uri = Uri.tryParse(v);
    if (uri != null && !uri.hasPort && uri.scheme == 'http') {
      v = '${uri.scheme}://${uri.host}:8000${uri.path}';
    }
    if (!v.endsWith('/api/v1')) {
      v = '$v/api/v1';
    }
    return v;
  }

  Future<void> setServerUrl(String rawInput) async {
    final normalized = normalizeServerInput(rawInput);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_prefKey, normalized);
    state = normalized;
  }
}

final apiBaseUrlProvider =
    NotifierProvider<ApiBaseUrlNotifier, String>(ApiBaseUrlNotifier.new);

/// Provider para el cliente HTTP Dio configurado con interceptores y autorización Bearer.
final dioClientProvider = Provider<DioClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  final networkInfo = ref.watch(networkInfoProvider);
  final sessionController = ref.watch(_sessionExpiredControllerProvider);
  final baseUrl = ref.watch(apiBaseUrlProvider);

  return DioClient(
    secureStorage: secureStorage,
    networkInfo: networkInfo,
    baseUrl: baseUrl,
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
