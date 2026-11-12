import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/dashboard_summary_entity.dart';
import '../models/dashboard_summary_model.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardSummaryModel> getSummary();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final DioClient _client;

  DashboardRemoteDataSourceImpl(this._client);

  @override
  Future<DashboardSummaryModel> getSummary() async {
    try {
      final response = await _client.get(ApiConstants.dashboardSummary);
      if (response.data is! Map<String, dynamic>) {
        throw const ServerException('Formato inválido al obtener métricas del dashboard.');
      }

      List<DashboardAlertEntity> alertas = [];
      try {
        final alertsRes = await _client.get(ApiConstants.dashboardAlerts);
        if (alertsRes.data is List) {
          alertas = (alertsRes.data as List)
              .whereType<Map<String, dynamic>>()
              .map(
                (a) => DashboardAlertEntity(
                  id: a['id']?.toString() ?? '',
                  nivel: a['nivel']?.toString() ?? 'info',
                  modulo: a['modulo']?.toString() ?? 'manejo',
                  mensaje: a['mensaje']?.toString() ?? '',
                  accionSugerida: a['accion_sugerida']?.toString() ?? '',
                ),
              )
              .toList();
        }
      } catch (_) {}

      List<RecentActivityEntity> actividad = [];
      try {
        final actRes = await _client.get(
          ApiConstants.dashboardRecentActivity,
          queryParameters: const {'limite': 6},
        );
        if (actRes.data is List) {
          actividad = (actRes.data as List)
              .whereType<Map<String, dynamic>>()
              .map(
                (item) => RecentActivityEntity(
                  id: item['id']?.toString() ?? '',
                  tipo: item['tipo']?.toString() ?? 'manejo',
                  titulo: item['titulo']?.toString() ?? '',
                  descripcion: item['descripcion']?.toString() ?? '',
                  tiempo: DateTime.tryParse(item['tiempo']?.toString() ?? '') ??
                      DateTime.now(),
                  usuario: item['usuario']?.toString() ?? 'Sistema',
                ),
              )
              .toList();
        }
      } catch (_) {}

      return DashboardSummaryModel.fromJson(
        response.data as Map<String, dynamic>,
        alertas: alertas,
        actividadReciente: actividad,
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
