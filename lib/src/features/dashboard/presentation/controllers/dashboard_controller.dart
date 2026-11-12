import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:porcitech_mobile/src/core/di/core_providers.dart';
import 'package:porcitech_mobile/src/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:porcitech_mobile/src/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:porcitech_mobile/src/features/dashboard/domain/entities/dashboard_summary_entity.dart';
import 'package:porcitech_mobile/src/features/dashboard/domain/repositories/dashboard_repository.dart';

final dashboardRemoteDataSourceProvider =
    Provider<DashboardRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return DashboardRemoteDataSourceImpl(dioClient);
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final remoteDataSource = ref.watch(dashboardRemoteDataSourceProvider);
  final cacheService = ref.watch(localCacheServiceProvider);
  return DashboardRepositoryImpl(
    remoteDataSource: remoteDataSource,
    cacheService: cacheService,
  );
});

class DashboardState {
  final bool isLoading;
  final DashboardSummaryEntity? summary;
  final String? errorMessage;

  const DashboardState({
    this.isLoading = false,
    this.summary,
    this.errorMessage,
  });

  DashboardState copyWith({
    bool? isLoading,
    DashboardSummaryEntity? summary,
    String? errorMessage,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      summary: summary ?? this.summary,
      errorMessage: errorMessage,
    );
  }
}

class DashboardNotifier extends Notifier<DashboardState> {
  @override
  DashboardState build() {
    Future.microtask(() => loadSummary());
    return const DashboardState();
  }

  DashboardRepository get _repository => ref.read(dashboardRepositoryProvider);

  Future<void> loadSummary() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.getSummary();
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (summary) => state = state.copyWith(
        isLoading: false,
        summary: summary,
      ),
    );
  }
}

final dashboardNotifierProvider =
    NotifierProvider<DashboardNotifier, DashboardState>(DashboardNotifier.new);
