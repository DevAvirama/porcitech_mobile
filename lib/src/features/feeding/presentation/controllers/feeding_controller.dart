import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:porcitech_mobile/src/core/di/core_providers.dart';
import 'package:porcitech_mobile/src/features/feeding/data/datasources/feeding_remote_datasource.dart';
import 'package:porcitech_mobile/src/features/feeding/data/repositories/feeding_repository_impl.dart';
import 'package:porcitech_mobile/src/features/feeding/domain/entities/feeding_entity.dart';
import 'package:porcitech_mobile/src/features/feeding/domain/repositories/feeding_repository.dart';

final feedingRemoteDataSourceProvider =
    Provider<FeedingRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return FeedingRemoteDataSourceImpl(dioClient);
});

final feedingRepositoryProvider = Provider<FeedingRepository>((ref) {
  final remoteDataSource = ref.watch(feedingRemoteDataSourceProvider);
  final cacheService = ref.watch(localCacheServiceProvider);
  return FeedingRepositoryImpl(
    remoteDataSource: remoteDataSource,
    cacheService: cacheService,
  );
});

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

  FeedingRepository get _repository => ref.read(feedingRepositoryProvider);

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final racRes = await _repository.getRaciones(limite: 40);
    final invRes = await _repository.getInventarioItems();

    state = state.copyWith(
      isLoading: false,
      raciones: racRes.getOrElse((_) => const []),
      insumos: invRes.getOrElse((_) => const []),
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

    final result = await _repository.registrarRacion(
      corralUuid: corralUuid,
      corralCodigo: corralCodigo,
      alimentoItemId: alimentoItemId,
      alimentoNombre: alimentoNombre,
      faseAlimentacion: faseAlimentacion,
      cantidadKg: cantidadKg,
      observaciones: observaciones,
    );

    return await result.fold(
      (failure) async {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (nuevaRacion) async {
        state = state.copyWith(
          isLoading: false,
          raciones: [nuevaRacion, ...state.raciones],
        );
        await loadData();
        return true;
      },
    );
  }
}

final feedingNotifierProvider =
    NotifierProvider<FeedingNotifier, FeedingState>(FeedingNotifier.new);
