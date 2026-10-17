import 'package:fpdart/fpdart.dart';
import 'package:porcitech_mobile/src/core/constants/api_constants.dart';
import 'package:porcitech_mobile/src/core/errors/exceptions.dart';
import 'package:porcitech_mobile/src/core/errors/failures.dart';
import 'package:porcitech_mobile/src/core/storage/local_cache_service.dart';
import 'package:porcitech_mobile/src/features/animals/data/models/porcino_model.dart';
import 'package:porcitech_mobile/src/features/health_record/data/datasources/health_remote_datasource.dart';
import 'package:porcitech_mobile/src/features/health_record/domain/entities/health_event_entity.dart';
import 'package:porcitech_mobile/src/features/health_record/domain/repositories/health_repository.dart';

class HealthRepositoryImpl implements HealthRepository {
  final HealthRemoteDataSource remoteDataSource;
  final LocalCacheService cacheService;

  HealthRepositoryImpl({
    required this.remoteDataSource,
    required this.cacheService,
  });

  @override
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
  }) async {
    final fechaFin = fecha.add(Duration(days: diasRetiro));
    final localEntity = HealthEventEntity(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      porcinoId: porcinoId,
      tipo: tipo,
      medicamento: medicamento,
      loteBiologico: loteBiologico,
      dosisMl: dosisMl,
      viaAplicacion: viaAplicacion,
      fecha: fecha,
      diasRetiro: diasRetiro,
      fechaFinRetiro: fechaFin,
      observaciones: observaciones,
    );

    final resolvedAnimalUuid = PorcinoModel.resolveUuid(porcinoId);
    final resolvedCorralUuid = PorcinoModel.resolveCorralUuid(porcinoId);
    final tipoLower = tipo.toLowerCase();
    final tipoEvento = tipoLower.contains('vacun')
        ? 'vacunacion'
        : tipoLower.contains('despara')
            ? 'desparasitacion'
            : 'medicacion';

    final offlinePayload = <String, dynamic>{
      if (resolvedAnimalUuid != null) 'animal_id': resolvedAnimalUuid,
      if (resolvedCorralUuid != null) 'corral_id': resolvedCorralUuid,
      'porcino': porcinoId,
      'tipo_evento': tipoEvento,
      'producto_nombre': medicamento,
      'lote_producto': loteBiologico,
      'dosis_aplicada': '$dosisMl ml',
      'via_administracion': viaAplicacion.toLowerCase(),
      'fecha_tratamiento': fecha.toIso8601String(),
      'tiempo_retiro_dias': diasRetiro,
      if (observaciones != null && observaciones.isNotEmpty)
        'motivo_diagnostico': observaciones,
    };

    if (cacheService.isOfflineModeEnabled()) {
      await cacheService.enqueueSyncItem(
        endpoint: ApiConstants.eventosSanitarios,
        method: 'POST',
        payload: offlinePayload,
        description: 'Sanidad #$porcinoId: $medicamento ($dosisMl ml)',
      );
      return Right(localEntity);
    }

    try {
      final remote = await remoteDataSource.registrarEventoSanitario(
        porcinoId: porcinoId,
        tipo: tipo,
        medicamento: medicamento,
        loteBiologico: loteBiologico,
        dosisMl: dosisMl,
        viaAplicacion: viaAplicacion,
        fecha: fecha,
        diasRetiro: diasRetiro,
        observaciones: observaciones,
      );
      return Right(remote);
    } on AppException {
      await cacheService.enqueueSyncItem(
        endpoint: ApiConstants.eventosSanitarios,
        method: 'POST',
        payload: offlinePayload,
        description: 'Sanidad #$porcinoId: $medicamento ($dosisMl ml)',
      );
      return Right(localEntity);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
