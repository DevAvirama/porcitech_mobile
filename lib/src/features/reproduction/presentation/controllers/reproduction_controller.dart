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
  final List<ReproductionServiceEntity> servicios;
  final List<ReproductionEventEntity> partos;
  final List<WeaningEventEntity> destetes;
  final ReproductionEventEntity? lastParto;
  final String? errorMessage;
  final bool isSuccess;

  const ReproductionState({
    this.isLoading = false,
    this.servicios = const [],
    this.partos = const [],
    this.destetes = const [],
    this.lastParto,
    this.errorMessage,
    this.isSuccess = false,
  });

  ReproductionState copyWith({
    bool? isLoading,
    List<ReproductionServiceEntity>? servicios,
    List<ReproductionEventEntity>? partos,
    List<WeaningEventEntity>? destetes,
    ReproductionEventEntity? lastParto,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return ReproductionState(
      isLoading: isLoading ?? this.isLoading,
      servicios: servicios ?? this.servicios,
      partos: partos ?? this.partos,
      destetes: destetes ?? this.destetes,
      lastParto: lastParto ?? this.lastParto,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class ReproductionNotifier extends Notifier<ReproductionState> {
  @override
  ReproductionState build() {
    Future.microtask(() => loadReproduccionData());
    return const ReproductionState();
  }

  ReproductionRepository get _repository => ref.read(reproductionRepositoryProvider);

  Future<void> loadReproduccionData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final servRes = await _repository.getServicios();
    final partRes = await _repository.getPartos();
    final destRes = await _repository.getDestetes();

    state = state.copyWith(
      isLoading: false,
      servicios: servRes.getOrElse((_) => []),
      partos: partRes.getOrElse((_) => []),
      destetes: destRes.getOrElse((_) => []),
    );
  }

  Future<bool> registrarServicio({
    required int porcinoId,
    String? hembraUuid,
    required String hembraArete,
    required String tipoServicio,
    String? codigoPajilla,
    required DateTime fechaServicio,
    String? observaciones,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    final result = await _repository.registrarServicio(
      porcinoId: porcinoId,
      hembraUuid: hembraUuid,
      hembraArete: hembraArete,
      tipoServicio: tipoServicio,
      codigoPajilla: codigoPajilla,
      fechaServicio: fechaServicio,
      observaciones: observaciones,
    );
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (serv) {
        state = state.copyWith(
          isLoading: false,
          servicios: [serv, ...state.servicios],
          isSuccess: true,
        );
        return true;
      },
    );
  }

  Future<bool> actualizarDiagnostico({
    required String servicioId,
    required String estadoConfirmacion,
    String? observaciones,
  }) async {
    final result = await _repository.actualizarDiagnosticoServicio(
      servicioId: servicioId,
      estadoConfirmacion: estadoConfirmacion,
      observaciones: observaciones,
    );
    await loadReproduccionData();
    return result.getOrElse((_) => false);
  }

  Future<bool> registrarParto({
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
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    final result = await _repository.registrarParto(
      porcinoId: porcinoId,
      hembraUuid: hembraUuid,
      corralMaternidadUuid: corralMaternidadUuid,
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
        state = state.copyWith(
          isLoading: false,
          lastParto: parto,
          partos: [parto, ...state.partos],
          isSuccess: true,
        );
        return true;
      },
    );
  }

  Future<bool> registrarDestete({
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
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    final result = await _repository.registrarDestete(
      porcinoId: porcinoId,
      hembraUuid: hembraUuid,
      hembraArete: hembraArete,
      corralDestinoUuid: corralDestinoUuid,
      fechaDestete: fechaDestete,
      lechonesDestetados: lechonesDestetados,
      pesoTotalKg: pesoTotalKg,
      diasLactancia: diasLactancia,
      observaciones: observaciones,
    );
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (dest) {
        state = state.copyWith(
          isLoading: false,
          destetes: [dest, ...state.destetes],
          isSuccess: true,
        );
        return true;
      },
    );
  }
}

final reproductionNotifierProvider =
    NotifierProvider<ReproductionNotifier, ReproductionState>(
  ReproductionNotifier.new,
);
