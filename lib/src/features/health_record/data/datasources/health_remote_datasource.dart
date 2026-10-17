import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../animals/data/models/porcino_model.dart';
import '../../domain/entities/health_event_entity.dart';

abstract class HealthRemoteDataSource {
  Future<HealthEventEntity> registrarEventoSanitario({
    required int porcinoId,
    required String tipo,
    required String medicamento,
    required String loteBiologico,
    required double dosisMl,
    required String viaAplicacion,
    required DateTime fecha,
    required int diasRetiro,
    String? observaciones,
  });
}

class HealthRemoteDataSourceImpl implements HealthRemoteDataSource {
  final DioClient _client;

  HealthRemoteDataSourceImpl(this._client);

  @override
  Future<HealthEventEntity> registrarEventoSanitario({
    required int porcinoId,
    required String tipo,
    required String medicamento,
    required String loteBiologico,
    required double dosisMl,
    required String viaAplicacion,
    required DateTime fecha,
    required int diasRetiro,
    String? observaciones,
  }) async {
    try {
      final fechaFin = fecha.add(Duration(days: diasRetiro));
      final resolvedAnimalUuid = PorcinoModel.resolveUuid(porcinoId);

      // 1. Registro del evento clínico en FastAPI
      final responseEvento = await _client.post(
        ApiConstants.eventosSanitarios,
        data: {
          if (resolvedAnimalUuid != null) 'animal_id': resolvedAnimalUuid,
          'porcino': porcinoId,
          'tipo_evento': tipo.toLowerCase(),
          'tipo': tipo,
          'producto_nombre': medicamento,
          'medicamento': medicamento,
          'lote_biologico': loteBiologico,
          'dosis_aplicada': '$dosisMl ml',
          'dosis': dosisMl,
          'via_administracion': viaAplicacion.toLowerCase(),
          'via_aplicacion': viaAplicacion,
          'diagnostico': observaciones ?? 'Aplicación de $medicamento (Lote $loteBiologico)',
          'descripcion': 'Aplicación de $medicamento (Lote $loteBiologico)',
          'fecha_tratamiento': fecha.toIso8601String(),
          'fecha': fecha.toIso8601String().split('T').first,
          'tiempo_retiro_dias': diasRetiro,
          'dias_retiro': diasRetiro,
          'fecha_fin_retiro': fechaFin.toIso8601String().split('T').first,
          'observaciones': observaciones ?? 'Sin reacción adversa',
        },
      );

      final data = responseEvento.data;
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

      return HealthEventEntity(
        id: id,
        porcinoId: porcinoId,
        tipo: tipo,
        medicamento: medicamento,
        loteBiologico: loteBiologico,
        dosisMl: dosisMl,
        viaAplicacion: viaAplicacion,
        fecha: fecha,
        diasRetiro: diasRetiro,
        fechaFinRetiro: fechaFin,
        observaciones: observaciones,
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
