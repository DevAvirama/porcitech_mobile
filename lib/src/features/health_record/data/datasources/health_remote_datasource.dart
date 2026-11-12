import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../animals/data/models/porcino_model.dart';
import '../../domain/entities/health_event_entity.dart';

abstract class HealthRemoteDataSource {
  Future<HealthEventEntity> registrarEventoSanitario({
    required int porcinoId,
    String? animalUuid,
    String? corralUuid,
    String? medicamentoUuid,
    required String tipo,
    required String medicamento,
    required String loteBiologico,
    required double dosisMl,
    String unidadDosis = 'ml',
    required String viaAplicacion,
    required DateTime fecha,
    required int diasRetiro,
    String? diagnostico,
    String? observaciones,
  });

  Future<List<HealthEventEntity>> getTratamientos({String? animalUuid});
  Future<List<WithdrawalAlertItem>> getAlertasRetiro();
  Future<List<BiosecurityProtocolItem>> getProtocolosBioseguridad();
  Future<bool> toggleProtocoloBioseguridad({
    required String protocoloId,
    required bool cumplido,
    String? observaciones,
  });
}

class HealthRemoteDataSourceImpl implements HealthRemoteDataSource {
  final DioClient _client;

  HealthRemoteDataSourceImpl(this._client);

  static String normalizeTipoEvento(String rawTipo) {
    final t = rawTipo.trim().toLowerCase();
    if (t.contains('vacun')) return 'vacuna';
    if (t.contains('despara')) return 'desparasitacion';
    return 'tratamiento';
  }

  @override
  Future<HealthEventEntity> registrarEventoSanitario({
    required int porcinoId,
    String? animalUuid,
    String? corralUuid,
    String? medicamentoUuid,
    required String tipo,
    required String medicamento,
    required String loteBiologico,
    required double dosisMl,
    String unidadDosis = 'ml',
    required String viaAplicacion,
    required DateTime fecha,
    required int diasRetiro,
    String? diagnostico,
    String? observaciones,
  }) async {
    try {
      final fechaFin = fecha.add(Duration(days: diasRetiro));
      final resolvedAnimalUuid = animalUuid ?? PorcinoModel.resolveUuid(porcinoId);
      final resolvedCorralUuid = corralUuid ?? PorcinoModel.resolveCorralUuid(porcinoId);
      final tipoEvento = normalizeTipoEvento(tipo);

      final responseEvento = await _client.post(
        ApiConstants.eventosSanitarios,
        data: {
          'animal_id': ?resolvedAnimalUuid,
          'corral_id': ?resolvedCorralUuid,
          'medicamento_id': ?medicamentoUuid,
          'tipo_evento': tipoEvento,
          'producto_nombre': medicamento,
          'lote_biologico': loteBiologico,
          'dosis': dosisMl,
          'unidad_dosis': unidadDosis,
          'via_administracion': viaAplicacion,
          'diagnostico': diagnostico != null && diagnostico.trim().isNotEmpty
              ? diagnostico.trim()
              : 'Aplicación de $medicamento (Lote $loteBiologico)',
          'fecha_tratamiento': fecha.toIso8601String(),
          'tiempo_retiro_dias': diasRetiro,
          if (observaciones != null && observaciones.trim().isNotEmpty)
            'observaciones': observaciones.trim(),
        },
      );

      final data = responseEvento.data;
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

      return HealthEventEntity(
        id: id,
        uuid: uuidStr,
        porcinoId: porcinoId,
        animalUuid: resolvedAnimalUuid,
        tipo: tipoEvento,
        medicamento: medicamento,
        loteBiologico: loteBiologico,
        dosisMl: dosisMl,
        unidadDosis: unidadDosis,
        viaAplicacion: viaAplicacion,
        fecha: fecha,
        diasRetiro: diasRetiro,
        fechaFinRetiro: fechaFin,
        diagnostico: diagnostico,
        observaciones: observaciones,
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<HealthEventEntity>> getTratamientos({String? animalUuid}) async {
    try {
      final queryParams = <String, dynamic>{'limite': 50};
      if (animalUuid != null && animalUuid.isNotEmpty) {
        queryParams['animal_id'] = animalUuid;
      }
      final response = await _client.get(
        ApiConstants.eventosSanitarios,
        queryParameters: queryParams,
      );
      if (response.data is List) {
        return (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map((m) {
          final fecha = DateTime.tryParse(m['fecha_tratamiento']?.toString() ?? '') ??
              DateTime.now();
          final diasRetiro = (m['tiempo_retiro_dias'] as num?)?.toInt() ?? 0;
          return HealthEventEntity(
            uuid: m['id']?.toString(),
            porcinoId: 0,
            animalUuid: m['animal_id']?.toString(),
            animalArete: m['animal_arete']?.toString(),
            corralCodigo: m['corral_codigo']?.toString(),
            tipo: m['tipo_evento']?.toString() ?? 'tratamiento',
            medicamento: m['producto_nombre']?.toString() ?? '',
            loteBiologico: m['lote_biologico']?.toString() ?? 'N/A',
            dosisMl: (m['dosis'] as num?)?.toDouble() ?? 0.0,
            unidadDosis: m['unidad_dosis']?.toString() ?? 'ml',
            viaAplicacion: m['via_administracion']?.toString() ?? 'Intramuscular',
            fecha: fecha,
            diasRetiro: diasRetiro,
            fechaFinRetiro: fecha.add(Duration(days: diasRetiro)),
            diagnostico: m['diagnostico']?.toString(),
            observaciones: m['observaciones']?.toString(),
            veterinarioNombre: m['veterinario_nombre']?.toString(),
          );
        }).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<WithdrawalAlertItem>> getAlertasRetiro() async {
    try {
      final response = await _client.get(ApiConstants.alertasRetiro);
      if (response.data is List) {
        return (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map((m) {
          final fechaTrat = DateTime.tryParse(m['fecha_tratamiento']?.toString() ?? '') ??
              DateTime.now();
          final fechaFin = DateTime.tryParse(m['fecha_fin_retiro']?.toString() ?? '') ??
              DateTime.now();
          return WithdrawalAlertItem(
            animalUuid: m['animal_id']?.toString() ?? '',
            animalArete: m['animal_arete']?.toString() ?? 'POR',
            corralCodigo: m['corral_codigo']?.toString(),
            productoNombre: m['producto_nombre']?.toString() ?? '',
            fechaTratamiento: fechaTrat,
            tiempoRetiroDias: (m['tiempo_retiro_dias'] as num?)?.toInt() ?? 0,
            fechaFinRetiro: fechaFin,
            diasRestantes: (m['dias_restantes'] as num?)?.toInt() ?? 0,
          );
        }).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<BiosecurityProtocolItem>> getProtocolosBioseguridad() async {
    try {
      final protoRes = await _client.get(
        ApiConstants.bioseguridadProtocolos,
        queryParameters: const {'activo': 'true'},
      );
      final Map<String, Map<String, dynamic>> execMap = {};
      try {
        final execRes = await _client.get(ApiConstants.bioseguridadEjecuciones);
        if (execRes.data is List) {
          for (final e in (execRes.data as List)) {
            if (e is Map<String, dynamic> && e['protocolo_id'] != null) {
              execMap[e['protocolo_id'].toString()] = e;
            }
          }
        }
      } catch (_) {}

      if (protoRes.data is List) {
        return (protoRes.data as List)
            .whereType<Map<String, dynamic>>()
            .map((p) {
          final idStr = p['id']?.toString() ?? '';
          final exec = execMap[idStr];
          return BiosecurityProtocolItem(
            id: idStr,
            codigo: p['codigo']?.toString() ?? 'BIO',
            tipoProtocolo: p['tipo_protocolo']?.toString() ?? 'operacional',
            tarea: p['tarea']?.toString() ?? '',
            descripcion: p['descripcion']?.toString() ?? '',
            frecuencia: p['frecuencia']?.toString() ?? 'Diaria',
            cumplidoHoy: exec != null ? (exec['cumplido'] == true) : false,
            observacionesHoy: exec?['observaciones']?.toString(),
          );
        }).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<bool> toggleProtocoloBioseguridad({
    required String protocoloId,
    required bool cumplido,
    String? observaciones,
  }) async {
    try {
      await _client.post(
        ApiConstants.bioseguridadEjecuciones,
        data: {
          'protocolo_id': protocoloId,
          'cumplido': cumplido,
          if (observaciones != null && observaciones.trim().isNotEmpty)
            'observaciones': observaciones.trim(),
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
