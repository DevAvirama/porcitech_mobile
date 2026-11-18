import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:porcitech_mobile/src/core/di/core_providers.dart';
import 'package:porcitech_mobile/src/features/sync/data/datasources/sync_remote_datasource.dart';
import 'package:porcitech_mobile/src/features/sync/data/repositories/sync_repository_impl.dart';
import 'package:porcitech_mobile/src/features/sync/domain/entities/sync_item_entity.dart';
import 'package:porcitech_mobile/src/features/sync/domain/repositories/sync_repository.dart';

final syncRemoteDataSourceProvider = Provider<SyncRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return SyncRemoteDataSourceImpl(dioClient);
});

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  final remote = ref.watch(syncRemoteDataSourceProvider);
  final cache = ref.watch(localCacheServiceProvider);
  return SyncRepositoryImpl(remoteDataSource: remote, cacheService: cache);
});

class SyncState {
  final bool isSyncing;
  final bool isDownloadingCatalog;
  final List<SyncItemEntity> queueItems;
  final String? message;
  final bool isError;
  final DateTime? lastCatalogSyncAt;
  final Map<String, dynamic>? userProfile;

  const SyncState({
    this.isSyncing = false,
    this.isDownloadingCatalog = false,
    this.queueItems = const [],
    this.message,
    this.isError = false,
    this.lastCatalogSyncAt,
    this.userProfile,
  });

  int get pendingCount =>
      queueItems.where((i) => i.status == SyncItemStatus.pendiente).length;
  int get sentCount =>
      queueItems.where((i) => i.status == SyncItemStatus.enviado).length;
  int get errorCount =>
      queueItems.where((i) => i.status == SyncItemStatus.error).length;
  int get conflictCount =>
      queueItems.where((i) => i.status == SyncItemStatus.conflicto).length;
  int get totalUnsentCount =>
      queueItems.where((i) => i.status != SyncItemStatus.enviado).length;

  SyncState copyWith({
    bool? isSyncing,
    bool? isDownloadingCatalog,
    List<SyncItemEntity>? queueItems,
    String? message,
    bool clearMessage = false,
    bool? isError,
    DateTime? lastCatalogSyncAt,
    Map<String, dynamic>? userProfile,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      isDownloadingCatalog: isDownloadingCatalog ?? this.isDownloadingCatalog,
      queueItems: queueItems ?? this.queueItems,
      message: clearMessage ? null : (message ?? this.message),
      isError: isError ?? this.isError,
      lastCatalogSyncAt: lastCatalogSyncAt ?? this.lastCatalogSyncAt,
      userProfile: userProfile ?? this.userProfile,
    );
  }
}

class SyncNotifier extends Notifier<SyncState> {
  @override
  SyncState build() {
    // Auto-sincronización FIFO al recuperar conectividad (HU32)
    ref.listen<AsyncValue<bool>>(connectivityStreamProvider, (prev, next) {
      final isOnline = next.asData?.value ?? false;
      final wasOnline = prev?.asData?.value ?? false;
      final offlineForced = ref.read(offlineModeProvider);
      if (isOnline && !wasOnline && !offlineForced && !state.isSyncing) {
        if (state.totalUnsentCount > 0) {
          executeSync();
        }
      }
    });

    final initialItems = _repository.getPendingQueue();
    Future.microtask(() {
      loadProfile();
    });

    return SyncState(
      queueItems: initialItems,
      lastCatalogSyncAt: _repository.getLastCatalogSyncAt(),
    );
  }

  SyncRepository get _repository => ref.read(syncRepositoryProvider);

  void refreshQueue() {
    final list = _repository.getPendingQueue();
    state = state.copyWith(
      queueItems: list,
      lastCatalogSyncAt: _repository.getLastCatalogSyncAt(),
    );
  }

  Future<void> loadProfile() async {
    final result = await _repository.getUserProfile();
    result.fold(
      (_) => null,
      (profile) => state = state.copyWith(userProfile: profile),
    );
  }

  Future<bool> executeSync() async {
    if (state.isSyncing) return false;
    state = state.copyWith(isSyncing: true, clearMessage: true, isError: false);
    final result = await _repository.syncOfflineQueue();
    refreshQueue();

    return result.fold(
      (failure) {
        state = state.copyWith(
          isSyncing: false,
          message: failure.message,
          isError: true,
        );
        return false;
      },
      (count) {
        state = state.copyWith(
          isSyncing: false,
          message: '$count registros sincronizados correctamente.',
          isError: false,
        );
        return true;
      },
    );
  }

  Future<bool> retryItem(String id) async {
    if (state.isSyncing) return false;
    state = state.copyWith(isSyncing: true, clearMessage: true, isError: false);
    final result = await _repository.retrySingleItem(id);
    refreshQueue();

    return result.fold(
      (failure) {
        state = state.copyWith(
          isSyncing: false,
          message: failure.message,
          isError: true,
        );
        return false;
      },
      (_) {
        state = state.copyWith(
          isSyncing: false,
          message: 'Evento reenviado y confirmado por el servidor.',
          isError: false,
        );
        return true;
      },
    );
  }

  Future<void> removeItem(String id) async {
    await _repository.removeItem(id);
    refreshQueue();
  }

  Future<void> clearSentItems() async {
    await _repository.clearSentItems();
    refreshQueue();
  }

  Future<void> clearQueue() async {
    await _repository.clearQueue();
    refreshQueue();
  }

  Future<bool> downloadOfflineCatalog() async {
    state = state.copyWith(
      isDownloadingCatalog: true,
      clearMessage: true,
      isError: false,
    );
    final result = await _repository.downloadOfflineCatalog();

    return result.fold(
      (failure) {
        state = state.copyWith(
          isDownloadingCatalog: false,
          message: failure.message,
          isError: true,
        );
        return false;
      },
      (syncTime) {
        state = state.copyWith(
          isDownloadingCatalog: false,
          lastCatalogSyncAt: syncTime,
          message: 'Catálogo completo (animales, corrales, insumos y sanidad) descargado para uso sin red.',
          isError: false,
        );
        return true;
      },
    );
  }
}

final syncNotifierProvider =
    NotifierProvider<SyncNotifier, SyncState>(SyncNotifier.new);
