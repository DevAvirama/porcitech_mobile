import 'package:fpdart/fpdart.dart';
import 'package:porcitech_mobile/src/core/constants/api_constants.dart';
import 'package:porcitech_mobile/src/core/errors/exceptions.dart';
import 'package:porcitech_mobile/src/core/errors/failures.dart';
import 'package:porcitech_mobile/src/core/storage/local_cache_service.dart';
import 'package:porcitech_mobile/src/features/animals/data/models/porcino_model.dart';
import 'package:porcitech_mobile/src/features/reproduction/data/datasources/reproduction_remote_datasource.dart';
import 'package:porcitech_mobile/src/features/reproduction/domain/entities/reproduction_event_entity.dart';
import 'package:porcitech_mobile/src/features/reproduction/domain/repositories/reproduction_repository.dart';

class ReproductionRepositoryImpl implements ReproductionRepository {
  final ReproductionRemoteDataSource remoteDataSource;
  final LocalCacheService cacheService;

  ReproductionRepositoryImpl({
    required this.remoteDataSource,
    required this.cacheService,
  });

  @override
  Future<Either<Failure, ReproductionEventEntity>> registrarParto({
    required int porcinoId,
    required DateTime fecha,
    required int nacidosVivos,
    required int nacidosMuertos,
    required int momias,
    required double pesoTotalCamadaKg,
    int numeroParto = 1,
    String? observaciones,
  }) async {
    final localEntity = ReproductionEventEntity(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      porcinoId: porcinoId,
      fecha: fecha,
      nacidosVivos: nacidosVivos,
      nacidosMuertos: nacidosMuertos,
      momias: momias,
      pesoTotalCamadaKg: pesoTotalCamadaKg,
      numeroParto: numeroParto,
      observaciones: observaciones,
    );

    final resolvedHembraUuid = PorcinoModel.resolveUuid(porcinoId);
    final resolvedCorralUuid = PorcinoModel.resolveCorralUuid(porcinoId);
    final offlinePayload = <String, dynamic>{
      if (resolvedHembraUuid != null) 'hembra_id': resolvedHembraUuid,
      if (resolvedCorralUuid != null) 'corral_maternidad_id': resolvedCorralUuid,
      'porcino': porcinoId,
      'fecha_parto': fecha.toIso8601String(),
      'nacidos_vivos': nacidosVivos,
      'nacidos_muertos': nacidosMuertos,
      'momias': momias,
      'peso_promedio_nacimiento_kg':
          nacidosVivos > 0 ? (pesoTotalCamadaKg / nacidosVivos) : 1.3,
      'observaciones': observaciones ?? 'Parto #$numeroParto registrado en campo',
    };

    if (cacheService.isOfflineModeEnabled()) {
      await cacheService.enqueueSyncItem(
        endpoint: ApiConstants.partos,
        method: 'POST',
        payload: offlinePayload,
        description: 'Parto cerda #$porcinoId: $nacidosVivos vivos, $nacidosMuertos muertos',
      );
      return Right(localEntity);
    }

    try {
      final remote = await remoteDataSource.registrarParto(
        porcinoId: porcinoId,
        fecha: fecha,
        nacidosVivos: nacidosVivos,
        nacidosMuertos: nacidosMuertos,
        momias: momias,
        pesoTotalCamadaKg: pesoTotalCamadaKg,
        numeroParto: numeroParto,
        observaciones: observaciones,
      );
      return Right(remote);
    } on AppException {
      await cacheService.enqueueSyncItem(
        endpoint: ApiConstants.partos,
        method: 'POST',
        payload: offlinePayload,
        description: 'Parto cerda #$porcinoId: $nacidosVivos vivos, $nacidosMuertos muertos',
      );
      return Right(localEntity);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
