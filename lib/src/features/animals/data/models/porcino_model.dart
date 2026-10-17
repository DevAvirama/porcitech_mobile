import '../../domain/entities/porcino_entity.dart';

class PorcinoModel extends PorcinoEntity {
  /// Registro en memoria que asocia el ID entero de la UI con el UUID real de PostgreSQL.
  static final Map<int, String> _uuidRegistry = <int, String>{};
  static final Map<int, String> _corralUuidRegistry = <int, String>{};

  static String? resolveUuid(int id) => _uuidRegistry[id];
  static String? resolveCorralUuid(int id) => _corralUuidRegistry[id];

  const PorcinoModel({
    required super.id,
    super.uuid,
    required super.codigo,
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

  factory PorcinoModel.fromJson(Map<String, dynamic> json) {
    final rawCurva = json['curva_crecimiento'] as List<dynamic>? ?? [];
    final curva = rawCurva.map((item) {
      final m = item as Map<String, dynamic>;
      return PesoHistoricoItem(
        fecha: DateTime.tryParse(m['fecha']?.toString() ?? '') ?? DateTime.now(),
        pesoKg: (m['peso'] as num?)?.toDouble() ?? 0.0,
        metodo: m['metodo']?.toString() ?? 'manual',
      );
    }).toList();

    // Si no viene curva desde FastAPI, generamos una curva predeterminada coherente para fl_chart
    final double currentPeso = (json['peso_actual_kg'] as num?)?.toDouble() ??
        (json['peso_actual'] as num?)?.toDouble() ??
        (json['peso'] as num?)?.toDouble() ??
        82.5;
    final List<PesoHistoricoItem> curvaFinal = curva.isNotEmpty
        ? curva
        : [
            PesoHistoricoItem(
              fecha: DateTime.now().subtract(const Duration(days: 42)),
              pesoKg: (currentPeso - 32.0).clamp(10.0, 300.0),
              metodo: 'manual',
            ),
            PesoHistoricoItem(
              fecha: DateTime.now().subtract(const Duration(days: 28)),
              pesoKg: (currentPeso - 21.0).clamp(15.0, 300.0),
              metodo: 'manual',
            ),
            PesoHistoricoItem(
              fecha: DateTime.now().subtract(const Duration(days: 14)),
              pesoKg: (currentPeso - 11.2).clamp(20.0, 300.0),
              metodo: 'ia',
            ),
            PesoHistoricoItem(
              fecha: DateTime.now(),
              pesoKg: currentPeso,
              metodo: 'manual',
            ),
          ];

    int parsedId = 1;
    String? rawUuid;
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
          parsedId = int.tryParse(hexClean.substring(0, 8), radix: 16) ?? idStr.hashCode.abs();
        } else if (idStr.isNotEmpty) {
          parsedId = idStr.hashCode.abs();
        }
        _uuidRegistry[parsedId] = idStr;
      }
    }

    final rawCorralId = json['corral_id']?.toString().trim();
    if (rawCorralId != null && rawCorralId.isNotEmpty) {
      _corralUuidRegistry[parsedId] = rawCorralId;
    }

    return PorcinoModel(
      id: parsedId,
      uuid: rawUuid,
      codigo: json['codigo_arete'] as String? ?? json['codigo'] as String? ?? 'POR-001',
      raza: json['raza'] as String? ?? 'Landrace',
      sexo: json['sexo'] as String? ?? 'Hembra',
      fechaNacimiento: DateTime.tryParse(json['fecha_nacimiento']?.toString() ?? '') ??
          DateTime.now().subtract(const Duration(days: 140)),
      loteId: json['lote'] is int ? json['lote'] as int : (json['lote_id'] is int ? json['lote_id'] as int : 1),
      loteNombre: json['corral_codigo'] as String? ??
          json['lote_nombre'] as String? ??
          'Lote Ceba 03',
      pesoActual: currentPeso,
      estadoSanitario: json['estado_sanitario'] as String? ??
          (json['estado'] == 'enfermo' ? 'Enfermo' : 'Sano'),
      fase: json['estado'] as String? ?? json['fase'] as String? ?? 'Ceba',
      gdpActualGramoDia: (json['gdp_actual'] as num?)?.toDouble() ?? 820.0,
      diasEnFase: json['dias_en_ceba'] as int? ?? json['dias_en_fase'] as int? ?? 65,
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
      'codigo_arete': codigo,
      'codigo': codigo,
      'raza': raza,
      'sexo': sexo,
      'fecha_nacimiento': fechaNacimiento.toIso8601String().split('T').first,
      'lote': loteId,
      'lote_nombre': loteNombre,
      'peso_actual': pesoActual,
      'estado_sanitario': estadoSanitario,
      'fase': fase,
      'gdp_actual': gdpActualGramoDia,
      'dias_en_ceba': diasEnFase,
      'medicacion_activa': medicacionActiva,
      'dias_retiro': diasRetiroRestantes,
      'fecha_fin_retiro': fechaFinRetiro?.toIso8601String(),
    };
  }
}
