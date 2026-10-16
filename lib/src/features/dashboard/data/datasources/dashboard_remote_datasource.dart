import 'package:porcitech_mobile/src/core/network/dio_client.dart';
import '../models/dashboard_summary_model.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardSummaryModel> getSummary();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final DioClient dioClient;

  DashboardRemoteDataSourceImpl(this.dioClient);

  @override
  Future<DashboardSummaryModel> getSummary() async {
    final response = await dioClient.get('/api/dashboard/summary/');
    return DashboardSummaryModel.fromJson(response.data as Map<String, dynamic>);
  }
}