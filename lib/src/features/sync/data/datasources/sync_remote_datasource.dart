import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';

abstract class SyncRemoteDataSource {
  Future<Map<String, dynamic>> getUserProfile();
  Future<void> sendSingleItem(Map<String, dynamic> item);
  Future<int> sendOfflineQueue(List<Map<String, dynamic>> queueItems);
  Future<Map<String, dynamic>> downloadOfflineCatalog();
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
        'granja': 'Unidad Porcina SENA',
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
      case '/animales':
        return ApiConstants.porcinos;
      case '/api/lotes/':
      case '/corrales':
        return ApiConstants.lotes;
      case '/api/eventos-sanitarios/':
      case '/sanidad/tratamientos':
        return ApiConstants.eventosSanitarios;
      case '/sanidad/bioseguridad/ejecuciones':
        return ApiConstants.bioseguridadEjecuciones;
      case '/api/eventos-reproductivos/':
      case '/reproduccion/partos':
        return ApiConstants.partos;
      case '/reproduccion/servicios':
        return ApiConstants.eventosReproductivos;
      case '/reproduccion/destetes':
        return ApiConstants.destetes;
      case '/alimentacion/raciones':
        return ApiConstants.raciones;
      case '/pesajes/vision':
        return ApiConstants.iaEstimarPeso;
      case '/api/pesos/':
      case '/pesajes/manual':
        return ApiConstants.pesos;
      default:
        return rawEndpoint.isNotEmpty ? rawEndpoint : ApiConstants.pesos;
    }
  }

  @override
  Future<void> sendSingleItem(Map<String, dynamic> item) async {
    final endpoint = _normalizeEndpoint(item['endpoint']?.toString() ?? '');
    final payload = item['payload'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(item['payload'] as Map<String, dynamic>)
        : <String, dynamic>{};

    final filePath = item['filePath']?.toString();
    if (filePath != null && filePath.isNotEmpty) {
      final file = File(filePath);
      if (!await file.exists()) {
        throw const NotFoundException(
          'El archivo fotográfico guardado en el dispositivo ya no existe.',
        );
      }
      final fileName = file.path.split('/').last;
      final formMap = <String, dynamic>{
        ...payload,
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      };
      await _client.postMultipart(
        endpoint,
        formData: FormData.fromMap(formMap),
      );
      return;
    }

    await _client.post(endpoint, data: payload);
  }

  @override
  Future<int> sendOfflineQueue(List<Map<String, dynamic>> queueItems) async {
    try {
      int processed = 0;
      for (final item in queueItems) {
        await sendSingleItem(item);
        processed++;
      }
      return processed;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> downloadOfflineCatalog() async {
    try {
      final results = await Future.wait([
        _client.get(ApiConstants.porcinos),
        _client.get(ApiConstants.lotes),
        _client.get(ApiConstants.inventarioItems),
        _client.get(ApiConstants.alertasRetiro),
        _client.get(
          ApiConstants.bioseguridadProtocolos,
          queryParameters: const {'activo': 'true'},
        ),
        _client.get(ApiConstants.bioseguridadEjecuciones),
        _client.get(ApiConstants.dashboardSummary),
        _client.get(ApiConstants.dashboardAlerts),
        _client.get(ApiConstants.eventosReproductivos),
      ]);

      return {
        'animales': results[0].data,
        'corrales': results[1].data,
        'inventario': results[2].data,
        'alertasRetiro': results[3].data,
        'protocolos': results[4].data,
        'ejecuciones': results[5].data,
        'dashboardKpis': results[6].data,
        'dashboardAlerts': results[7].data,
        'servicios': results[8].data,
      };
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
