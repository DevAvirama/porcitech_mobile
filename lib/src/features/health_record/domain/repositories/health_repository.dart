import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/health_event_entity.dart';

abstract class HealthRepository {
  Future<Either<Failure, HealthEventEntity>> registrarEventoSanitario({
    required int porcinoId,
    required String tipo,
    required String medicamento,
    required String loteBiologico,
    required double dosisMl,
    required String viaAplicacion,
    required DateTime fecha,
    required int diasRetiro,
    String? observaciones,
  });
}
