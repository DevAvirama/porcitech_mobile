import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
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

      // 1. Registro del evento clínico en FastAPI
      final responseEvento = await _client.post(
        ApiConstants.eventosSanitarios,
        data: {
          'porcino': porcinoId,
          'tipo': tipo,
          'medicamento': medicamento,
          'lote_biologico': loteBiologico,
          'dosis': dosisMl,
          'via_aplicacion': viaAplicacion,
          'descripcion': 'Aplicación de $medicamento (Lote $loteBiologico)',
          'fecha': fecha.toIso8601String().split('T').first,
          'dias_retiro': diasRetiro,
          'fecha_fin_retiro': fechaFin.toIso8601String().split('T').first,
          'observaciones': observaciones ?? 'Sin reacción adversa',
        },
      );

      // 2. Descuento automático de inventario farmacológico
      try {
        await _client.post(
          ApiConstants.inventarioDescuento,
          data: {
            'insumo': 8, // ID genérico de inventario de medicamentos
            'medicamento': medicamento,
            'cantidad': dosisMl.ceil(),
            'unidad': 'ml',
            'motivo': 'Sanidad animal porcino #$porcinoId',
          },
        );
      } catch (_) {
        // La deducción de inventario secundaria no bloquea el registro clínico del porcino
      }

      final data = responseEvento.data;
      final int id = (data is Map<String, dynamic>) ? (data['id'] as int? ?? 1) : 1;

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
