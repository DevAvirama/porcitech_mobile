import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:porcitech_mobile/src/core/di/core_providers.dart';
import 'package:porcitech_mobile/src/features/weight_estimation/data/datasources/weight_remote_datasource.dart';
import 'package:porcitech_mobile/src/features/weight_estimation/data/repositories/weight_repository_impl.dart';
import 'package:porcitech_mobile/src/features/weight_estimation/domain/entities/weight_record_entity.dart';
import 'package:porcitech_mobile/src/features/weight_estimation/domain/repositories/weight_repository.dart';

final weightRemoteDataSourceProvider = Provider<WeightRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return WeightRemoteDataSourceImpl(dioClient);
});

final weightRepositoryProvider = Provider<WeightRepository>((ref) {
  final remote = ref.watch(weightRemoteDataSourceProvider);
  final cache = ref.watch(localCacheServiceProvider);
  return WeightRepositoryImpl(remoteDataSource: remote, cacheService: cache);
});

class WeightState {
  final bool isLoading;
  final WeightRecordEntity? lastRecord;
  final IaWeightEstimationResult? iaResult;
  final String? errorMessage;
  final bool isSuccess;

  const WeightState({
    this.isLoading = false,
    this.lastRecord,
    this.iaResult,
    this.errorMessage,
    this.isSuccess = false,
  });

  WeightState copyWith({
    bool? isLoading,
    WeightRecordEntity? lastRecord,
    IaWeightEstimationResult? iaResult,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return WeightState(
      isLoading: isLoading ?? this.isLoading,
      lastRecord: lastRecord ?? this.lastRecord,
      iaResult: iaResult ?? this.iaResult,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class WeightNotifier extends Notifier<WeightState> {
  @override
  WeightState build() => const WeightState();

  WeightRepository get _repository => ref.read(weightRepositoryProvider);

  Future<bool> registrarPesaje({
    required int porcinoId,
    required double peso,
    required DateTime fecha,
    required String tipo,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    final result = await _repository.registrarPesaje(
      porcinoId: porcinoId,
      peso: peso,
      fecha: fecha,
      tipo: tipo,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (record) {
        state = state.copyWith(isLoading: false, lastRecord: record, isSuccess: true);
        return true;
      },
    );
  }

  Future<IaWeightEstimationResult?> estimarConIa({
    required int porcinoId,
    required File imageFile,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.estimarPesoPorIa(
      porcinoId: porcinoId,
      imagenCenital: imageFile,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return null;
      },
      (res) {
        state = state.copyWith(isLoading: false, iaResult: res);
        return res;
      },
    );
  }

  void resetState() {
    state = const WeightState();
  }
}

final weightNotifierProvider =
    NotifierProvider<WeightNotifier, WeightState>(WeightNotifier.new);
