import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:porcitech_mobile/src/core/di/core_providers.dart';
import 'package:porcitech_mobile/src/features/animals/data/datasources/animals_remote_datasource.dart';
import 'package:porcitech_mobile/src/features/animals/data/repositories/animals_repository_impl.dart';
import 'package:porcitech_mobile/src/features/animals/domain/entities/porcino_entity.dart';
import 'package:porcitech_mobile/src/features/animals/domain/repositories/animals_repository.dart';

final animalsRemoteDataSourceProvider =
    Provider<AnimalsRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AnimalsRemoteDataSourceImpl(dioClient);
});

final animalsRepositoryProvider = Provider<AnimalsRepository>((ref) {
  final remoteDataSource = ref.watch(animalsRemoteDataSourceProvider);
  final cacheService = ref.watch(localCacheServiceProvider);
  return AnimalsRepositoryImpl(
    remoteDataSource: remoteDataSource,
    cacheService: cacheService,
  );
});

class AnimalsListState {
  final bool isLoading;
  final List<PorcinoEntity> porcinos;
  final List<LoteEntity> lotes;
  final String? errorMessage;
  final String searchQuery;
  final String selectedFilter;

  const AnimalsListState({
    this.isLoading = false,
    this.porcinos = const [],
    this.lotes = const [],
    this.errorMessage,
    this.searchQuery = '',
    this.selectedFilter = 'Todos',
  });

  AnimalsListState copyWith({
    bool? isLoading,
    List<PorcinoEntity>? porcinos,
    List<LoteEntity>? lotes,
    String? errorMessage,
    String? searchQuery,
    String? selectedFilter,
  }) {
    return AnimalsListState(
      isLoading: isLoading ?? this.isLoading,
      porcinos: porcinos ?? this.porcinos,
      lotes: lotes ?? this.lotes,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedFilter: selectedFilter ?? this.selectedFilter,
    );
  }
}

class AnimalsNotifier extends Notifier<AnimalsListState> {
  @override
  AnimalsListState build() {
    Future.microtask(() {
      fetchPorcinos();
      fetchLotes();
    });
    return const AnimalsListState();
  }

  AnimalsRepository get _repository => ref.read(animalsRepositoryProvider);

  Future<void> fetchPorcinos() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.getPorcinos(
      query: state.searchQuery,
      filter: state.selectedFilter,
    );
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (list) => state = state.copyWith(
        isLoading: false,
        porcinos: list,
      ),
    );
  }

  Future<void> fetchLotes() async {
    final result = await _repository.getLotes();
    result.fold(
      (_) {},
      (lotesList) => state = state.copyWith(lotes: lotesList),
    );
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    fetchPorcinos();
  }

  void setFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
    fetchPorcinos();
  }

  Future<bool> registerPorcino({
    required String codigo,
    String? nombreAlias,
    required String raza,
    required String sexo,
    required DateTime fechaNacimiento,
    required int loteId,
    String? corralUuid,
    String estado = 'levante',
    double pesoInicialKg = 0.0,
  }) async {
    state = state.copyWith(isLoading: true);
    final result = await _repository.createPorcino(
      codigo: codigo,
      nombreAlias: nombreAlias,
      raza: raza,
      sexo: sexo,
      fechaNacimiento: fechaNacimiento,
      loteId: loteId,
      corralUuid: corralUuid,
      estado: estado,
      pesoInicialKg: pesoInicialKg,
    );
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (created) {
        fetchPorcinos();
        fetchLotes();
        return true;
      },
    );
  }

  Future<bool> registerLote({
    required String codigo,
    required String nombre,
    required String fase,
    required String galpon,
    int capacidadMaxima = 25,
  }) async {
    state = state.copyWith(isLoading: true);
    final result = await _repository.createLote(
      codigo: codigo,
      nombre: nombre,
      fase: fase,
      galpon: galpon,
      capacidadMaxima: capacidadMaxima,
    );
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (created) {
        fetchLotes();
        state = state.copyWith(isLoading: false);
        return true;
      },
    );
  }
}

final animalsNotifierProvider =
    NotifierProvider<AnimalsNotifier, AnimalsListState>(AnimalsNotifier.new);

final lotesListProvider = FutureProvider<List<LoteEntity>>((ref) async {
  final repository = ref.watch(animalsRepositoryProvider);
  final result = await repository.getLotes();
  return result.getOrElse((_) => []);
});

final porcinoDetailProvider =
    FutureProvider.family<PorcinoEntity, int>((ref, id) async {
  final repository = ref.watch(animalsRepositoryProvider);
  final result = await repository.getPorcinoById(id);
  return result.fold(
    (l) => throw Exception(l.message),
    (r) => r,
  );
});

final historialPesajesProvider =
    FutureProvider.family<List<PesoHistoricoItem>, PorcinoEntity>((ref, porcino) async {
  final repository = ref.watch(animalsRepositoryProvider);
  final result = await repository.getHistorialPesajes(
    porcino.id,
    uuid: porcino.uuid,
  );
  return result.getOrElse((_) => porcino.curvaCrecimiento);
});
