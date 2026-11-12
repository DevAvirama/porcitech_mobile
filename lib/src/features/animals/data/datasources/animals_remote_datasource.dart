import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/porcino_entity.dart';
import '../models/lote_model.dart';
import '../models/porcino_model.dart';

abstract class AnimalsRemoteDataSource {
  Future<List<PorcinoModel>> getPorcinos({String? query, String? filter});
  Future<PorcinoModel> getPorcinoById(int id, {String? uuid});
  Future<PorcinoModel> getPorcinoByQr(String codigo);
  Future<List<PesoHistoricoItem>> getHistorialPesajes(int id, {String? uuid});
  Future<PorcinoModel> createPorcino({
    required String codigo,
    String? nombreAlias,
    required String raza,
    required String sexo,
    required DateTime fechaNacimiento,
    required int loteId,
    String? corralUuid,
    String estado = 'levante',
    double pesoInicialKg = 0.0,
  });
  Future<List<LoteModel>> getLotes();
  Future<LoteModel> createLote({
    required String codigo,
    required String nombre,
    required String fase,
    required String galpon,
    int capacidadMaxima = 25,
  });
}

class AnimalsRemoteDataSourceImpl implements AnimalsRemoteDataSource {
  final DioClient _client;

  AnimalsRemoteDataSourceImpl(this._client);

  String _normalizeFaseForBackend(String rawFase) {
    final f = rawFase.trim().toLowerCase();
    if (f.contains('gesta')) return 'gestacion';
    if (f.contains('mater') || f.contains('lacta')) return 'maternidad';
    if (f.contains('prece') || f.contains('deste')) return 'precebo';
    if (f.contains('levan')) return 'levante';
    if (f.contains('cuaren')) return 'cuarentena';
    if (f.contains('enfer')) return 'enfermo';
    return 'ceba';
  }

  @override
  Future<List<PorcinoModel>> getPorcinos({String? query, String? filter}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (query != null && query.trim().isNotEmpty) {
        queryParams['search'] = query.trim();
      }
      if (filter != null && filter != 'Todos') {
        queryParams['estado'] = _normalizeFaseForBackend(filter);
      }

      final response = await _client.get(
        ApiConstants.porcinos,
        queryParameters: queryParams,
      );

      // Consultar alertas de retiro activas para enriquecer la ficha sanitaria
      Map<String, Map<String, dynamic>> withdrawalByAnimalUuid = {};
      try {
        final alertsRes = await _client.get(ApiConstants.alertasRetiro);
        if (alertsRes.data is List) {
          for (final item in (alertsRes.data as List)) {
            if (item is Map<String, dynamic> && item['animal_id'] != null) {
              withdrawalByAnimalUuid[item['animal_id'].toString()] = item;
            }
          }
        }
      } catch (_) {
        // Ignorar fallo secundario si el endpoint de alertas no responde
      }

      final data = response.data;
      List<dynamic> rawList = [];
      if (data is List) {
        rawList = data;
      } else if (data is Map<String, dynamic> && data['results'] is List) {
        rawList = data['results'] as List;
      }

      return rawList.map((e) {
        final map = Map<String, dynamic>.from(e as Map<String, dynamic>);
        final animalUuid = map['id']?.toString();
        if (animalUuid != null && withdrawalByAnimalUuid.containsKey(animalUuid)) {
          final alert = withdrawalByAnimalUuid[animalUuid]!;
          map['estado_sanitario'] = 'Retiro Farmacológico';
          map['medicacion_activa'] = alert['producto_nombre']?.toString();
          map['dias_retiro'] = (alert['dias_restantes'] as num?)?.toInt() ?? 0;
          map['fecha_fin_retiro'] = alert['fecha_fin_retiro']?.toString();
        }
        return PorcinoModel.fromJson(map);
      }).toList();
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<PorcinoModel> getPorcinoById(int id, {String? uuid}) async {
    try {
      final targetId = uuid ?? PorcinoModel.resolveUuid(id) ?? id;
      final response = await _client.get(ApiConstants.porcinoById(targetId));
      if (response.data is Map<String, dynamic>) {
        final map = Map<String, dynamic>.from(response.data as Map<String, dynamic>);
        final resolvedUuid = map['id']?.toString() ?? targetId.toString();
        final pesajes = await getHistorialPesajes(id, uuid: resolvedUuid);
        if (pesajes.isNotEmpty) {
          map['curva_crecimiento'] = pesajes
              .map((p) => {
                    'tiempo': p.fecha.toIso8601String(),
                    'peso_kg': p.pesoKg,
                    'metodo': p.metodo,
                  })
              .toList();
        }
        return PorcinoModel.fromJson(map);
      }
      throw const NotFoundException('Porcino no encontrado.');
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<PorcinoModel> getPorcinoByQr(String codigo) async {
    try {
      final response = await _client.get(ApiConstants.porcinoByQr(codigo));
      if (response.data is Map<String, dynamic>) {
        final map = Map<String, dynamic>.from(response.data as Map<String, dynamic>);
        final resolvedUuid = map['id']?.toString();
        if (resolvedUuid != null) {
          final pesajes = await getHistorialPesajes(0, uuid: resolvedUuid);
          if (pesajes.isNotEmpty) {
            map['curva_crecimiento'] = pesajes
                .map((p) => {
                      'tiempo': p.fecha.toIso8601String(),
                      'peso_kg': p.pesoKg,
                      'metodo': p.metodo,
                    })
                .toList();
          }
        }
        return PorcinoModel.fromJson(map);
      }
      throw const NotFoundException(
        'El código QR o arete no coincide con ningún porcino activo.',
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<PesoHistoricoItem>> getHistorialPesajes(int id, {String? uuid}) async {
    try {
      final targetId = uuid ?? PorcinoModel.resolveUuid(id);
      if (targetId == null || targetId.isEmpty) return [];

      final response = await _client.get(ApiConstants.pesajesPorAnimal(targetId));
      if (response.data is List) {
        final list = (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map(
              (m) => PesoHistoricoItem(
                fecha: DateTime.tryParse(
                      m['tiempo']?.toString() ?? m['fecha']?.toString() ?? '',
                    ) ??
                    DateTime.now(),
                pesoKg: (m['peso_kg'] as num?)?.toDouble() ??
                    (m['peso'] as num?)?.toDouble() ??
                    0.0,
                metodo: m['metodo']?.toString() ?? 'manual',
              ),
            )
            .toList();
        list.sort((a, b) => a.fecha.compareTo(b.fecha));
        return list;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<PorcinoModel> createPorcino({
    required String codigo,
    String? nombreAlias,
    required String raza,
    required String sexo,
    required DateTime fechaNacimiento,
    required int loteId,
    String? corralUuid,
    String estado = 'levante',
    double pesoInicialKg = 0.0,
  }) async {
    try {
      final resolvedCorralUuid = corralUuid ?? LoteModel.resolveUuid(loteId);
      final cleanArete = codigo.trim();
      final payload = <String, dynamic>{
        'codigo_arete': cleanArete,
        'codigo_qr': 'QR-$cleanArete',
        if (nombreAlias != null && nombreAlias.trim().isNotEmpty)
          'nombre_alias': nombreAlias.trim(),
        'raza': raza,
        'sexo': sexo.toLowerCase().contains('macho') ? 'macho' : 'hembra',
        'fecha_nacimiento': fechaNacimiento.toIso8601String().split('T').first,
        'estado': _normalizeFaseForBackend(estado),
        'corral_id': ?resolvedCorralUuid,
        'peso_actual_kg': pesoInicialKg,
      };

      final response = await _client.post(
        ApiConstants.porcinos,
        data: payload,
      );

      if (response.data is Map<String, dynamic>) {
        return PorcinoModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw const ServerException('Respuesta inválida al registrar porcino.');
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<LoteModel>> getLotes() async {
    try {
      final response = await _client.get(
        ApiConstants.lotes,
        queryParameters: const {'activo': 'true'},
      );
      final data = response.data;
      if (data is List) {
        return data
            .map((e) => LoteModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (data is Map<String, dynamic> && data['results'] is List) {
        return (data['results'] as List)
            .map((e) => LoteModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<LoteModel> createLote({
    required String codigo,
    required String nombre,
    required String fase,
    required String galpon,
    int capacidadMaxima = 25,
  }) async {
    try {
      final faseBackend = _normalizeFaseForBackend(fase);
      final descripcionCompleta =
          galpon.trim().isNotEmpty && nombre.trim().isNotEmpty
              ? '${nombre.trim()} • ${galpon.trim()}'
              : (nombre.trim().isNotEmpty ? nombre.trim() : galpon.trim());

      final response = await _client.post(
        ApiConstants.lotes,
        data: {
          'codigo': codigo.trim(),
          'descripcion': descripcionCompleta.isNotEmpty ? descripcionCompleta : codigo.trim(),
          'fase': faseBackend,
          'capacidad_maxima': capacidadMaxima,
          'activo': true,
        },
      );
      if (response.data is Map<String, dynamic>) {
        return LoteModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw const ServerException('Error al crear corral en FastAPI.');
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
