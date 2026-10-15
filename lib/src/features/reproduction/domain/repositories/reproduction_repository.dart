import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/reproduction_event_entity.dart';

abstract class ReproductionRepository {
  Future<Either<Failure, ReproductionEventEntity>> registrarParto({
    required int porcinoId,
    required DateTime fecha,
    required int nacidosVivos,
    required int nacidosMuertos,
    required int momias,
    required double pesoTotalCamadaKg,
    int numeroParto = 1,
    String? observaciones,
  });
}
