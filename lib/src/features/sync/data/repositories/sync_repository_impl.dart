import 'package:fpdart/fpdart.dart';
import 'package:porcitech_mobile/src/core/errors/exceptions.dart';
import 'package:porcitech_mobile/src/core/errors/failures.dart';
import 'package:porcitech_mobile/src/core/storage/local_cache_service.dart';
import 'package:porcitech_mobile/src/features/sync/data/datasources/sync_remote_datasource.dart';
import 'package:porcitech_mobile/src/features/sync/domain/entities/sync_item_entity.dart';
import 'package:porcitech_mobile/src/features/sync/domain/repositories/sync_repository.dart';

class SyncRepositoryImpl implements SyncRepository {
  final SyncRemoteDataSource remoteDataSource;
  final LocalCacheService cacheService;

  SyncRepositoryImpl({
    required this.remoteDataSource,
    required this.cacheService,
  });

  @override
  List<SyncItemEntity> getPendingQueue() {
    final raw = cacheService.getOfflineQueue();
    return raw.map((item) {
      return SyncItemEntity(
        id: item['id']?.toString() ?? '',
        endpoint: item['endpoint']?.toString() ?? '',
        method: item['method']?.toString() ?? 'POST',
        payload: (item['payload'] is Map<String, dynamic>)
            ? item['payload'] as Map<String, dynamic>
            : {},
        description: item['description']?.toString() ?? 'Transacción en corral',
        createdAt: DateTime.tryParse(item['createdAt']?.toString() ?? '') ?? DateTime.now(),
      );
    }).toList();
  }

  @override
  Future<Either<Failure, int>> syncOfflineQueue() async {
    final items = cacheService.getOfflineQueue();
    if (items.isEmpty) return const Right(0);

    int totalProcessed = 0;
    AppException? lastError;

    for (final item in items) {
      try {
        final count = await remoteDataSource.sendOfflineQueue([item]);
        totalProcessed += count;
        final itemId = item['id']?.toString();
        if (itemId != null && itemId.isNotEmpty) {
          await cacheService.removeSyncItem(itemId);
        }
      } on AppException catch (e) {
        lastError = e;
      } catch (e) {
        lastError = ServerException(e.toString());
      }
    }

    if (totalProcessed == 0 && lastError != null) {
      return Left(ServerFailure(lastError.message));
    }
    return Right(totalProcessed);
  }

  @override
  Future<Either<Failure, void>> clearQueue() async {
    try {
      await cacheService.clearOfflineQueue();
      return const Right(null);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getUserProfile() async {
    try {
      final profile = await remoteDataSource.getUserProfile();
      return Right(profile);
    } on AppException {
      return const Right({
        'username': 'santiago_operario',
        'email': 'santiago@porcitech.agro',
        'role': 'Zootecnista de Campo',
        'granja': 'Granja San Jerónimo (Galpón 4)',
      });
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
