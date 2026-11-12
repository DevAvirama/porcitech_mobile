import '../../domain/entities/porcino_entity.dart';

class LoteModel extends LoteEntity {
  static final Map<int, String> _uuidRegistry = <int, String>{};

  static String? resolveUuid(int id) => _uuidRegistry[id];

  static void registerUuid(int id, String? uuid) {
    if (uuid != null && uuid.isNotEmpty) {
      _uuidRegistry[id] = uuid;
    }
  }

  const LoteModel({
    required super.id,
    super.uuid,
    required super.codigo,
    required super.nombre,
    required super.fase,
    required super.cantidadPorcinos,
    super.capacidadMaxima = 25,
    required super.pesoPromedio,
    required super.galpon,
    super.activo = true,
  });

  factory LoteModel.fromJson(Map<String, dynamic> json) {
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
    registerUuid(parsedId, rawUuid);

    final codigo = json['codigo'] as String? ?? 'COR-01';
    final descripcion = json['descripcion'] as String? ??
        json['nombre'] as String? ??
        json['ubicacion_galpon'] as String? ??
        codigo;

    return LoteModel(
      id: parsedId,
      uuid: rawUuid,
      codigo: codigo,
      nombre: descripcion,
      fase: json['fase'] as String? ?? json['tipo_etapa'] as String? ?? 'ceba',
      cantidadPorcinos: json['ocupacion_actual'] as int? ??
          json['cantidad_porcinos'] as int? ??
          json['cantidad'] as int? ??
          0,
      capacidadMaxima: json['capacidad_maxima'] as int? ?? 25,
      pesoPromedio: (json['peso_promedio_kg'] as num?)?.toDouble() ??
          (json['peso_promedio'] as num?)?.toDouble() ??
          0.0,
      galpon: descripcion,
      activo: json['activo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': uuid ?? id,
      'uuid': uuid,
      'codigo': codigo,
      'descripcion': nombre,
      'nombre': nombre,
      'fase': fase,
      'ocupacion_actual': cantidadPorcinos,
      'cantidad_porcinos': cantidadPorcinos,
      'capacidad_maxima': capacidadMaxima,
      'peso_promedio': pesoPromedio,
      'galpon': galpon,
      'activo': activo,
    };
  }
}
