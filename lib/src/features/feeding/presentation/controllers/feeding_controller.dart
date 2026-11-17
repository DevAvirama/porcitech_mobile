import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:porcitech_mobile/src/core/constants/api_constants.dart';
import 'package:porcitech_mobile/src/core/di/core_providers.dart';
import 'package:porcitech_mobile/src/core/network/dio_client.dart';
import 'package:porcitech_mobile/src/core/storage/local_cache_service.dart';
import 'package:porcitech_mobile/src/features/feeding/domain/entities/feeding_entity.dart';

class FeedingState {
  final bool isLoading;
  final List<FeedingRationEntity> raciones;
  final List<InventoryItemEntity> insumos;
  final String? errorMessage;

  const FeedingState({
    this.isLoading = false,
    this.raciones = const [],
    this.insumos = const [],
    this.errorMessage,
  });

  List<InventoryItemEntity> get alimentos =>
      insumos.where((i) => i.esAlimento).isNotEmpty
          ? insumos.where((i) => i.esAlimento).toList()
          : insumos;

  FeedingState copyWith({
    bool? isLoading,
    List<FeedingRationEntity>? raciones,
    List<InventoryItemEntity>? insumos,
    String? errorMessage,
  }) {
    return FeedingState(
      isLoading: isLoading ?? this.isLoading,
      raciones: raciones ?? this.raciones,
      insumos: insumos ?? this.insumos,
      errorMessage: errorMessage,
    );
  }
}

class FeedingNotifier extends Notifier<FeedingState> {
  @override
  FeedingState build() {
    Future.microtask(() => loadData());
    return const FeedingState();
  }

  DioClient get _client => ref.read(dioClientProvider);
  LocalCacheService get _cache => ref.read(localCacheServiceProvider);

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    List<FeedingRationEntity> racionesList = [];
    List<InventoryItemEntity> insumosList = [];

    if (!_cache.isOfflineModeEnabled()) {
      try {
        final racRes = await _client.get(
          ApiConstants.raciones,
          queryParameters: const {'limite': 40},
        );
        if (racRes.data is List) {
          racionesList = (racRes.data as List)
              .whereType<Map<String, dynamic>>()
              .map(
                (m) => FeedingRationEntity(
                  id: m['id']?.toString() ?? '',
                  corralUuid: m['corral_id']?.toString() ?? '',
                  corralCodigo: m['corral_codigo']?.toString() ?? 'COR',
                  alimentoItemId: m['alimento_item_id']?.toString() ?? '',
                  alimentoNombre:
                      m['alimento_nombre']?.toString() ?? 'Concentrado',
                  faseAlimentacion:
                      m['fase_alimentacion']?.toString() ?? 'Ceba',
                  cantidadKg: (m['cantidad_kg'] as num?)?.toDouble() ?? 0.0,
                  costoTotal: (m['costo_total'] as num?)?.toDouble() ?? 0.0,
                  fechaSuministro:
                      DateTime.tryParse(m['fecha_suministro']?.toString() ?? '') ??
                          DateTime.now(),
                  operarioNombre: m['operario_nombre']?.toString(),
                  observaciones: m['observaciones']?.toString(),
                ),
              )
              .toList();
        }
      } catch (_) {}

      try {
        final invRes = await _client.get(ApiConstants.inventarioItems);
        if (invRes.data is List) {
          await _cache.cacheJson(_cache.keyCachedInventory, invRes.data);
          insumosList = (invRes.data as List)
              .whereType<Map<String, dynamic>>()
              .map(
                (m) => InventoryItemEntity(
                  id: m['id']?.toString() ?? '',
                  categoriaCodigo: m['categoria_codigo']?.toString() ?? 'INS',
                  categoriaNombre:
                      m['categoria_nombre']?.toString() ?? 'Insumo',
                  codigoSku: m['codigo_sku']?.toString() ?? 'SKU-01',
                  nombre: m['nombre']?.toString() ?? 'Insumo',
                  unidadMedida: m['unidad_medida']?.toString() ?? 'kg',
                  stockActual: (m['stock_actual'] as num?)?.toDouble() ?? 0.0,
                  stockMinimo: (m['stock_minimo'] as num?)?.toDouble() ?? 0.0,
                  costoUnitario:
                      (m['costo_unitario'] as num?)?.toDouble() ?? 0.0,
                  ubicacionBodega:
                      m['ubicacion_bodega']?.toString() ?? 'Bodega Principal',
                ),
              )
              .toList();
        }
      } catch (_) {}
    }

    if (insumosList.isEmpty) {
      final cachedInv = _cache.getCachedJson(_cache.keyCachedInventory);
      if (cachedInv is List && cachedInv.isNotEmpty) {
        insumosList = cachedInv
            .whereType<Map<String, dynamic>>()
            .map(
              (m) => InventoryItemEntity(
                id: m['id']?.toString() ?? '',
                categoriaCodigo: m['categoria_codigo']?.toString() ?? 'INS',
                categoriaNombre:
                    m['categoria_nombre']?.toString() ?? 'Insumo',
                codigoSku: m['codigo_sku']?.toString() ?? 'SKU-01',
                nombre: m['nombre']?.toString() ?? 'Insumo',
                unidadMedida: m['unidad_medida']?.toString() ?? 'kg',
                stockActual: (m['stock_actual'] as num?)?.toDouble() ?? 0.0,
                stockMinimo: (m['stock_minimo'] as num?)?.toDouble() ?? 0.0,
                costoUnitario:
                    (m['costo_unitario'] as num?)?.toDouble() ?? 0.0,
                ubicacionBodega:
                    m['ubicacion_bodega']?.toString() ?? 'Bodega Principal',
              ),
            )
            .toList();
      }
    }

    state = state.copyWith(
      isLoading: false,
      raciones: racionesList,
      insumos: insumosList,
    );
  }

  Future<bool> registrarRacion({
    required String corralUuid,
    required String corralCodigo,
    required String alimentoItemId,
    required String alimentoNombre,
    required String faseAlimentacion,
    required double cantidadKg,
    String? observaciones,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

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

    if (_cache.isOfflineModeEnabled()) {
      await _cache.enqueueSyncItem(
        endpoint: ApiConstants.raciones,
        method: 'POST',
        payload: payload,
        description: 'Ración $corralCodigo: $cantidadKg kg ($alimentoNombre)',
      );
      state = state.copyWith(
        isLoading: false,
        raciones: [nuevaRacion, ...state.raciones],
      );
      return true;
    }

    try {
      await _client.post(ApiConstants.raciones, data: payload);
      await loadData();
      return true;
    } on AppException catch (e) {
      if (e.statusCode != null && e.statusCode! >= 400 && e.statusCode! < 500) {
        state = state.copyWith(isLoading: false, errorMessage: e.message);
        return false;
      }
      await _cache.enqueueSyncItem(
        endpoint: ApiConstants.raciones,
        method: 'POST',
        payload: payload,
        description: 'Ración $corralCodigo: $cantidadKg kg ($alimentoNombre)',
      );
      state = state.copyWith(
        isLoading: false,
        raciones: [nuevaRacion, ...state.raciones],
      );
      return true;
    } catch (_) {
      await _cache.enqueueSyncItem(
        endpoint: ApiConstants.raciones,
        method: 'POST',
        payload: payload,
        description: 'Ración $corralCodigo: $cantidadKg kg ($alimentoNombre)',
      );
      state = state.copyWith(
        isLoading: false,
        raciones: [nuevaRacion, ...state.raciones],
      );
      return true;
    }
  }
}

final feedingNotifierProvider =
    NotifierProvider<FeedingNotifier, FeedingState>(FeedingNotifier.new);
