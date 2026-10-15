import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
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
      if (response.data is Map<String, dynamic>) {
        return DashboardSummaryModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw const ServerException('Formato inválido al obtener métricas del dashboard.');
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
