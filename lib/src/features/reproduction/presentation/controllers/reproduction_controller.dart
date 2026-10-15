import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:porcitech_mobile/src/core/di/core_providers.dart';
import 'package:porcitech_mobile/src/features/reproduction/data/datasources/reproduction_remote_datasource.dart';
import 'package:porcitech_mobile/src/features/reproduction/data/repositories/reproduction_repository_impl.dart';
import 'package:porcitech_mobile/src/features/reproduction/domain/entities/reproduction_event_entity.dart';
import 'package:porcitech_mobile/src/features/reproduction/domain/repositories/reproduction_repository.dart';

final reproductionRemoteDataSourceProvider =
    Provider<ReproductionRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ReproductionRemoteDataSourceImpl(dioClient);
});

final reproductionRepositoryProvider = Provider<ReproductionRepository>((ref) {
  final remote = ref.watch(reproductionRemoteDataSourceProvider);
  final cache = ref.watch(localCacheServiceProvider);
  return ReproductionRepositoryImpl(remoteDataSource: remote, cacheService: cache);
});

class ReproductionState {
  final bool isLoading;
  final ReproductionEventEntity? lastParto;
  final String? errorMessage;
  final bool isSuccess;

  const ReproductionState({
    this.isLoading = false,
    this.lastParto,
    this.errorMessage,
    this.isSuccess = false,
  });

  ReproductionState copyWith({
    bool? isLoading,
    ReproductionEventEntity? lastParto,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return ReproductionState(
      isLoading: isLoading ?? this.isLoading,
      lastParto: lastParto ?? this.lastParto,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class ReproductionNotifier extends Notifier<ReproductionState> {
  @override
  ReproductionState build() => const ReproductionState();

  ReproductionRepository get _repository => ref.read(reproductionRepositoryProvider);

  Future<bool> registrarParto({
    required int porcinoId,
    required DateTime fecha,
    required int nacidosVivos,
    required int nacidosMuertos,
    required int momias,
    required double pesoTotalCamadaKg,
    int numeroParto = 1,
    String? observaciones,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    final result = await _repository.registrarParto(
      porcinoId: porcinoId,
      fecha: fecha,
      nacidosVivos: nacidosVivos,
      nacidosMuertos: nacidosMuertos,
      momias: momias,
      pesoTotalCamadaKg: pesoTotalCamadaKg,
      numeroParto: numeroParto,
      observaciones: observaciones,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (parto) {
        state = state.copyWith(isLoading: false, lastParto: parto, isSuccess: true);
        return true;
      },
    );
  }
}

final reproductionNotifierProvider =
    NotifierProvider<ReproductionNotifier, ReproductionState>(ReproductionNotifier.new);
