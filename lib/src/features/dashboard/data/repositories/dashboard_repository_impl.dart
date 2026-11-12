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
        return Right(
          DashboardSummaryModel.fromJson(cachedJson, pendingSync: pendingCount),
        );
      }
      return Right(
        DashboardSummaryModel(
          totalPorcinos: 64,
          totalCorralesActivos: 3,
          pesoPromedioGranjaKg: 74.5,
          alertasSanitarias: 2,
          alertasInventarioStock: 1,
          tasaOcupacionPorcentaje: 71.0,
          porcinosEnCeba: 52,
          hembrasGestacion: 12,
          partosMes: 4,
          gdpPromedioGramoDia: 795.0,
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
          totalCorralesActivos: summary.totalCorralesActivos,
          pesoPromedioGranjaKg: summary.pesoPromedioGranjaKg,
          alertasSanitarias: summary.alertasSanitarias,
          alertasInventarioStock: summary.alertasInventarioStock,
          tasaOcupacionPorcentaje: summary.tasaOcupacionPorcentaje,
          porcinosEnCeba: summary.porcinosEnCeba,
          hembrasGestacion: summary.hembrasGestacion,
          partosMes: summary.partosMes,
          gdpPromedioGramoDia: summary.gdpPromedioGramoDia,
          registrosPendientesSync: pendingCount,
          alertas: summary.alertas,
          actividadReciente: summary.actividadReciente,
        ),
      );
    } on AppException catch (_) {
      final cachedJson = cacheService.getCachedJson(cacheService.keyCachedDashboard);
      if (cachedJson != null && cachedJson is Map<String, dynamic>) {
        return Right(
          DashboardSummaryModel.fromJson(cachedJson, pendingSync: pendingCount),
        );
      }
      return Right(
        DashboardSummaryModel(
          totalPorcinos: 64,
          totalCorralesActivos: 3,
          pesoPromedioGranjaKg: 74.5,
          alertasSanitarias: 2,
          alertasInventarioStock: 1,
          tasaOcupacionPorcentaje: 71.0,
          porcinosEnCeba: 52,
          hembrasGestacion: 12,
          partosMes: 4,
          gdpPromedioGramoDia: 795.0,
          registrosPendientesSync: pendingCount,
        ),
      );
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
