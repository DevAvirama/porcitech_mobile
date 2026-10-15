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
  final List<SyncItemEntity> queueItems;
  final String? message;
  final Map<String, dynamic>? userProfile;

  const SyncState({
    this.isSyncing = false,
    this.queueItems = const [],
    this.message,
    this.userProfile,
  });

  SyncState copyWith({
    bool? isSyncing,
    List<SyncItemEntity>? queueItems,
    String? message,
    Map<String, dynamic>? userProfile,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      queueItems: queueItems ?? this.queueItems,
      message: message,
      userProfile: userProfile ?? this.userProfile,
    );
  }
}

class SyncNotifier extends Notifier<SyncState> {
  @override
  SyncState build() {
    Future.microtask(() {
      refreshQueue();
      loadProfile();
    });
    return const SyncState();
  }

  SyncRepository get _repository => ref.read(syncRepositoryProvider);

  void refreshQueue() {
    final list = _repository.getPendingQueue();
    state = state.copyWith(queueItems: list);
  }

  Future<void> loadProfile() async {
    final result = await _repository.getUserProfile();
    result.fold(
      (_) => null,
      (profile) => state = state.copyWith(userProfile: profile),
    );
  }

  Future<bool> executeSync() async {
    state = state.copyWith(isSyncing: true, message: null);
    final result = await _repository.syncOfflineQueue();

    return result.fold(
      (failure) {
        state = state.copyWith(isSyncing: false, message: failure.message);
        return false;
      },
      (count) {
        refreshQueue();
        state = state.copyWith(
          isSyncing: false,
          message: '$count registros sincronizados exitosamente con FastAPI.',
        );
        return true;
      },
    );
  }

  Future<void> clearQueue() async {
    await _repository.clearQueue();
    refreshQueue();
  }
}

final syncNotifierProvider =
    NotifierProvider<SyncNotifier, SyncState>(SyncNotifier.new);
