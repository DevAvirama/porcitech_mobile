import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/health_event_entity.dart';

abstract class HealthRepository {
  Future<Either<Failure, HealthEventEntity>> registrarEventoSanitario({
    required int porcinoId,
    String? animalUuid,
    String? corralUuid,
    String? medicamentoUuid,
    required String tipo,
    required String medicamento,
    required String loteBiologico,
    required double dosisMl,
    String unidadDosis = 'ml',
    required String viaAplicacion,
    required DateTime fecha,
    required int diasRetiro,
    String? diagnostico,
    String? observaciones,
  });

  Future<Either<Failure, List<HealthEventEntity>>> getTratamientos({String? animalUuid});
  Future<Either<Failure, List<WithdrawalAlertItem>>> getAlertasRetiro();
  Future<Either<Failure, List<BiosecurityProtocolItem>>> getProtocolosBioseguridad();
  Future<Either<Failure, bool>> toggleProtocoloBioseguridad({
    required String protocoloId,
    required bool cumplido,
    String? observaciones,
  });
}
