import '../../domain/entities/porcino_entity.dart';

class PorcinoModel extends PorcinoEntity {
  const PorcinoModel({
    required super.id,
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
    final double currentPeso = (json['peso_actual'] as num?)?.toDouble() ?? (json['peso'] as num?)?.toDouble() ?? 82.5;
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

    return PorcinoModel(
      id: json['id'] as int? ?? 1,
      codigo: json['codigo'] as String? ?? 'POR-001',
      raza: json['raza'] as String? ?? 'Landrace',
      sexo: json['sexo'] as String? ?? 'Hembra',
      fechaNacimiento: DateTime.tryParse(json['fecha_nacimiento']?.toString() ?? '') ??
          DateTime.now().subtract(const Duration(days: 140)),
      loteId: json['lote'] as int? ?? json['lote_id'] as int? ?? 1,
      loteNombre: json['lote_nombre'] as String? ?? 'Lote Ceba 03',
      pesoActual: currentPeso,
      estadoSanitario: json['estado_sanitario'] as String? ?? 'Sano',
      fase: json['fase'] as String? ?? 'Ceba',
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
      'id': id,
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
