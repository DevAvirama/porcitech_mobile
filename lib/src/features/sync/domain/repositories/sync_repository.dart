import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/sync_item_entity.dart';

abstract class SyncRepository {
  List<SyncItemEntity> getPendingQueue();
  Future<Either<Failure, int>> syncOfflineQueue();
  Future<Either<Failure, bool>> retrySingleItem(String id);
  Future<Either<Failure, void>> removeItem(String id);
  Future<Either<Failure, void>> clearSentItems();
  Future<Either<Failure, void>> clearQueue();
  Future<Either<Failure, Map<String, dynamic>>> getUserProfile();
  Future<Either<Failure, DateTime>> downloadOfflineCatalog();
  DateTime? getLastCatalogSyncAt();
}
