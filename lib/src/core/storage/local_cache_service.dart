import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio de almacenamiento local y gestión de cola de sincronización Offline-First.
/// Permite trabajar en galpones sin señal y sincronizar transacciones al reconectar.
class LocalCacheService {
  final SharedPreferences _prefs;

  LocalCacheService(this._prefs);

  static const String _keyOfflineMode = 'porcitech_offline_mode_enabled';
  static const String _keyOfflineQueue = 'porcitech_sync_offline_queue';
  static const String _keyCachedAnimals = 'porcitech_cached_animals';
  static const String _keyCachedLotes = 'porcitech_cached_lotes';
  static const String _keyCachedDashboard = 'porcitech_cached_dashboard';

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

  // --- Cola de Sincronización Offline (`offline-queue`) ---
  List<Map<String, dynamic>> getOfflineQueue() {
    final rawJson = _prefs.getString(_keyOfflineQueue);
    if (rawJson == null || rawJson.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(rawJson);
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> enqueueSyncItem({
    required String endpoint,
    required String method,
    required Map<String, dynamic> payload,
    required String description,
  }) async {
    final queue = getOfflineQueue();
    final item = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'endpoint': endpoint,
      'method': method,
      'payload': payload,
      'description': description,
      'createdAt': DateTime.now().toIso8601String(),
    };
    queue.add(item);
    await _prefs.setString(_keyOfflineQueue, jsonEncode(queue));
  }

  Future<void> removeSyncItem(String id) async {
    final queue = getOfflineQueue();
    queue.removeWhere((item) => item['id'] == id);
    await _prefs.setString(_keyOfflineQueue, jsonEncode(queue));
  }

  Future<void> clearOfflineQueue() async {
    await _prefs.remove(_keyOfflineQueue);
  }

  // --- Caché de Registros Locales (Expedientes y Lotes) ---
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
}
