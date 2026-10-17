import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../animals/data/models/porcino_model.dart';
import '../../domain/entities/reproduction_event_entity.dart';

abstract class ReproductionRemoteDataSource {
  Future<ReproductionEventEntity> registrarParto({
    required int porcinoId,
    required DateTime fecha,
    required int nacidosVivos,
    required int nacidosMuertos,
    required int momias,
    required double pesoTotalCamadaKg,
    int numeroParto = 1,
    String? observaciones,
  });
}

class ReproductionRemoteDataSourceImpl implements ReproductionRemoteDataSource {
  final DioClient _client;

  ReproductionRemoteDataSourceImpl(this._client);

  @override
  Future<ReproductionEventEntity> registrarParto({
    required int porcinoId,
    required DateTime fecha,
    required int nacidosVivos,
    required int nacidosMuertos,
    required int momias,
    required double pesoTotalCamadaKg,
    int numeroParto = 1,
    String? observaciones,
  }) async {
    try {
      final resolvedHembraUuid = PorcinoModel.resolveUuid(porcinoId);
      final payload = {
        if (resolvedHembraUuid != null) 'hembra_id': resolvedHembraUuid,
        'porcino': porcinoId,
        'tipo': 'parto',
        'fecha_parto': fecha.toIso8601String(),
        'fecha': fecha.toIso8601String().split('T').first,
        'numero_lechones': nacidosVivos,
        'nacidos_vivos': nacidosVivos,
        'nacidos_muertos': nacidosMuertos,
        'momias': momias,
        'peso_camada_total_kg': pesoTotalCamadaKg,
        'peso_total_camada': pesoTotalCamadaKg,
        'numero_parto': numeroParto,
        'observaciones': observaciones ?? 'Parto atendido en maternidad',
      };

      final response = await _client.post(
        ApiConstants.partos,
        data: payload,
      );

      final data = response.data;
      int id = 1;
      if (data is Map<String, dynamic> && data['id'] != null) {
        final rawId = data['id'];
        if (rawId is int) {
          id = rawId;
        } else {
          final idStr = rawId.toString().replaceAll('-', '');
          id = int.tryParse(idStr.length >= 8 ? idStr.substring(0, 8) : idStr, radix: 16) ??
              rawId.toString().hashCode.abs();
        }
      }

      return ReproductionEventEntity(
        id: id,
        porcinoId: porcinoId,
        fecha: fecha,
        nacidosVivos: nacidosVivos,
        nacidosMuertos: nacidosMuertos,
        momias: momias,
        pesoTotalCamadaKg: pesoTotalCamadaKg,
        numeroParto: numeroParto,
        observaciones: observaciones,
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
