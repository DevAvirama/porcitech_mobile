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
  final String? errorMessage;
  final String searchQuery;
  final String selectedFilter;

  const AnimalsListState({
    this.isLoading = false,
    this.porcinos = const [],
    this.errorMessage,
    this.searchQuery = '',
    this.selectedFilter = 'Todos',
  });

  AnimalsListState copyWith({
    bool? isLoading,
    List<PorcinoEntity>? porcinos,
    String? errorMessage,
    String? searchQuery,
    String? selectedFilter,
  }) {
    return AnimalsListState(
      isLoading: isLoading ?? this.isLoading,
      porcinos: porcinos ?? this.porcinos,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedFilter: selectedFilter ?? this.selectedFilter,
    );
  }
}

class AnimalsNotifier extends Notifier<AnimalsListState> {
  @override
  AnimalsListState build() {
    Future.microtask(() => fetchPorcinos());
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
    required String raza,
    required String sexo,
    required DateTime fechaNacimiento,
    required int loteId,
  }) async {
    state = state.copyWith(isLoading: true);
    final result = await _repository.createPorcino(
      codigo: codigo,
      raza: raza,
      sexo: sexo,
      fechaNacimiento: fechaNacimiento,
      loteId: loteId,
    );
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (created) {
        fetchPorcinos();
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
