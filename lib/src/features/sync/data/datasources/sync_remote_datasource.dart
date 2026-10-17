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

  String _normalizeEndpoint(String rawEndpoint) {
    switch (rawEndpoint) {
      case '/api/porcinos/':
        return ApiConstants.porcinos;
      case '/api/lotes/':
        return ApiConstants.lotes;
      case '/api/eventos-sanitarios/':
        return ApiConstants.eventosSanitarios;
      case '/api/eventos-reproductivos/':
        return ApiConstants.partos;
      case '/api/pesos/':
        return ApiConstants.pesos;
      default:
        return rawEndpoint.isNotEmpty ? rawEndpoint : ApiConstants.pesos;
    }
  }

  @override
  Future<int> sendOfflineQueue(List<Map<String, dynamic>> queueItems) async {
    try {
      int processed = 0;
      for (final item in queueItems) {
        final endpoint = _normalizeEndpoint(item['endpoint']?.toString() ?? '');
        final payload = item['payload'] is Map<String, dynamic>
            ? item['payload'] as Map<String, dynamic>
            : <String, dynamic>{};
        await _client.post(endpoint, data: payload);
        processed++;
      }
      return processed;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
