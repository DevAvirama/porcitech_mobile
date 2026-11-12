import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../animals/data/models/porcino_model.dart';
import '../../domain/entities/reproduction_event_entity.dart';

abstract class ReproductionRemoteDataSource {
  Future<List<ReproductionServiceEntity>> getServicios();
  Future<ReproductionServiceEntity> registrarServicio({
    required int porcinoId,
    String? hembraUuid,
    required String hembraArete,
    required String tipoServicio,
    String? codigoPajilla,
    required DateTime fechaServicio,
    String? observaciones,
  });
  Future<bool> actualizarDiagnosticoServicio({
    required String servicioId,
    required String estadoConfirmacion,
    String? observaciones,
  });

  Future<List<ReproductionEventEntity>> getPartos();
  Future<ReproductionEventEntity> registrarParto({
    required int porcinoId,
    String? hembraUuid,
    String? corralMaternidadUuid,
    required DateTime fecha,
    required int nacidosVivos,
    required int nacidosMuertos,
    required int momias,
    required double pesoTotalCamadaKg,
    int numeroParto = 1,
    String? observaciones,
  });

  Future<List<WeaningEventEntity>> getDestetes();
  Future<WeaningEventEntity> registrarDestete({
    required int porcinoId,
    String? hembraUuid,
    required String hembraArete,
    String? corralDestinoUuid,
    required DateTime fechaDestete,
    required int lechonesDestetados,
    required double pesoTotalKg,
    int diasLactancia = 21,
    String? observaciones,
  });
}

class ReproductionRemoteDataSourceImpl implements ReproductionRemoteDataSource {
  final DioClient _client;

  ReproductionRemoteDataSourceImpl(this._client);

  @override
  Future<List<ReproductionServiceEntity>> getServicios() async {
    try {
      final response = await _client.get(ApiConstants.eventosReproductivos);
      if (response.data is List) {
        return (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map((m) {
          final fechaServ = DateTime.tryParse(m['fecha_servicio']?.toString() ?? '') ??
              DateTime.now();
          final fechaProb = DateTime.tryParse(
                m['fecha_probable_parto']?.toString() ?? '',
              ) ??
              fechaServ.add(const Duration(days: 114));
          return ReproductionServiceEntity(
            id: m['id']?.toString() ?? '',
            hembraUuid: m['hembra_id']?.toString() ?? '',
            hembraArete: m['hembra_arete']?.toString() ?? 'CERDA',
            tipoServicio: m['tipo_servicio']?.toString() ?? 'inseminacion_artificial',
            codigoPajillaMacho: m['codigo_pajilla_macho']?.toString(),
            fechaServicio: fechaServ,
            fechaProbableParto: fechaProb,
            estadoConfirmacion: m['estado_confirmacion']?.toString() ?? 'pendiente',
            observaciones: m['observaciones']?.toString(),
          );
        }).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<ReproductionServiceEntity> registrarServicio({
    required int porcinoId,
    String? hembraUuid,
    required String hembraArete,
    required String tipoServicio,
    String? codigoPajilla,
    required DateTime fechaServicio,
    String? observaciones,
  }) async {
    try {
      final resolvedHembraUuid = hembraUuid ?? PorcinoModel.resolveUuid(porcinoId);
      final payload = <String, dynamic>{
        'hembra_id': ?resolvedHembraUuid,
        'tipo_servicio': tipoServicio,
        if (codigoPajilla != null && codigoPajilla.trim().isNotEmpty)
          'codigo_pajilla_macho': codigoPajilla.trim(),
        'fecha_servicio': fechaServicio.toIso8601String().split('T').first,
        'estado_confirmacion': 'pendiente',
        if (observaciones != null && observaciones.trim().isNotEmpty)
          'observaciones': observaciones.trim(),
      };

      final response = await _client.post(
        ApiConstants.eventosReproductivos,
        data: payload,
      );

      final data = response.data;
      final idStr = (data is Map<String, dynamic> && data['id'] != null)
          ? data['id'].toString()
          : DateTime.now().millisecondsSinceEpoch.toString();

      return ReproductionServiceEntity(
        id: idStr,
        hembraUuid: resolvedHembraUuid ?? '',
        hembraArete: hembraArete,
        tipoServicio: tipoServicio,
        codigoPajillaMacho: codigoPajilla,
        fechaServicio: fechaServicio,
        fechaProbableParto: fechaServicio.add(const Duration(days: 114)),
        estadoConfirmacion: 'pendiente',
        observaciones: observaciones,
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<bool> actualizarDiagnosticoServicio({
    required String servicioId,
    required String estadoConfirmacion,
    String? observaciones,
  }) async {
    try {
      await _client.put(
        ApiConstants.servicioReproductivoById(servicioId),
        data: {
          'estado_confirmacion': estadoConfirmacion,
          'fecha_diagnostico': DateTime.now().toIso8601String().split('T').first,
          if (observaciones != null && observaciones.trim().isNotEmpty)
            'observaciones': observaciones.trim(),
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<ReproductionEventEntity>> getPartos() async {
    try {
      final response = await _client.get(ApiConstants.partos);
      if (response.data is List) {
        return (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map((m) {
          final fechaParto = DateTime.tryParse(m['fecha_parto']?.toString() ?? '') ??
              DateTime.now();
          return ReproductionEventEntity(
            uuid: m['id']?.toString(),
            porcinoId: 0,
            hembraUuid: m['hembra_id']?.toString(),
            hembraArete: m['hembra_arete']?.toString() ?? 'CERDA',
            corralMaternidadCodigo: m['corral_maternidad_codigo']?.toString(),
            fecha: fechaParto,
            nacidosVivos: (m['nacidos_vivos'] as num?)?.toInt() ?? 0,
            nacidosMuertos: (m['nacidos_muertos'] as num?)?.toInt() ?? 0,
            momias: (m['momias'] as num?)?.toInt() ?? 0,
            pesoTotalCamadaKg:
                (m['peso_camada_total_kg'] as num?)?.toDouble() ?? 0.0,
            numeroParto: (m['numero_parto'] as num?)?.toInt() ?? 1,
            observaciones: m['observaciones']?.toString(),
          );
        }).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<ReproductionEventEntity> registrarParto({
    required int porcinoId,
    String? hembraUuid,
    String? corralMaternidadUuid,
    required DateTime fecha,
    required int nacidosVivos,
    required int nacidosMuertos,
    required int momias,
    required double pesoTotalCamadaKg,
    int numeroParto = 1,
    String? observaciones,
  }) async {
    try {
      final resolvedHembraUuid = hembraUuid ?? PorcinoModel.resolveUuid(porcinoId);
      final resolvedCorralUuid =
          corralMaternidadUuid ?? PorcinoModel.resolveCorralUuid(porcinoId);
      final payload = <String, dynamic>{
        'hembra_id': ?resolvedHembraUuid,
        'corral_maternidad_id': ?resolvedCorralUuid,
        'fecha_parto': fecha.toIso8601String(),
        'numero_parto': numeroParto,
        'nacidos_vivos': nacidosVivos,
        'nacidos_muertos': nacidosMuertos,
        'momias': momias,
        'peso_camada_total_kg': pesoTotalCamadaKg,
        if (observaciones != null && observaciones.trim().isNotEmpty)
          'observaciones': observaciones.trim(),
      };

      final response = await _client.post(
        ApiConstants.partos,
        data: payload,
      );

      final data = response.data;
      int id = 1;
      String? uuidStr;
      if (data is Map<String, dynamic> && data['id'] != null) {
        final rawId = data['id'];
        if (rawId is int) {
          id = rawId;
        } else {
          uuidStr = rawId.toString();
          final idStr = uuidStr.replaceAll('-', '');
          id = int.tryParse(idStr.length >= 8 ? idStr.substring(0, 8) : idStr, radix: 16) ??
              uuidStr.hashCode.abs();
        }
      }

      return ReproductionEventEntity(
        id: id,
        uuid: uuidStr,
        porcinoId: porcinoId,
        hembraUuid: resolvedHembraUuid,
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

  @override
  Future<List<WeaningEventEntity>> getDestetes() async {
    try {
      final response = await _client.get(ApiConstants.destetes);
      if (response.data is List) {
        return (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map((m) {
          final fechaDest = DateTime.tryParse(m['fecha_destete']?.toString() ?? '') ??
              DateTime.now();
          return WeaningEventEntity(
            id: m['id']?.toString() ?? '',
            hembraUuid: m['hembra_id']?.toString() ?? '',
            hembraArete: m['hembra_arete']?.toString() ?? 'CERDA',
            corralDestinoCodigo: m['corral_destino_codigo']?.toString(),
            fechaDestete: fechaDest,
            lechonesDestetados: (m['lechones_destetados'] as num?)?.toInt() ?? 0,
            pesoTotalKg: (m['peso_total_kg'] as num?)?.toDouble() ?? 0.0,
            diasLactancia: (m['dias_lactancia'] as num?)?.toInt() ?? 21,
            observaciones: m['observaciones']?.toString(),
          );
        }).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<WeaningEventEntity> registrarDestete({
    required int porcinoId,
    String? hembraUuid,
    required String hembraArete,
    String? corralDestinoUuid,
    required DateTime fechaDestete,
    required int lechonesDestetados,
    required double pesoTotalKg,
    int diasLactancia = 21,
    String? observaciones,
  }) async {
    try {
      final resolvedHembraUuid = hembraUuid ?? PorcinoModel.resolveUuid(porcinoId);
      final payload = <String, dynamic>{
        'hembra_id': ?resolvedHembraUuid,
        'corral_destino_id': ?corralDestinoUuid,
        'fecha_destete': fechaDestete.toIso8601String().split('T').first,
        'lechones_destetados': lechonesDestetados,
        'peso_total_kg': pesoTotalKg,
        'dias_lactancia': diasLactancia,
        if (observaciones != null && observaciones.trim().isNotEmpty)
          'observaciones': observaciones.trim(),
      };

      final response = await _client.post(
        ApiConstants.destetes,
        data: payload,
      );

      final data = response.data;
      final idStr = (data is Map<String, dynamic> && data['id'] != null)
          ? data['id'].toString()
          : DateTime.now().millisecondsSinceEpoch.toString();

      return WeaningEventEntity(
        id: idStr,
        hembraUuid: resolvedHembraUuid ?? '',
        hembraArete: hembraArete,
        fechaDestete: fechaDestete,
        lechonesDestetados: lechonesDestetados,
        pesoTotalKg: pesoTotalKg,
        diasLactancia: diasLactancia,
        observaciones: observaciones,
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
