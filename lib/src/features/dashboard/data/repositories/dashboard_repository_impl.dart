import 'package:fpdart/fpdart.dart';
import 'package:porcitech_mobile/src/core/errors/exceptions.dart';
import 'package:porcitech_mobile/src/core/errors/failures.dart';
import 'package:porcitech_mobile/src/core/storage/local_cache_service.dart';
import 'package:porcitech_mobile/src/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:porcitech_mobile/src/features/dashboard/data/models/dashboard_summary_model.dart';
import 'package:porcitech_mobile/src/features/dashboard/domain/entities/dashboard_summary_entity.dart';
import 'package:porcitech_mobile/src/features/dashboard/domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;
  final LocalCacheService cacheService;

  DashboardRepositoryImpl({
    required this.remoteDataSource,
    required this.cacheService,
  });

  @override
  Future<Either<Failure, DashboardSummaryEntity>> getSummary() async {
    final pendingCount = cacheService.getOfflineQueue().length;

    if (cacheService.isOfflineModeEnabled()) {
      final cachedJson = cacheService.getCachedJson(cacheService.keyCachedDashboard);
      if (cachedJson != null && cachedJson is Map<String, dynamic>) {
        return Right(DashboardSummaryModel.fromJson(cachedJson, pendingSync: pendingCount));
      }
      return Right(
        DashboardSummaryModel(
          totalPorcinos: 1420,
          alertasSanitarias: 3,
          porcinosEnCeba: 860,
          hembrasGestacion: 310,
          partosMes: 28,
          gdpPromedioGramoDia: 835.0,
          registrosPendientesSync: pendingCount,
        ),
      );
    }

    try {
      final summary = await remoteDataSource.getSummary();
      await cacheService.cacheJson(cacheService.keyCachedDashboard, summary.toJson());
      return Right(
        DashboardSummaryModel(
          totalPorcinos: summary.totalPorcinos,
          alertasSanitarias: summary.alertasSanitarias,
          porcinosEnCeba: summary.porcinosEnCeba,
          hembrasGestacion: summary.hembrasGestacion,
          partosMes: summary.partosMes,
          gdpPromedioGramoDia: summary.gdpPromedioGramoDia,
          registrosPendientesSync: pendingCount,
        ),
      );
    } on AppException catch (_) {
      final cachedJson = cacheService.getCachedJson(cacheService.keyCachedDashboard);
      if (cachedJson != null && cachedJson is Map<String, dynamic>) {
        return Right(DashboardSummaryModel.fromJson(cachedJson, pendingSync: pendingCount));
      }
      return Right(
        DashboardSummaryModel(
          totalPorcinos: 1420,
          alertasSanitarias: 3,
          porcinosEnCeba: 860,
          hembrasGestacion: 310,
          partosMes: 28,
          gdpPromedioGramoDia: 835.0,
          registrosPendientesSync: pendingCount,
        ),
      );
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
