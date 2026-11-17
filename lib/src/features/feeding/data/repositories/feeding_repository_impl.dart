import 'package:fpdart/fpdart.dart';
import 'package:porcitech_mobile/src/core/constants/api_constants.dart';
import 'package:porcitech_mobile/src/core/errors/exceptions.dart';
import 'package:porcitech_mobile/src/core/errors/failures.dart';
import 'package:porcitech_mobile/src/core/storage/local_cache_service.dart';
import 'package:porcitech_mobile/src/features/feeding/data/datasources/feeding_remote_datasource.dart';
import 'package:porcitech_mobile/src/features/feeding/domain/entities/feeding_entity.dart';
import 'package:porcitech_mobile/src/features/feeding/domain/repositories/feeding_repository.dart';

class FeedingRepositoryImpl implements FeedingRepository {
  final FeedingRemoteDataSource remoteDataSource;
  final LocalCacheService cacheService;

  FeedingRepositoryImpl({
    required this.remoteDataSource,
    required this.cacheService,
  });

  List<InventoryItemEntity> _parseInventoryList(dynamic rawList) {
    if (rawList is! List) return const [];
    return rawList
        .whereType<Map<String, dynamic>>()
        .map(
          (m) => InventoryItemEntity(
            id: m['id']?.toString() ?? '',
            categoriaCodigo: m['categoria_codigo']?.toString() ?? 'INS',
            categoriaNombre: m['categoria_nombre']?.toString() ?? 'Insumo',
            codigoSku: m['codigo_sku']?.toString() ?? 'SKU-01',
            nombre: m['nombre']?.toString() ?? 'Insumo',
            unidadMedida: m['unidad_medida']?.toString() ?? 'kg',
            stockActual: (m['stock_actual'] as num?)?.toDouble() ?? 0.0,
            stockMinimo: (m['stock_minimo'] as num?)?.toDouble() ?? 0.0,
            costoUnitario: (m['costo_unitario'] as num?)?.toDouble() ?? 0.0,
            ubicacionBodega:
                m['ubicacion_bodega']?.toString() ?? 'Bodega Principal',
          ),
        )
        .toList();
  }

  @override
  Future<Either<Failure, List<FeedingRationEntity>>> getRaciones({
    int limite = 40,
  }) async {
    if (cacheService.isOfflineModeEnabled()) {
      return const Right([]);
    }
    try {
      final list = await remoteDataSource.getRaciones(limite: limite);
      return Right(list);
    } on AppException {
      return const Right([]);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<InventoryItemEntity>>> getInventarioItems() async {
    if (!cacheService.isOfflineModeEnabled()) {
      try {
        final raw = await remoteDataSource.getRawInventarioItems();
        if (raw.isNotEmpty) {
          await cacheService.cacheJson(cacheService.keyCachedInventory, raw);
          return Right(_parseInventoryList(raw));
        }
      } on AppException {
        // Fallback a caché local abajo
      } catch (_) {}
    }

    final cachedInv = cacheService.getCachedJson(cacheService.keyCachedInventory);
    return Right(_parseInventoryList(cachedInv));
  }

  @override
  Future<Either<Failure, FeedingRationEntity>> registrarRacion({
    required String corralUuid,
    required String corralCodigo,
    required String alimentoItemId,
    required String alimentoNombre,
    required String faseAlimentacion,
    required double cantidadKg,
    String? observaciones,
  }) async {
    final payload = <String, dynamic>{
      'corral_id': corralUuid,
      'alimento_item_id': alimentoItemId,
      'fase_alimentacion': faseAlimentacion,
      'cantidad_kg': cantidadKg,
      if (observaciones != null && observaciones.trim().isNotEmpty)
        'observaciones': observaciones.trim(),
    };

    final nuevaRacion = FeedingRationEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      corralUuid: corralUuid,
      corralCodigo: corralCodigo,
      alimentoItemId: alimentoItemId,
      alimentoNombre: alimentoNombre,
      faseAlimentacion: faseAlimentacion,
      cantidadKg: cantidadKg,
      fechaSuministro: DateTime.now(),
      observaciones: observaciones,
    );

    if (cacheService.isOfflineModeEnabled()) {
      await cacheService.enqueueSyncItem(
        endpoint: ApiConstants.raciones,
        method: 'POST',
        payload: payload,
        description: 'Ración $corralCodigo: $cantidadKg kg ($alimentoNombre)',
      );
      return Right(nuevaRacion);
    }

    try {
      await remoteDataSource.registrarRacion(payload);
      return Right(nuevaRacion);
    } on AppException catch (e) {
      if (e.statusCode != null && e.statusCode! >= 400 && e.statusCode! < 500) {
        return Left(ServerFailure(e.message, e.statusCode));
      }
      await cacheService.enqueueSyncItem(
        endpoint: ApiConstants.raciones,
        method: 'POST',
        payload: payload,
        description: 'Ración $corralCodigo: $cantidadKg kg ($alimentoNombre)',
      );
      return Right(nuevaRacion);
    } catch (_) {
      await cacheService.enqueueSyncItem(
        endpoint: ApiConstants.raciones,
        method: 'POST',
        payload: payload,
        description: 'Ración $corralCodigo: $cantidadKg kg ($alimentoNombre)',
      );
      return Right(nuevaRacion);
    }
  }
}
