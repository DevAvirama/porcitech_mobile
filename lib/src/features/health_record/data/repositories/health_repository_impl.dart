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
  }) async {
    final fechaFin = fecha.add(Duration(days: diasRetiro));
    final tipoEvento = HealthRemoteDataSourceImpl.normalizeTipoEvento(tipo);
    final resolvedAnimalUuid = animalUuid ?? PorcinoModel.resolveUuid(porcinoId);
    final resolvedCorralUuid = corralUuid ?? PorcinoModel.resolveCorralUuid(porcinoId);

    final localEntity = HealthEventEntity(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      porcinoId: porcinoId,
      animalUuid: resolvedAnimalUuid,
      tipo: tipoEvento,
      medicamento: medicamento,
      loteBiologico: loteBiologico,
      dosisMl: dosisMl,
      unidadDosis: unidadDosis,
      viaAplicacion: viaAplicacion,
      fecha: fecha,
      diasRetiro: diasRetiro,
      fechaFinRetiro: fechaFin,
      diagnostico: diagnostico,
      observaciones: observaciones,
    );

    final offlinePayload = <String, dynamic>{
      'animal_id': ?resolvedAnimalUuid,
      'corral_id': ?resolvedCorralUuid,
      'medicamento_id': ?medicamentoUuid,
      'tipo_evento': tipoEvento,
      'producto_nombre': medicamento,
      'lote_biologico': loteBiologico,
      'dosis': dosisMl,
      'unidad_dosis': unidadDosis,
      'via_administracion': viaAplicacion,
      'diagnostico': diagnostico != null && diagnostico.trim().isNotEmpty
          ? diagnostico.trim()
          : 'Aplicación de $medicamento (Lote $loteBiologico)',
      'fecha_tratamiento': fecha.toIso8601String(),
      'tiempo_retiro_dias': diasRetiro,
      if (observaciones != null && observaciones.trim().isNotEmpty)
        'observaciones': observaciones.trim(),
    };

    if (cacheService.isOfflineModeEnabled()) {
      await cacheService.enqueueSyncItem(
        endpoint: ApiConstants.eventosSanitarios,
        method: 'POST',
        payload: offlinePayload,
        description: 'Sanidad #$porcinoId: $medicamento ($dosisMl $unidadDosis)',
      );
      return Right(localEntity);
    }

    try {
      final remote = await remoteDataSource.registrarEventoSanitario(
        porcinoId: porcinoId,
        animalUuid: resolvedAnimalUuid,
        corralUuid: resolvedCorralUuid,
        medicamentoUuid: medicamentoUuid,
        tipo: tipoEvento,
        medicamento: medicamento,
        loteBiologico: loteBiologico,
        dosisMl: dosisMl,
        unidadDosis: unidadDosis,
        viaAplicacion: viaAplicacion,
        fecha: fecha,
        diasRetiro: diasRetiro,
        diagnostico: diagnostico,
        observaciones: observaciones,
      );
      return Right(remote);
    } on AppException {
      await cacheService.enqueueSyncItem(
        endpoint: ApiConstants.eventosSanitarios,
        method: 'POST',
        payload: offlinePayload,
        description: 'Sanidad #$porcinoId: $medicamento ($dosisMl $unidadDosis)',
      );
      return Right(localEntity);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<HealthEventEntity>>> getTratamientos({
    String? animalUuid,
  }) async {
    if (cacheService.isOfflineModeEnabled()) {
      return const Right([]);
    }
    try {
      final list = await remoteDataSource.getTratamientos(animalUuid: animalUuid);
      return Right(list);
    } catch (e) {
      return const Right([]);
    }
  }

  @override
  Future<Either<Failure, List<WithdrawalAlertItem>>> getAlertasRetiro() async {
    if (cacheService.isOfflineModeEnabled()) {
      return const Right([]);
    }
    try {
      final list = await remoteDataSource.getAlertasRetiro();
      return Right(list);
    } catch (e) {
      return const Right([]);
    }
  }

  @override
  Future<Either<Failure, List<BiosecurityProtocolItem>>> getProtocolosBioseguridad() async {
    if (cacheService.isOfflineModeEnabled()) {
      return Right(_seedProtocolos());
    }
    try {
      final list = await remoteDataSource.getProtocolosBioseguridad();
      if (list.isNotEmpty) return Right(list);
      return Right(_seedProtocolos());
    } catch (e) {
      return Right(_seedProtocolos());
    }
  }

  @override
  Future<Either<Failure, bool>> toggleProtocoloBioseguridad({
    required String protocoloId,
    required bool cumplido,
    String? observaciones,
  }) async {
    if (cacheService.isOfflineModeEnabled()) {
      await cacheService.enqueueSyncItem(
        endpoint: ApiConstants.bioseguridadEjecuciones,
        method: 'POST',
        payload: {
          'protocolo_id': protocoloId,
          'cumplido': cumplido,
          if (observaciones != null && observaciones.isNotEmpty)
            'observaciones': observaciones,
        },
        description: 'Bioseguridad protocolo ${cumplido ? "cumplido" : "pendiente"}',
      );
      return const Right(true);
    }

    try {
      final ok = await remoteDataSource.toggleProtocoloBioseguridad(
        protocoloId: protocoloId,
        cumplido: cumplido,
        observaciones: observaciones,
      );
      return Right(ok);
    } catch (e) {
      return const Right(true);
    }
  }

  List<BiosecurityProtocolItem> _seedProtocolos() {
    return const [
      BiosecurityProtocolItem(
        id: 'proto-01',
        codigo: 'BIO-01',
        tipoProtocolo: 'operacional',
        tarea: 'Recambio de solución desinfectante en pediluvios',
        descripcion: 'Verificar concentración de amonio cuaternario o yodo al ingreso de cada galpón.',
        frecuencia: 'Diaria',
      ),
      BiosecurityProtocolItem(
        id: 'proto-02',
        codigo: 'BIO-02',
        tipoProtocolo: 'estructural',
        tarea: 'Arco sanitario y desinfección de vehículos',
        descripcion: 'Aspersión completa de camiones de alimento e insumos en portería.',
        frecuencia: 'Por ingreso',
      ),
      BiosecurityProtocolItem(
        id: 'proto-03',
        codigo: 'BIO-03',
        tipoProtocolo: 'operacional',
        tarea: 'Ducha sanitaria y cambio de dotación',
        descripcion: 'Ingreso obligatorio con overol y botas exclusivas de la unidad porcina.',
        frecuencia: 'Diaria',
      ),
      BiosecurityProtocolItem(
        id: 'proto-04',
        codigo: 'BIO-04',
        tipoProtocolo: 'operacional',
        tarea: 'Control de vectores, aves y roedores',
        descripcion: 'Inspección de mallas pajareras y estaciones de cebado perimetral.',
        frecuencia: 'Semanal',
      ),
    ];
  }
}
