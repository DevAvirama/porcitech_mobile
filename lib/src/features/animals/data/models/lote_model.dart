import '../../domain/entities/porcino_entity.dart';

class LoteModel extends LoteEntity {
  static final Map<int, String> _uuidRegistry = <int, String>{};

  static String? resolveUuid(int id) => _uuidRegistry[id];

  const LoteModel({
    required super.id,
    super.uuid,
    required super.codigo,
    required super.nombre,
    required super.fase,
    required super.cantidadPorcinos,
    required super.pesoPromedio,
    required super.galpon,
  });

  factory LoteModel.fromJson(Map<String, dynamic> json) {
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

    return LoteModel(
      id: parsedId,
      uuid: rawUuid,
      codigo: json['codigo'] as String? ?? 'LOT-01',
      nombre: json['nombre'] as String? ?? 'Lote Principal',
      fase: json['tipo_etapa'] as String? ?? json['fase'] as String? ?? 'Ceba',
      cantidadPorcinos: json['ocupacion_actual'] as int? ??
          json['cantidad_porcinos'] as int? ??
          json['cantidad'] as int? ??
          0,
      pesoPromedio: (json['peso_promedio_kg'] as num?)?.toDouble() ??
          (json['peso_promedio'] as num?)?.toDouble() ??
          81.2,
      galpon: json['ubicacion_galpon'] as String? ??
          json['galpon'] as String? ??
          'Galpón Principal',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': uuid ?? id,
      'uuid': uuid,
      'codigo': codigo,
      'nombre': nombre,
      'fase': fase,
      'cantidad_porcinos': cantidadPorcinos,
      'peso_promedio': pesoPromedio,
      'galpon': galpon,
    };
  }
}
