import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Servicio de almacenamiento local y gestión de cola Outbox FIFO Offline-First.
/// Permite trabajar en galpones sin señal, asignar UUID v4 idempotentes (HU32)
/// y sincronizar transacciones al reconectar.
class LocalCacheService {
  final SharedPreferences _prefs;
  static const Uuid _uuid = Uuid();
  Future<void> _queueLock = Future.value();

  LocalCacheService(this._prefs);

  Future<T> _withQueueLock<T>(Future<T> Function() action) {
    final next = _queueLock.then((_) => action(), onError: (_) => action());
    _queueLock = next.then((_) {}, onError: (_) {});
    return next;
  }

  static const String _keyOfflineMode = 'porcitech_offline_mode_enabled';
  static const String _keyOfflineQueue = 'porcitech_sync_offline_queue';
  static const String _keyCachedAnimals = 'porcitech_cached_animals';
  static const String _keyCachedLotes = 'porcitech_cached_lotes';
  static const String _keyCachedDashboard = 'porcitech_cached_dashboard';
  static const String _keyCachedInventory = 'porcitech_cached_inventory';
  static const String _keyCachedWithdrawals = 'porcitech_cached_withdrawals';
  static const String _keyCachedProtocols = 'porcitech_cached_protocols';
  static const String _keyCachedServices = 'porcitech_cached_services';
  static const String _keyLastCatalogSyncAt = 'porcitech_last_catalog_sync_at';

  /// Inicializador asíncrono para inyección en el árbol de Riverpod.
  static Future<LocalCacheService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalCacheService(prefs);
  }

  // --- Modo Offline Forzado por el Usuario ---
  bool isOfflineModeEnabled() {
    return _prefs.getBool(_keyOfflineMode) ?? false;
  }

  Future<void> setOfflineMode(bool enabled) async {
    await _prefs.setBool(_keyOfflineMode, enabled);
  }

  // --- Fecha de Última Descarga de Catálogo Offline (HU34) ---
  DateTime? getLastCatalogSyncAt() {
    final raw = _prefs.getString(_keyLastCatalogSyncAt);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> setLastCatalogSyncAt(DateTime timestamp) async {
    await _prefs.setString(_keyLastCatalogSyncAt, timestamp.toIso8601String());
  }

  // --- Cola Outbox FIFO Offline (`offline-queue`) ---
  List<Map<String, dynamic>> getOfflineQueue() {
    final rawJson = _prefs.getString(_keyOfflineQueue);
    if (rawJson == null || rawJson.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(rawJson);
      return list.whereType<Map<String, dynamic>>().toList();
    } catch (_) {
      return [];
    }
  }

  int getPendingSyncCount() {
    return getOfflineQueue()
        .where((item) => (item['status']?.toString() ?? 'pendiente') != 'enviado')
        .length;
  }

  Future<String> enqueueSyncItem({
    required String endpoint,
    required String method,
    required Map<String, dynamic> payload,
    required String description,
    String? filePath,
  }) {
    return _withQueueLock(() async {
      final queue = getOfflineQueue();
      final eventUuid = _uuid.v4();
      final enrichedPayload = Map<String, dynamic>.from(payload);
      enrichedPayload.putIfAbsent('id_local', () => eventUuid);

      final item = <String, dynamic>{
        'id': eventUuid,
        'idLocal': eventUuid,
        'endpoint': endpoint,
        'method': method,
        'payload': enrichedPayload,
        'description': description,
        'status': 'pendiente',
        'errorMessage': null,
        'retryCount': 0,
        if (filePath != null && filePath.isNotEmpty) 'filePath': filePath,
        'createdAt': DateTime.now().toIso8601String(),
      };
      queue.add(item);
      await _prefs.setString(_keyOfflineQueue, jsonEncode(queue));
      return eventUuid;
    });
  }

  Future<void> updateSyncItem(
    String id, {
    String? status,
    String? errorMessage,
    bool clearError = false,
    int? retryCount,
    Map<String, dynamic>? payloadOverride,
  }) {
    return _withQueueLock(() async {
      final queue = getOfflineQueue();
      final updated = queue.map((item) {
        if (item['id']?.toString() == id) {
          final copy = Map<String, dynamic>.from(item);
          if (status != null) copy['status'] = status;
          if (clearError) {
            copy['errorMessage'] = null;
          } else if (errorMessage != null) {
            copy['errorMessage'] = errorMessage;
          }
          if (retryCount != null) copy['retryCount'] = retryCount;
          if (payloadOverride != null) copy['payload'] = payloadOverride;
          return copy;
        }
        return item;
      }).toList();
      await _prefs.setString(_keyOfflineQueue, jsonEncode(updated));
    });
  }

  Future<void> markSyncItemForRetry(String id) async {
    await updateSyncItem(id, status: 'pendiente', clearError: true);
  }

  Future<void> removeSyncItem(String id) {
    return _withQueueLock(() async {
      final queue = getOfflineQueue();
      queue.removeWhere((item) => item['id']?.toString() == id);
      await _prefs.setString(_keyOfflineQueue, jsonEncode(queue));
    });
  }

  Future<void> clearSentSyncItems() {
    return _withQueueLock(() async {
      final queue = getOfflineQueue();
      queue.removeWhere((item) => item['status']?.toString() == 'enviado');
      await _prefs.setString(_keyOfflineQueue, jsonEncode(queue));
    });
  }

  Future<void> clearOfflineQueue() {
    return _withQueueLock(() async {
      await _prefs.remove(_keyOfflineQueue);
    });
  }

  // --- Caché de Registros Locales (Expedientes, Lotes, Inventario, Sanidad) ---
  Future<void> cacheJson(String key, dynamic data) async {
    await _prefs.setString(key, jsonEncode(data));
  }

  dynamic getCachedJson(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  String get keyCachedAnimals => _keyCachedAnimals;
  String get keyCachedLotes => _keyCachedLotes;
  String get keyCachedDashboard => _keyCachedDashboard;
  String get keyCachedInventory => _keyCachedInventory;
  String get keyCachedWithdrawals => _keyCachedWithdrawals;
  String get keyCachedProtocols => _keyCachedProtocols;
  String get keyCachedServices => _keyCachedServices;
}
