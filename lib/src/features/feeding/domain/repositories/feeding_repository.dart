import 'package:fpdart/fpdart.dart';
import 'package:porcitech_mobile/src/core/errors/failures.dart';
import 'package:porcitech_mobile/src/features/feeding/domain/entities/feeding_entity.dart';

abstract class FeedingRepository {
  Future<Either<Failure, List<FeedingRationEntity>>> getRaciones({int limite = 40});
  Future<Either<Failure, List<InventoryItemEntity>>> getInventarioItems();
  Future<Either<Failure, FeedingRationEntity>> registrarRacion({
    required String corralUuid,
    required String corralCodigo,
    required String alimentoItemId,
    required String alimentoNombre,
    required String faseAlimentacion,
    required double cantidadKg,
    String? observaciones,
  });
}
