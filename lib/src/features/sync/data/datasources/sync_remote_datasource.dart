import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';

abstract class SyncRemoteDataSource {
  Future<Map<String, dynamic>> getUserProfile();
  Future<int> sendOfflineQueue(List<Map<String, dynamic>> queueItems);
}

class SyncRemoteDataSourceImpl implements SyncRemoteDataSource {
  final DioClient _client;

  SyncRemoteDataSourceImpl(this._client);

  @override
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _client.get(ApiConstants.userProfile);
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {
        'username': 'operario_granja',
        'email': 'operario@porcitech.agro',
        'role': 'Operario de Galpón',
        'granja': 'Granja San Jerónimo',
      };
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<int> sendOfflineQueue(List<Map<String, dynamic>> queueItems) async {
    try {
      final response = await _client.post(
        ApiConstants.syncOfflineQueue,
        data: {'queue': queueItems},
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data['processed_count'] as int? ?? queueItems.length;
      }
      return queueItems.length;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
