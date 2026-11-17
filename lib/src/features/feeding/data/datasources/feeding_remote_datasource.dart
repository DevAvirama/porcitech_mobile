import 'package:porcitech_mobile/src/core/constants/api_constants.dart';
import 'package:porcitech_mobile/src/core/errors/exceptions.dart';
import 'package:porcitech_mobile/src/core/network/dio_client.dart';
import 'package:porcitech_mobile/src/features/feeding/domain/entities/feeding_entity.dart';

abstract class FeedingRemoteDataSource {
  Future<List<FeedingRationEntity>> getRaciones({int limite = 40});
  Future<List<Map<String, dynamic>>> getRawInventarioItems();
  Future<void> registrarRacion(Map<String, dynamic> payload);
}

class FeedingRemoteDataSourceImpl implements FeedingRemoteDataSource {
  final DioClient _client;

  FeedingRemoteDataSourceImpl(this._client);

  @override
  Future<List<FeedingRationEntity>> getRaciones({int limite = 40}) async {
    try {
      final res = await _client.get(
        ApiConstants.raciones,
        queryParameters: {'limite': limite},
      );
      if (res.data is List) {
        return (res.data as List)
            .whereType<Map<String, dynamic>>()
            .map(
              (m) => FeedingRationEntity(
                id: m['id']?.toString() ?? '',
                corralUuid: m['corral_id']?.toString() ?? '',
                corralCodigo: m['corral_codigo']?.toString() ?? 'COR',
                alimentoItemId: m['alimento_item_id']?.toString() ?? '',
                alimentoNombre:
                    m['alimento_nombre']?.toString() ?? 'Concentrado',
                faseAlimentacion:
                    m['fase_alimentacion']?.toString() ?? 'Ceba',
                cantidadKg: (m['cantidad_kg'] as num?)?.toDouble() ?? 0.0,
                costoTotal: (m['costo_total'] as num?)?.toDouble() ?? 0.0,
                fechaSuministro:
                    DateTime.tryParse(m['fecha_suministro']?.toString() ?? '') ??
                        DateTime.now(),
                operarioNombre: m['operario_nombre']?.toString(),
                observaciones: m['observaciones']?.toString(),
              ),
            )
            .toList();
      }
      return const [];
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRawInventarioItems() async {
    try {
      final res = await _client.get(ApiConstants.inventarioItems);
      if (res.data is List) {
        return (res.data as List).whereType<Map<String, dynamic>>().toList();
      }
      return const [];
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> registrarRacion(Map<String, dynamic> payload) async {
    try {
      await _client.post(ApiConstants.raciones, data: payload);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
