import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/reproduction_event_entity.dart';

abstract class ReproductionRepository {
  Future<Either<Failure, List<ReproductionServiceEntity>>> getServicios();
  Future<Either<Failure, ReproductionServiceEntity>> registrarServicio({
    required int porcinoId,
    String? hembraUuid,
    required String hembraArete,
    required String tipoServicio,
    String? codigoPajilla,
    required DateTime fechaServicio,
    String? observaciones,
  });
  Future<Either<Failure, bool>> actualizarDiagnosticoServicio({
    required String servicioId,
    required String estadoConfirmacion,
    String? observaciones,
  });

  Future<Either<Failure, List<ReproductionEventEntity>>> getPartos();
  Future<Either<Failure, ReproductionEventEntity>> registrarParto({
    required int porcinoId,
    String? hembraUuid,
    String? corralMaternidadUuid,
    required DateTime fecha,
    required int nacidosVivos,
    required int nacidosMuertos,
    required int momias,
    required double pesoTotalCamadaKg,
    int numeroParto = 1,
    String? observaciones,
  });

  Future<Either<Failure, List<WeaningEventEntity>>> getDestetes();
  Future<Either<Failure, WeaningEventEntity>> registrarDestete({
    required int porcinoId,
    String? hembraUuid,
    required String hembraArete,
    String? corralDestinoUuid,
    required DateTime fechaDestete,
    required int lechonesDestetados,
    required double pesoTotalKg,
    int diasLactancia = 21,
    String? observaciones,
  });
}
