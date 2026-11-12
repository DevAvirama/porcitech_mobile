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
  final List<HealthEventEntity> tratamientos;
  final List<WithdrawalAlertItem> alertasRetiro;
  final List<BiosecurityProtocolItem> protocolos;
  final String? errorMessage;
  final bool isSuccess;

  const HealthState({
    this.isLoading = false,
    this.lastEvent,
    this.tratamientos = const [],
    this.alertasRetiro = const [],
    this.protocolos = const [],
    this.errorMessage,
    this.isSuccess = false,
  });

  HealthState copyWith({
    bool? isLoading,
    HealthEventEntity? lastEvent,
    List<HealthEventEntity>? tratamientos,
    List<WithdrawalAlertItem>? alertasRetiro,
    List<BiosecurityProtocolItem>? protocolos,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return HealthState(
      isLoading: isLoading ?? this.isLoading,
      lastEvent: lastEvent ?? this.lastEvent,
      tratamientos: tratamientos ?? this.tratamientos,
      alertasRetiro: alertasRetiro ?? this.alertasRetiro,
      protocolos: protocolos ?? this.protocolos,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class HealthNotifier extends Notifier<HealthState> {
  @override
  HealthState build() {
    Future.microtask(() => loadSanidadData());
    return const HealthState();
  }

  HealthRepository get _repository => ref.read(healthRepositoryProvider);

  Future<void> loadSanidadData({String? animalUuid}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final tratRes = await _repository.getTratamientos(animalUuid: animalUuid);
    final alertRes = await _repository.getAlertasRetiro();
    final protoRes = await _repository.getProtocolosBioseguridad();

    state = state.copyWith(
      isLoading: false,
      tratamientos: tratRes.getOrElse((_) => []),
      alertasRetiro: alertRes.getOrElse((_) => []),
      protocolos: protoRes.getOrElse((_) => []),
    );
  }

  Future<bool> registrarEvento({
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
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    final result = await _repository.registrarEventoSanitario(
      porcinoId: porcinoId,
      animalUuid: animalUuid,
      corralUuid: corralUuid,
      medicamentoUuid: medicamentoUuid,
      tipo: tipo,
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

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (event) {
        state = state.copyWith(
          isLoading: false,
          lastEvent: event,
          tratamientos: [event, ...state.tratamientos],
          isSuccess: true,
        );
        loadSanidadData(animalUuid: animalUuid);
        return true;
      },
    );
  }

  Future<void> toggleProtocolo(String protocoloId, bool cumplido) async {
    final updated = state.protocolos.map((p) {
      if (p.id == protocoloId) {
        return p.copyWith(cumplidoHoy: cumplido);
      }
      return p;
    }).toList();
    state = state.copyWith(protocolos: updated);

    await _repository.toggleProtocoloBioseguridad(
      protocoloId: protocoloId,
      cumplido: cumplido,
    );
  }
}

final healthNotifierProvider =
    NotifierProvider<HealthNotifier, HealthState>(HealthNotifier.new);
