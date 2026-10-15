import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:porcitech_mobile/src/core/di/core_providers.dart';
import 'package:porcitech_mobile/src/features/health_record/data/datasources/health_remote_datasource.dart';
import 'package:porcitech_mobile/src/features/health_record/data/repositories/health_repository_impl.dart';
import 'package:porcitech_mobile/src/features/health_record/domain/entities/health_event_entity.dart';
import 'package:porcitech_mobile/src/features/health_record/domain/repositories/health_repository.dart';

final healthRemoteDataSourceProvider = Provider<HealthRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return HealthRemoteDataSourceImpl(dioClient);
});

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  final remote = ref.watch(healthRemoteDataSourceProvider);
  final cache = ref.watch(localCacheServiceProvider);
  return HealthRepositoryImpl(remoteDataSource: remote, cacheService: cache);
});

class HealthState {
  final bool isLoading;
  final HealthEventEntity? lastEvent;
  final String? errorMessage;
  final bool isSuccess;

  const HealthState({
    this.isLoading = false,
    this.lastEvent,
    this.errorMessage,
    this.isSuccess = false,
  });

  HealthState copyWith({
    bool? isLoading,
    HealthEventEntity? lastEvent,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return HealthState(
      isLoading: isLoading ?? this.isLoading,
      lastEvent: lastEvent ?? this.lastEvent,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class HealthNotifier extends Notifier<HealthState> {
  @override
  HealthState build() => const HealthState();

  HealthRepository get _repository => ref.read(healthRepositoryProvider);

  Future<bool> registrarEvento({
    required int porcinoId,
    required String tipo,
    required String medicamento,
    required String loteBiologico,
    required double dosisMl,
    required String viaAplicacion,
    required DateTime fecha,
    required int diasRetiro,
    String? observaciones,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    final result = await _repository.registrarEventoSanitario(
      porcinoId: porcinoId,
      tipo: tipo,
      medicamento: medicamento,
      loteBiologico: loteBiologico,
      dosisMl: dosisMl,
      viaAplicacion: viaAplicacion,
      fecha: fecha,
      diasRetiro: diasRetiro,
      observaciones: observaciones,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (event) {
        state = state.copyWith(isLoading: false, lastEvent: event, isSuccess: true);
        return true;
      },
    );
  }
}

final healthNotifierProvider =
    NotifierProvider<HealthNotifier, HealthState>(HealthNotifier.new);
