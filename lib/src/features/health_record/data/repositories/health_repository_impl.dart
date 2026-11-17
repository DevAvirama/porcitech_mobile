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
      if (resolvedAnimalUuid == null) '_local_animal_id': porcinoId,
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
    } on AppException catch (e) {
      if (e.statusCode != null && e.statusCode! >= 400 && e.statusCode! < 500) {
        return Left(ServerFailure(e.message, e.statusCode));
      }
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
      return Right(_getCachedWithdrawals());
    }
    try {
      final list = await remoteDataSource.getAlertasRetiro();
      if (list.isNotEmpty) {
        final raw = list
            .map(
              (a) => {
                'animal_id': a.animalUuid,
                'animal_arete': a.animalArete,
                'corral_codigo': a.corralCodigo,
                'producto_nombre': a.productoNombre,
                'fecha_tratamiento': a.fechaTratamiento.toIso8601String(),
                'tiempo_retiro_dias': a.tiempoRetiroDias,
                'fecha_fin_retiro': a.fechaFinRetiro.toIso8601String(),
                'dias_restantes': a.diasRestantes,
              },
            )
            .toList();
        await cacheService.cacheJson(cacheService.keyCachedWithdrawals, raw);
      }
      return Right(list);
    } catch (e) {
      return Right(_getCachedWithdrawals());
    }
  }

  List<WithdrawalAlertItem> _getCachedWithdrawals() {
    final cached = cacheService.getCachedJson(cacheService.keyCachedWithdrawals);
    if (cached is List && cached.isNotEmpty) {
      return cached.whereType<Map<String, dynamic>>().map((m) {
        final fechaTrat =
            DateTime.tryParse(m['fecha_tratamiento']?.toString() ?? '') ??
                DateTime.now();
        final fechaFin =
            DateTime.tryParse(m['fecha_fin_retiro']?.toString() ?? '') ??
                DateTime.now();
        final remaining = fechaFin.difference(DateTime.now()).inDays;
        return WithdrawalAlertItem(
          animalUuid: m['animal_id']?.toString() ?? '',
          animalArete: m['animal_arete']?.toString() ?? 'POR',
          corralCodigo: m['corral_codigo']?.toString(),
          productoNombre: m['producto_nombre']?.toString() ?? '',
          fechaTratamiento: fechaTrat,
          tiempoRetiroDias: (m['tiempo_retiro_dias'] as num?)?.toInt() ?? 0,
          fechaFinRetiro: fechaFin,
          diasRestantes: remaining >= 0
              ? remaining
              : ((m['dias_restantes'] as num?)?.toInt() ?? 0),
        );
      }).toList();
    }
    return const [];
  }

  @override
  Future<Either<Failure, List<BiosecurityProtocolItem>>> getProtocolosBioseguridad() async {
    if (cacheService.isOfflineModeEnabled()) {
      return Right(_getCachedOrSeedProtocolos());
    }
    try {
      final list = await remoteDataSource.getProtocolosBioseguridad();
      if (list.isNotEmpty) {
        final raw = list
            .map(
              (p) => {
                'id': p.id,
                'codigo': p.codigo,
                'tipo_protocolo': p.tipoProtocolo,
                'tarea': p.tarea,
                'descripcion': p.descripcion,
                'frecuencia': p.frecuencia,
                'cumplido_hoy': p.cumplidoHoy,
                'observaciones_hoy': p.observacionesHoy,
              },
            )
            .toList();
        await cacheService.cacheJson(cacheService.keyCachedProtocols, raw);
        return Right(list);
      }
      return Right(_getCachedOrSeedProtocolos());
    } catch (e) {
      return Right(_getCachedOrSeedProtocolos());
    }
  }

  List<BiosecurityProtocolItem> _getCachedOrSeedProtocolos() {
    final cached = cacheService.getCachedJson(cacheService.keyCachedProtocols);
    if (cached is List && cached.isNotEmpty) {
      return cached
          .whereType<Map<String, dynamic>>()
          .map(
            (p) => BiosecurityProtocolItem(
              id: p['id']?.toString() ?? '',
              codigo: p['codigo']?.toString() ?? 'BIO',
              tipoProtocolo: p['tipo_protocolo']?.toString() ?? 'operacional',
              tarea: p['tarea']?.toString() ?? '',
              descripcion: p['descripcion']?.toString() ?? '',
              frecuencia: p['frecuencia']?.toString() ?? 'Diaria',
              cumplidoHoy: p['cumplido_hoy'] == true,
              observacionesHoy: p['observaciones_hoy']?.toString(),
            ),
          )
          .toList();
    }
    return _seedProtocolos();
  }

  Future<void> _updateCachedProtocolStatus(String protocoloId, bool cumplido) async {
    final cached = cacheService.getCachedJson(cacheService.keyCachedProtocols);
    if (cached is List && cached.isNotEmpty) {
      final updated = cached.whereType<Map<String, dynamic>>().map((p) {
        if (p['id']?.toString() == protocoloId) {
          final copy = Map<String, dynamic>.from(p);
          copy['cumplido_hoy'] = cumplido;
          return copy;
        }
        return p;
      }).toList();
      await cacheService.cacheJson(cacheService.keyCachedProtocols, updated);
    }
  }

  @override
  Future<Either<Failure, bool>> toggleProtocoloBioseguridad({
    required String protocoloId,
    required bool cumplido,
    String? corralId,
    String? observaciones,
  }) async {
    final payload = <String, dynamic>{
      'protocolo_id': protocoloId,
      if (corralId != null && corralId.trim().isNotEmpty)
        'corral_id': corralId.trim(),
      'cumplido': cumplido,
      if (observaciones != null && observaciones.trim().isNotEmpty)
        'observaciones': observaciones.trim(),
    };

    await _updateCachedProtocolStatus(protocoloId, cumplido);

    if (cacheService.isOfflineModeEnabled()) {
      await cacheService.enqueueSyncItem(
        endpoint: ApiConstants.bioseguridadEjecuciones,
        method: 'POST',
        payload: payload,
        description: 'Bioseguridad protocolo ${cumplido ? "cumplido" : "pendiente"}',
      );
      return const Right(true);
    }

    try {
      final ok = await remoteDataSource.toggleProtocoloBioseguridad(
        protocoloId: protocoloId,
        cumplido: cumplido,
        corralId: corralId,
        observaciones: observaciones,
      );
      return Right(ok);
    } catch (e) {
      await cacheService.enqueueSyncItem(
        endpoint: ApiConstants.bioseguridadEjecuciones,
        method: 'POST',
        payload: payload,
        description: 'Bioseguridad protocolo ${cumplido ? "cumplido" : "pendiente"}',
      );
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
