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

  Either<Failure, DashboardSummaryEntity> _buildOfflineSummary(int pendingCount) {
    final cachedJson = cacheService.getCachedJson(cacheService.keyCachedDashboard);
    final cachedAnimals = cacheService.getCachedJson(cacheService.keyCachedAnimals);
    final cachedLotes = cacheService.getCachedJson(cacheService.keyCachedLotes);
    final cachedWithdrawals =
        cacheService.getCachedJson(cacheService.keyCachedWithdrawals);
    final cachedServices =
        cacheService.getCachedJson(cacheService.keyCachedServices);

    final animalsList = cachedAnimals is List
        ? cachedAnimals.whereType<Map<String, dynamic>>().toList()
        : const <Map<String, dynamic>>[];
    final lotesList = cachedLotes is List
        ? cachedLotes.whereType<Map<String, dynamic>>().toList()
        : const <Map<String, dynamic>>[];

    final now = DateTime.now();
    int? activeWithdrawals;
    if (cachedWithdrawals is List) {
      activeWithdrawals = cachedWithdrawals.whereType<Map<String, dynamic>>().where((w) {
        final dias = (w['dias_restantes'] as num?)?.toInt();
        if (dias != null) return dias > 0;
        final fin = DateTime.tryParse(w['fecha_fin_retiro']?.toString() ?? '');
        return fin == null || !fin.isBefore(DateTime(now.year, now.month, now.day));
      }).length;
    }

    int? activeGestations;
    int? monthFarrowings;
    if (cachedServices is List) {
      final services = cachedServices.whereType<Map<String, dynamic>>().toList();
      activeGestations = services.where((s) {
        final est = s['estado']?.toString().toLowerCase() ?? '';
        return est == 'gestante' || est == 'activo' || est == 'pendiente';
      }).length;
      monthFarrowings = services.where((s) {
        final est = s['estado']?.toString().toLowerCase() ?? '';
        final fp = DateTime.tryParse(s['fecha_parto_real']?.toString() ?? '');
        return est == 'parto' &&
            fp != null &&
            fp.year == now.year &&
            fp.month == now.month;
      }).length;
    }

    if (cachedJson is Map<String, dynamic>) {
      final base = DashboardSummaryModel.fromJson(
        cachedJson,
        pendingSync: pendingCount,
      );
      return Right(
        DashboardSummaryModel(
          totalPorcinos: animalsList.isNotEmpty ? animalsList.length : base.totalPorcinos,
          totalCorralesActivos:
              lotesList.isNotEmpty ? lotesList.length : base.totalCorralesActivos,
          pesoPromedioGranjaKg: base.pesoPromedioGranjaKg,
          alertasSanitarias: activeWithdrawals ?? base.alertasSanitarias,
          alertasInventarioStock: base.alertasInventarioStock,
          tasaOcupacionPorcentaje: base.tasaOcupacionPorcentaje,
          porcinosEnCeba: base.porcinosEnCeba,
          hembrasGestacion: activeGestations ?? base.hembrasGestacion,
          partosMes: monthFarrowings ?? base.partosMes,
          gdpPromedioGramoDia: base.gdpPromedioGramoDia,
          registrosPendientesSync: pendingCount,
          alertas: base.alertas,
          actividadReciente: base.actividadReciente,
        ),
      );
    }

    if (animalsList.isEmpty &&
        lotesList.isEmpty &&
        cachedWithdrawals == null &&
        cachedServices == null &&
        pendingCount == 0) {
      return const Left(
        CacheFailure(
          'Sin catálogo offline guardado. Descargue los datos desde Ajustes cuando tenga red.',
        ),
      );
    }

    double sumPeso = 0.0;
    int pesoCount = 0;
    int ceba = 0;
    int gest = 0;
    for (final a in animalsList) {
      final p = (a['peso_actual_kg'] as num?)?.toDouble() ??
          (a['peso_actual'] as num?)?.toDouble() ??
          0.0;
      if (p > 0) {
        sumPeso += p;
        pesoCount++;
      }
      final fase = (a['fase'] ?? a['estado'] ?? '').toString().toLowerCase();
      if (fase == 'ceba' || fase == 'engorde' || fase == 'levante') ceba++;
      if (fase == 'gestacion' || fase == 'maternidad' || fase == 'lactante') gest++;
    }

    return Right(
      DashboardSummaryModel(
        totalPorcinos: animalsList.length,
        totalCorralesActivos: lotesList.length,
        pesoPromedioGranjaKg: pesoCount > 0 ? sumPeso / pesoCount : 0.0,
        alertasSanitarias: activeWithdrawals ?? 0,
        alertasInventarioStock: 0,
        tasaOcupacionPorcentaje: 0.0,
        porcinosEnCeba: ceba,
        hembrasGestacion: activeGestations ?? gest,
        partosMes: monthFarrowings ?? 0,
        gdpPromedioGramoDia: 0.0,
        registrosPendientesSync: pendingCount,
      ),
    );
  }

  @override
  Future<Either<Failure, DashboardSummaryEntity>> getSummary() async {
    final pendingCount = cacheService.getPendingSyncCount();

    if (cacheService.isOfflineModeEnabled()) {
      return _buildOfflineSummary(pendingCount);
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
      return _buildOfflineSummary(pendingCount);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
