import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/sync_item_entity.dart';

abstract class SyncRepository {
  List<SyncItemEntity> getPendingQueue();
  Future<Either<Failure, int>> syncOfflineQueue();
  Future<Either<Failure, void>> clearQueue();
  Future<Either<Failure, Map<String, dynamic>>> getUserProfile();
}
