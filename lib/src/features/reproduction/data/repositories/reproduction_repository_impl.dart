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
  Future<Either<Failure, List<ReproductionServiceEntity>>> getServicios() async {
    if (cacheService.isOfflineModeEnabled()) {
      return const Right([]);
    }
    try {
      final list = await remoteDataSource.getServicios();
      return Right(list);
    } catch (_) {
      return const Right([]);
    }
  }

  @override
  Future<Either<Failure, ReproductionServiceEntity>> registrarServicio({
    required int porcinoId,
    String? hembraUuid,
    required String hembraArete,
    required String tipoServicio,
    String? codigoPajilla,
    required DateTime fechaServicio,
    String? observaciones,
  }) async {
    final resolvedHembraUuid = hembraUuid ?? PorcinoModel.resolveUuid(porcinoId);
    final localEntity = ReproductionServiceEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      hembraUuid: resolvedHembraUuid ?? '',
      hembraArete: hembraArete,
      tipoServicio: tipoServicio,
      codigoPajillaMacho: codigoPajilla,
      fechaServicio: fechaServicio,
      fechaProbableParto: fechaServicio.add(const Duration(days: 114)),
      estadoConfirmacion: 'pendiente',
      observaciones: observaciones,
    );

    final offlinePayload = <String, dynamic>{
      'hembra_id': ?resolvedHembraUuid,
      'tipo_servicio': tipoServicio,
      if (codigoPajilla != null && codigoPajilla.trim().isNotEmpty)
        'codigo_pajilla_macho': codigoPajilla.trim(),
      'fecha_servicio': fechaServicio.toIso8601String().split('T').first,
      'estado_confirmacion': 'pendiente',
      if (observaciones != null && observaciones.trim().isNotEmpty)
        'observaciones': observaciones.trim(),
    };

    if (cacheService.isOfflineModeEnabled()) {
      await cacheService.enqueueSyncItem(
        endpoint: ApiConstants.eventosReproductivos,
        method: 'POST',
        payload: offlinePayload,
        description: 'Servicio reproductivo cerda $hembraArete ($tipoServicio)',
      );
      return Right(localEntity);
    }

    try {
      final remote = await remoteDataSource.registrarServicio(
        porcinoId: porcinoId,
        hembraUuid: resolvedHembraUuid,
        hembraArete: hembraArete,
        tipoServicio: tipoServicio,
        codigoPajilla: codigoPajilla,
        fechaServicio: fechaServicio,
        observaciones: observaciones,
      );
      return Right(remote);
    } on AppException {
      await cacheService.enqueueSyncItem(
        endpoint: ApiConstants.eventosReproductivos,
        method: 'POST',
        payload: offlinePayload,
        description: 'Servicio reproductivo cerda $hembraArete ($tipoServicio)',
      );
      return Right(localEntity);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> actualizarDiagnosticoServicio({
    required String servicioId,
    required String estadoConfirmacion,
    String? observaciones,
  }) async {
    try {
      final ok = await remoteDataSource.actualizarDiagnosticoServicio(
        servicioId: servicioId,
        estadoConfirmacion: estadoConfirmacion,
        observaciones: observaciones,
      );
      return Right(ok);
    } catch (_) {
      return const Right(false);
    }
  }

  @override
  Future<Either<Failure, List<ReproductionEventEntity>>> getPartos() async {
    if (cacheService.isOfflineModeEnabled()) {
      return const Right([]);
    }
    try {
      final list = await remoteDataSource.getPartos();
      return Right(list);
    } catch (_) {
      return const Right([]);
    }
  }

  @override
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
  }) async {
    final resolvedHembraUuid = hembraUuid ?? PorcinoModel.resolveUuid(porcinoId);
    final resolvedCorralUuid =
        corralMaternidadUuid ?? PorcinoModel.resolveCorralUuid(porcinoId);

    final localEntity = ReproductionEventEntity(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      porcinoId: porcinoId,
      hembraUuid: resolvedHembraUuid,
      fecha: fecha,
      nacidosVivos: nacidosVivos,
      nacidosMuertos: nacidosMuertos,
      momias: momias,
      pesoTotalCamadaKg: pesoTotalCamadaKg,
      numeroParto: numeroParto,
      observaciones: observaciones,
    );

    final offlinePayload = <String, dynamic>{
      'hembra_id': ?resolvedHembraUuid,
      'corral_maternidad_id': ?resolvedCorralUuid,
      'fecha_parto': fecha.toIso8601String(),
      'numero_parto': numeroParto,
      'nacidos_vivos': nacidosVivos,
      'nacidos_muertos': nacidosMuertos,
      'momias': momias,
      'peso_camada_total_kg': pesoTotalCamadaKg,
      if (observaciones != null && observaciones.trim().isNotEmpty)
        'observaciones': observaciones.trim(),
    };

    if (cacheService.isOfflineModeEnabled()) {
      await cacheService.enqueueSyncItem(
        endpoint: ApiConstants.partos,
        method: 'POST',
        payload: offlinePayload,
        description: 'Parto cerda #$porcinoId: $nacidosVivos vivos ($pesoTotalCamadaKg kg)',
      );
      return Right(localEntity);
    }

    try {
      final remote = await remoteDataSource.registrarParto(
        porcinoId: porcinoId,
        hembraUuid: resolvedHembraUuid,
        corralMaternidadUuid: resolvedCorralUuid,
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
        description: 'Parto cerda #$porcinoId: $nacidosVivos vivos ($pesoTotalCamadaKg kg)',
      );
      return Right(localEntity);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<WeaningEventEntity>>> getDestetes() async {
    if (cacheService.isOfflineModeEnabled()) {
      return const Right([]);
    }
    try {
      final list = await remoteDataSource.getDestetes();
      return Right(list);
    } catch (_) {
      return const Right([]);
    }
  }

  @override
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
  }) async {
    final resolvedHembraUuid = hembraUuid ?? PorcinoModel.resolveUuid(porcinoId);
    final localEntity = WeaningEventEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      hembraUuid: resolvedHembraUuid ?? '',
      hembraArete: hembraArete,
      fechaDestete: fechaDestete,
      lechonesDestetados: lechonesDestetados,
      pesoTotalKg: pesoTotalKg,
      diasLactancia: diasLactancia,
      observaciones: observaciones,
    );

    final offlinePayload = <String, dynamic>{
      'hembra_id': ?resolvedHembraUuid,
      'corral_destino_id': ?corralDestinoUuid,
      'fecha_destete': fechaDestete.toIso8601String().split('T').first,
      'lechones_destetados': lechonesDestetados,
      'peso_total_kg': pesoTotalKg,
      'dias_lactancia': diasLactancia,
      if (observaciones != null && observaciones.trim().isNotEmpty)
        'observaciones': observaciones.trim(),
    };

    if (cacheService.isOfflineModeEnabled()) {
      await cacheService.enqueueSyncItem(
        endpoint: ApiConstants.destetes,
        method: 'POST',
        payload: offlinePayload,
        description: 'Destete cerda $hembraArete: $lechonesDestetados lechones',
      );
      return Right(localEntity);
    }

    try {
      final remote = await remoteDataSource.registrarDestete(
        porcinoId: porcinoId,
        hembraUuid: resolvedHembraUuid,
        hembraArete: hembraArete,
        corralDestinoUuid: corralDestinoUuid,
        fechaDestete: fechaDestete,
        lechonesDestetados: lechonesDestetados,
        pesoTotalKg: pesoTotalKg,
        diasLactancia: diasLactancia,
        observaciones: observaciones,
      );
      return Right(remote);
    } on AppException {
      await cacheService.enqueueSyncItem(
        endpoint: ApiConstants.destetes,
        method: 'POST',
        payload: offlinePayload,
        description: 'Destete cerda $hembraArete: $lechonesDestetados lechones',
      );
      return Right(localEntity);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
