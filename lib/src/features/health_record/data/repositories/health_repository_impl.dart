import 'package:fpdart/fpdart.dart';
import 'package:porcitech_mobile/src/core/errors/exceptions.dart';
import 'package:porcitech_mobile/src/core/errors/failures.dart';
import 'package:porcitech_mobile/src/core/storage/local_cache_service.dart';
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

    if (cacheService.isOfflineModeEnabled()) {
      await cacheService.enqueueSyncItem(
        endpoint: '/api/eventos-sanitarios/',
        method: 'POST',
        payload: {
          'porcino': porcinoId,
          'tipo': tipo,
          'medicamento': medicamento,
          'lote_biologico': loteBiologico,
          'dosis': dosisMl,
          'via_aplicacion': viaAplicacion,
          'fecha': fecha.toIso8601String().split('T').first,
          'dias_retiro': diasRetiro,
        },
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
        endpoint: '/api/eventos-sanitarios/',
        method: 'POST',
        payload: {
          'porcino': porcinoId,
          'tipo': tipo,
          'medicamento': medicamento,
          'lote_biologico': loteBiologico,
          'dosis': dosisMl,
          'via_aplicacion': viaAplicacion,
          'fecha': fecha.toIso8601String().split('T').first,
          'dias_retiro': diasRetiro,
        },
        description: 'Sanidad #$porcinoId: $medicamento ($dosisMl ml)',
      );
      return Right(localEntity);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
