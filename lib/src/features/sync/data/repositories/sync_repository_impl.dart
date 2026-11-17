import 'package:fpdart/fpdart.dart';
import 'package:porcitech_mobile/src/core/errors/exceptions.dart';
import 'package:porcitech_mobile/src/core/errors/failures.dart';
import 'package:porcitech_mobile/src/core/storage/local_cache_service.dart';
import 'package:porcitech_mobile/src/features/animals/data/models/lote_model.dart';
import 'package:porcitech_mobile/src/features/animals/data/models/porcino_model.dart';
import 'package:porcitech_mobile/src/features/sync/data/datasources/sync_remote_datasource.dart';
import 'package:porcitech_mobile/src/features/sync/domain/entities/sync_item_entity.dart';
import 'package:porcitech_mobile/src/features/sync/domain/repositories/sync_repository.dart';

class SyncRepositoryImpl implements SyncRepository {
  final SyncRemoteDataSource remoteDataSource;
  final LocalCacheService cacheService;

  SyncRepositoryImpl({
    required this.remoteDataSource,
    required this.cacheService,
  });

  @override
  List<SyncItemEntity> getPendingQueue() {
    final raw = cacheService.getOfflineQueue();
    return raw.map((item) {
      final rawId = item['id']?.toString() ?? '';
      return SyncItemEntity(
        id: rawId,
        idLocal: item['idLocal']?.toString() ?? rawId,
        endpoint: item['endpoint']?.toString() ?? '',
        method: item['method']?.toString() ?? 'POST',
        payload: (item['payload'] is Map<String, dynamic>)
            ? item['payload'] as Map<String, dynamic>
            : {},
        description: item['description']?.toString() ?? 'Transacción en corral',
        status: SyncItemStatus.fromString(item['status']?.toString()),
        errorMessage: item['errorMessage']?.toString(),
        retryCount: (item['retryCount'] as num?)?.toInt() ?? 0,
        filePath: item['filePath']?.toString(),
        createdAt: DateTime.tryParse(item['createdAt']?.toString() ?? '') ?? DateTime.now(),
      );
    }).toList();
  }

  Map<String, dynamic> _resolvePendingRefs(
    Map<String, dynamic> item,
    Map<int, String> corralUuidMap,
    Map<int, String> animalUuidMap,
  ) {
    final payload = item['payload'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(item['payload'] as Map<String, dynamic>)
        : <String, dynamic>{};
    bool changed = false;

    final localCorralId = (payload['_local_corral_id'] as num?)?.toInt();
    if (localCorralId != null && corralUuidMap.containsKey(localCorralId)) {
      final uuid = corralUuidMap[localCorralId]!;
      payload.putIfAbsent('corral_id', () => uuid);
      if (item['endpoint'] == '/reproduccion/partos' && !payload.containsKey('corral_maternidad_id')) {
        payload['corral_maternidad_id'] = uuid;
      }
      if (item['endpoint'] == '/reproduccion/destetes' && !payload.containsKey('corral_destino_id')) {
        payload['corral_destino_id'] = uuid;
      }
      changed = true;
    }

    final localAnimalId = (payload['_local_animal_id'] as num?)?.toInt();
    if (localAnimalId != null && animalUuidMap.containsKey(localAnimalId)) {
      final uuid = animalUuidMap[localAnimalId]!;
      final ep = item['endpoint']?.toString() ?? '';
      if (ep.contains('/pesajes')) {
        payload.putIfAbsent('id_cerdo', () => uuid);
      } else if (ep.contains('/sanidad')) {
        payload.putIfAbsent('animal_id', () => uuid);
      } else if (ep.contains('/reproduccion')) {
        payload.putIfAbsent('hembra_id', () => uuid);
      }
      changed = true;
    }

    if (!changed) return item;
    return {...item, 'payload': payload};
  }

  void _hydrateUuidRegistriesFromCache() {
    final cachedLotes = cacheService.getCachedJson(cacheService.keyCachedLotes);
    if (cachedLotes is List) {
      for (final raw in cachedLotes.whereType<Map<String, dynamic>>()) {
        LoteModel.fromJson(raw);
      }
    }
    final cachedAnimals = cacheService.getCachedJson(cacheService.keyCachedAnimals);
    if (cachedAnimals is List) {
      for (final raw in cachedAnimals.whereType<Map<String, dynamic>>()) {
        PorcinoModel.fromJson(raw);
      }
    }
  }

  Future<void> _persistCreatedUuidInCache({
    int? localCorralId,
    int? localAnimalId,
    required String serverUuid,
    String? corralUuid,
  }) async {
    if (localCorralId != null) {
      final cachedLotes = cacheService.getCachedJson(cacheService.keyCachedLotes);
      if (cachedLotes is List) {
        final updated = cachedLotes.whereType<Map<String, dynamic>>().map((m) {
          if (LoteModel.parseNumericId(m['id']) == localCorralId) {
            return {...m, 'uuid': serverUuid};
          }
          return m;
        }).toList();
        await cacheService.cacheJson(cacheService.keyCachedLotes, updated);
      }
    }
    if (localAnimalId != null) {
      final cachedAnimals =
          cacheService.getCachedJson(cacheService.keyCachedAnimals);
      if (cachedAnimals is List) {
        final updated = cachedAnimals.whereType<Map<String, dynamic>>().map((m) {
          if (LoteModel.parseNumericId(m['id']) == localAnimalId) {
            return {
              ...m,
              'uuid': serverUuid,
              if (corralUuid != null && corralUuid.isNotEmpty)
                'corral_id': corralUuid,
            };
          }
          return m;
        }).toList();
        await cacheService.cacheJson(cacheService.keyCachedAnimals, updated);
      }
    }
  }

  Future<void> _captureCreatedUuids(
    Map<String, dynamic> item,
    dynamic responseData,
    Map<int, String> corralUuidMap,
    Map<int, String> animalUuidMap,
  ) async {
    if (responseData is! Map<String, dynamic>) return;
    final serverUuid = responseData['id']?.toString();
    if (serverUuid == null || serverUuid.isEmpty) return;
    final payload = item['payload'] is Map<String, dynamic>
        ? item['payload'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final endpoint = item['endpoint']?.toString() ?? '';

    if (endpoint.contains('/corrales')) {
      final localId = (payload['_local_corral_id'] as num?)?.toInt();
      if (localId != null) {
        corralUuidMap[localId] = serverUuid;
        LoteModel.registerUuid(localId, serverUuid);
        await _persistCreatedUuidInCache(
          localCorralId: localId,
          serverUuid: serverUuid,
        );
      }
    } else if (endpoint.contains('/animales')) {
      final localId = (payload['_local_animal_id'] as num?)?.toInt();
      if (localId != null) {
        final serverCorralUuid = responseData['corral_id']?.toString();
        animalUuidMap[localId] = serverUuid;
        PorcinoModel.registerUuids(
          id: localId,
          uuid: serverUuid,
          corralUuid: serverCorralUuid,
        );
        await _persistCreatedUuidInCache(
          localAnimalId: localId,
          serverUuid: serverUuid,
          corralUuid: serverCorralUuid,
        );
      }
    }
  }

  Future<bool> _dispatchSingleRawItem(
    Map<String, dynamic> item, {
    Map<int, String>? corralUuidMap,
    Map<int, String>? animalUuidMap,
  }) async {
    final itemId = item['id']?.toString() ?? '';
    final retries = (item['retryCount'] as num?)?.toInt() ?? 0;

    try {
      final respData = await remoteDataSource.sendSingleItem(item);
      if (corralUuidMap != null && animalUuidMap != null) {
        await _captureCreatedUuids(item, respData, corralUuidMap, animalUuidMap);
      }
      if (itemId.isNotEmpty) {
        await cacheService.updateSyncItem(
          itemId,
          status: 'enviado',
          clearError: true,
        );
      }
      return true;
    } on BadRequestException catch (e) {
      if (itemId.isNotEmpty) {
        await cacheService.updateSyncItem(
          itemId,
          status: 'conflicto',
          errorMessage: e.message,
          retryCount: retries + 1,
        );
      }
      return false;
    } on ForbiddenException catch (e) {
      if (itemId.isNotEmpty) {
        await cacheService.updateSyncItem(
          itemId,
          status: 'conflicto',
          errorMessage: e.message,
          retryCount: retries + 1,
        );
      }
      return false;
    } on NotFoundException catch (e) {
      if (itemId.isNotEmpty) {
        await cacheService.updateSyncItem(
          itemId,
          status: 'conflicto',
          errorMessage: e.message,
          retryCount: retries + 1,
        );
      }
      return false;
    } on AppException catch (e) {
      if (itemId.isNotEmpty) {
        await cacheService.updateSyncItem(
          itemId,
          status: 'error',
          errorMessage: e.message,
          retryCount: retries + 1,
        );
      }
      return false;
    } catch (e) {
      if (itemId.isNotEmpty) {
        await cacheService.updateSyncItem(
          itemId,
          status: 'error',
          errorMessage: e.toString(),
          retryCount: retries + 1,
        );
      }
      return false;
    }
  }

  @override
  Future<Either<Failure, int>> syncOfflineQueue() async {
    final items = cacheService.getOfflineQueue();
    final pendingFifo = items
        .where((item) => (item['status']?.toString() ?? 'pendiente') != 'enviado')
        .toList();
    if (pendingFifo.isEmpty) return const Right(0);

    _hydrateUuidRegistriesFromCache();
    final corralUuidMap = Map<int, String>.from(LoteModel.uuidRegistrySnapshot);
    final animalUuidMap = Map<int, String>.from(PorcinoModel.uuidRegistrySnapshot);
    int totalProcessed = 0;

    for (final rawItem in pendingFifo) {
      final resolvedItem = _resolvePendingRefs(rawItem, corralUuidMap, animalUuidMap);
      if (!identical(resolvedItem, rawItem)) {
        final itemId = resolvedItem['id']?.toString() ?? '';
        if (itemId.isNotEmpty) {
          await cacheService.updateSyncItem(
            itemId,
            payloadOverride: resolvedItem['payload'] as Map<String, dynamic>?,
          );
        }
      }
      final ok = await _dispatchSingleRawItem(
        resolvedItem,
        corralUuidMap: corralUuidMap,
        animalUuidMap: animalUuidMap,
      );
      if (ok) {
        totalProcessed++;
      }
    }

    if (totalProcessed == 0) {
      return const Left(
        ServerFailure(
          'No se pudieron enviar los registros pendientes. Revise errores o conflictos en la cola.',
        ),
      );
    }
    return Right(totalProcessed);
  }

  @override
  Future<Either<Failure, bool>> retrySingleItem(String id) async {
    final items = cacheService.getOfflineQueue();
    final match = items.cast<Map<String, dynamic>?>().firstWhere(
          (i) => i?['id']?.toString() == id,
          orElse: () => null,
        );
    if (match == null) {
      return const Left(NotFoundFailure('El evento ya no está en la cola local.'));
    }
    _hydrateUuidRegistriesFromCache();
    final corralUuidMap = Map<int, String>.from(LoteModel.uuidRegistrySnapshot);
    final animalUuidMap = Map<int, String>.from(PorcinoModel.uuidRegistrySnapshot);
    final resolvedMatch = _resolvePendingRefs(match, corralUuidMap, animalUuidMap);
    if (!identical(resolvedMatch, match)) {
      await cacheService.updateSyncItem(
        id,
        payloadOverride: resolvedMatch['payload'] as Map<String, dynamic>?,
      );
    }
    await cacheService.markSyncItemForRetry(id);
    final ok = await _dispatchSingleRawItem(
      resolvedMatch,
      corralUuidMap: corralUuidMap,
      animalUuidMap: animalUuidMap,
    );
    if (ok) return const Right(true);

    final updated = cacheService.getOfflineQueue().cast<Map<String, dynamic>?>().firstWhere(
          (i) => i?['id']?.toString() == id,
          orElse: () => null,
        );
    final msg = updated?['errorMessage']?.toString() ?? 'Error al reintentar el envío.';
    return Left(ServerFailure(msg));
  }

  @override
  Future<Either<Failure, void>> removeItem(String id) async {
    try {
      await cacheService.removeSyncItem(id);
      return const Right(null);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearSentItems() async {
    try {
      await cacheService.clearSentSyncItems();
      return const Right(null);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearQueue() async {
    try {
      await cacheService.clearOfflineQueue();
      return const Right(null);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DateTime>> downloadOfflineCatalog() async {
    try {
      final data = await remoteDataSource.downloadOfflineCatalog();

      // 1. Retiros activos por animal
      final Map<String, Map<String, dynamic>> withdrawalByAnimal = {};
      if (data['alertasRetiro'] is List) {
        final rawAlerts = (data['alertasRetiro'] as List)
            .whereType<Map<String, dynamic>>()
            .toList();
        await cacheService.cacheJson(cacheService.keyCachedWithdrawals, rawAlerts);
        for (final alert in rawAlerts) {
          final aid = alert['animal_id']?.toString();
          if (aid != null && aid.isNotEmpty) {
            withdrawalByAnimal[aid] = alert;
          }
        }
      }

      // 2. Animales enriquecidos con alertas de retiro para escaneo QR offline (HU06 + HU12)
      if (data['animales'] is List) {
        final models = (data['animales'] as List)
            .whereType<Map<String, dynamic>>()
            .map((raw) {
          final map = Map<String, dynamic>.from(raw);
          final aid = map['id']?.toString();
          if (aid != null && withdrawalByAnimal.containsKey(aid)) {
            final alert = withdrawalByAnimal[aid]!;
            map['estado_sanitario'] = 'Retiro Farmacológico';
            map['medicacion_activa'] = alert['producto_nombre']?.toString();
            map['dias_retiro'] = (alert['dias_restantes'] as num?)?.toInt() ?? 0;
            map['fecha_fin_retiro'] = alert['fecha_fin_retiro']?.toString();
          }
          return PorcinoModel.fromJson(map).toJson();
        }).toList();
        await cacheService.cacheJson(cacheService.keyCachedAnimals, models);
      }

      // 3. Corrales / Lotes
      if (data['corrales'] is List) {
        final lotes = (data['corrales'] as List)
            .whereType<Map<String, dynamic>>()
            .map((raw) => LoteModel.fromJson(raw).toJson())
            .toList();
        await cacheService.cacheJson(cacheService.keyCachedLotes, lotes);
      }

      // 4. Inventario de insumos y medicamentos
      if (data['inventario'] is List) {
        await cacheService.cacheJson(cacheService.keyCachedInventory, data['inventario']);
      }

      // 5. Protocolos de bioseguridad y ejecuciones del día (HU15)
      if (data['protocolos'] is List) {
        final execByProto = <String, Map<String, dynamic>>{};
        if (data['ejecuciones'] is List) {
          for (final ex in (data['ejecuciones'] as List).whereType<Map<String, dynamic>>()) {
            final pid = ex['protocolo_id']?.toString();
            if (pid != null) execByProto[pid] = ex;
          }
        }
        final enrichedProtocols = (data['protocolos'] as List)
            .whereType<Map<String, dynamic>>()
            .map((p) {
          final copy = Map<String, dynamic>.from(p);
          final exec = execByProto[copy['id']?.toString() ?? ''];
          copy['cumplido_hoy'] = exec != null && exec['cumplido'] == true;
          copy['observaciones_hoy'] = exec?['observaciones']?.toString();
          return copy;
        }).toList();
        await cacheService.cacheJson(cacheService.keyCachedProtocols, enrichedProtocols);
      }

      // 6. Servicios reproductivos / partos próximos (HU36)
      if (data['servicios'] is List) {
        await cacheService.cacheJson(cacheService.keyCachedServices, data['servicios']);
      }

      // 7. KPIs + Alertas del Dashboard (HU36)
      if (data['dashboardKpis'] is Map<String, dynamic>) {
        final kpiMap = Map<String, dynamic>.from(data['dashboardKpis'] as Map<String, dynamic>);
        if (data['dashboardAlerts'] is List) {
          kpiMap['alertas'] = data['dashboardAlerts'];
        }
        await cacheService.cacheJson(cacheService.keyCachedDashboard, kpiMap);
      }

      final now = DateTime.now();
      await cacheService.setLastCatalogSyncAt(now);
      return Right(now);
    } on AppException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  DateTime? getLastCatalogSyncAt() {
    return cacheService.getLastCatalogSyncAt();
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getUserProfile() async {
    try {
      final profile = await remoteDataSource.getUserProfile();
      return Right(profile);
    } on AppException catch (e) {
      // Sin red o sesión inválida: la UI usa el usuario autenticado en caché (authState.user).
      return Left(ServerFailure(e.message, e.statusCode));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
