import '../../domain/entities/porcino_entity.dart';

class PorcinoModel extends PorcinoEntity {
  /// Registro en memoria que asocia el ID entero de la UI con el UUID real de PostgreSQL.
  static final Map<int, String> _uuidRegistry = <int, String>{};
  static final Map<int, String> _corralUuidRegistry = <int, String>{};

  static String? resolveUuid(int id) => _uuidRegistry[id];
  static String? resolveCorralUuid(int id) => _corralUuidRegistry[id];

  static void registerUuids({required int id, String? uuid, String? corralUuid}) {
    if (uuid != null && uuid.isNotEmpty) {
      _uuidRegistry[id] = uuid;
    }
    if (corralUuid != null && corralUuid.isNotEmpty) {
      _corralUuidRegistry[id] = corralUuid;
    }
  }

  const PorcinoModel({
    required super.id,
    super.uuid,
    super.corralUuid,
    required super.codigo,
    super.codigoQr,
    super.nombreAlias,
    required super.raza,
    required super.sexo,
    required super.fechaNacimiento,
    required super.loteId,
    required super.loteNombre,
    required super.pesoActual,
    required super.estadoSanitario,
    required super.fase,
    required super.gdpActualGramoDia,
    required super.diasEnFase,
    super.medicacionActiva,
    super.diasRetiroRestantes = 0,
    super.fechaFinRetiro,
    super.curvaCrecimiento = const [],
  });

  static String _formatFase(String rawFase) {
    final lower = rawFase.trim().toLowerCase();
    switch (lower) {
      case 'ceba':
      case 'engorde':
        return 'Ceba';
      case 'gestacion':
      case 'gestación':
        return 'Gestación';
      case 'maternidad':
      case 'lactante':
        return 'Maternidad';
      case 'precebo':
      case 'destete':
        return 'Precebo';
      case 'levante':
        return 'Levante';
      case 'cuarentena':
        return 'Cuarentena';
      case 'enfermo':
        return 'Enfermo';
      default:
        if (rawFase.isEmpty) return 'Ceba';
        return rawFase[0].toUpperCase() + rawFase.substring(1);
    }
  }

  static String _formatSexo(String rawSexo) {
    final lower = rawSexo.trim().toLowerCase();
    if (lower.contains('castrado')) return 'Macho Castrado';
    if (lower.contains('macho')) return 'Macho';
    return 'Hembra';
  }

  factory PorcinoModel.fromJson(Map<String, dynamic> json) {
    final rawCurva = json['curva_crecimiento'] as List<dynamic>? ?? [];
    final curva = rawCurva.map((item) {
      final m = item as Map<String, dynamic>;
      return PesoHistoricoItem(
        fecha: DateTime.tryParse(
              m['tiempo']?.toString() ?? m['fecha']?.toString() ?? '',
            ) ??
            DateTime.now(),
        pesoKg: (m['peso_kg'] as num?)?.toDouble() ??
            (m['peso'] as num?)?.toDouble() ??
            0.0,
        metodo: m['metodo']?.toString() ?? 'manual',
      );
    }).toList();

    final double currentPeso = (json['peso_actual_kg'] as num?)?.toDouble() ??
        (json['peso_actual'] as num?)?.toDouble() ??
        (json['peso'] as num?)?.toDouble() ??
        0.0;

    final List<PesoHistoricoItem> curvaFinal = curva.isNotEmpty
        ? curva
        : (currentPeso > 0
            ? [
                PesoHistoricoItem(
                  fecha: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
                      DateTime.now(),
                  pesoKg: currentPeso,
                  metodo: 'manual',
                ),
              ]
            : const []);

    int parsedId = 1;
    String? rawUuid = json['uuid']?.toString().trim();
    final rawId = json['id'];
    if (rawId is int) {
      parsedId = rawId;
    } else if (rawId != null) {
      final idStr = rawId.toString().trim();
      final asInt = int.tryParse(idStr);
      if (asInt != null) {
        parsedId = asInt;
      } else {
        rawUuid = idStr;
        final hexClean = idStr.replaceAll('-', '');
        if (hexClean.length >= 8) {
          parsedId =
              int.tryParse(hexClean.substring(0, 8), radix: 16) ?? idStr.hashCode.abs();
        } else if (idStr.isNotEmpty) {
          parsedId = idStr.hashCode.abs();
        }
      }
    }

    final rawCorralId = (json['corral_id'] ?? json['corralUuid'])?.toString().trim();
    registerUuids(id: parsedId, uuid: rawUuid, corralUuid: rawCorralId);

    final rawEstado = json['estado']?.toString() ?? '';
    final estadoSanitario = json['estado_sanitario'] as String? ??
        (rawEstado.toLowerCase() == 'enfermo'
            ? 'Enfermo'
            : (rawEstado.toLowerCase() == 'cuarentena' ? 'En Tratamiento' : 'Sano'));

    final fechaNac = DateTime.tryParse(json['fecha_nacimiento']?.toString() ?? '') ??
        DateTime.now().subtract(const Duration(days: 90));
    final int edadDias = DateTime.now().difference(fechaNac).inDays.clamp(1, 3650);
    final double gdpCalculada = (json['gdp_actual'] as num?)?.toDouble() ??
        (currentPeso > 1.5 ? ((currentPeso - 1.4) * 1000.0 / edadDias).clamp(150.0, 1200.0) : 0.0);

    final codigoArete =
        json['codigo_arete'] as String? ?? json['codigo'] as String? ?? 'POR-001';

    return PorcinoModel(
      id: parsedId,
      uuid: rawUuid,
      corralUuid: rawCorralId,
      codigo: codigoArete,
      codigoQr: json['codigo_qr'] as String? ?? 'QR-$codigoArete',
      nombreAlias: json['nombre_alias'] as String?,
      raza: json['raza'] as String? ?? 'Landrace',
      sexo: _formatSexo(json['sexo']?.toString() ?? 'Hembra'),
      fechaNacimiento: fechaNac,
      loteId: json['lote'] is int
          ? json['lote'] as int
          : (json['lote_id'] is int ? json['lote_id'] as int : 1),
      loteNombre: json['corral_codigo'] as String? ??
          json['lote_nombre'] as String? ??
          'Sin corral asignado',
      pesoActual: currentPeso,
      estadoSanitario: estadoSanitario,
      fase: _formatFase(json['fase']?.toString() ?? rawEstado),
      gdpActualGramoDia: gdpCalculada,
      diasEnFase: json['dias_en_ceba'] as int? ??
          json['dias_en_fase'] as int? ??
          edadDias.clamp(1, 180),
      medicacionActiva: json['medicacion_activa'] as String?,
      diasRetiroRestantes: json['dias_retiro'] as int? ?? 0,
      fechaFinRetiro: json['fecha_fin_retiro'] != null
          ? DateTime.tryParse(json['fecha_fin_retiro'].toString())
          : null,
      curvaCrecimiento: curvaFinal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': uuid ?? id,
      'uuid': uuid,
      'corral_id': corralUuid,
      'codigo_arete': codigo,
      'codigo': codigo,
      'codigo_qr': codigoQr,
      'nombre_alias': nombreAlias,
      'raza': raza,
      'sexo': sexo,
      'fecha_nacimiento': fechaNacimiento.toIso8601String().split('T').first,
      'lote': loteId,
      'lote_nombre': loteNombre,
      'corral_codigo': loteNombre,
      'peso_actual_kg': pesoActual,
      'peso_actual': pesoActual,
      'estado_sanitario': estadoSanitario,
      'fase': fase,
      'estado': fase.toLowerCase(),
      'gdp_actual': gdpActualGramoDia,
      'dias_en_ceba': diasEnFase,
      'medicacion_activa': medicacionActiva,
      'dias_retiro': diasRetiroRestantes,
      'fecha_fin_retiro': fechaFinRetiro?.toIso8601String(),
      'curva_crecimiento': curvaCrecimiento
          .map((c) => {
                'fecha': c.fecha.toIso8601String(),
                'peso_kg': c.pesoKg,
                'metodo': c.metodo,
              })
          .toList(),
    };
  }
}
