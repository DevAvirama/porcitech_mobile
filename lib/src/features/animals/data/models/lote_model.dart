import '../../domain/entities/porcino_entity.dart';

class LoteModel extends LoteEntity {
  const LoteModel({
    required super.id,
    required super.codigo,
    required super.nombre,
    required super.fase,
    required super.cantidadPorcinos,
    required super.pesoPromedio,
    required super.galpon,
  });

  factory LoteModel.fromJson(Map<String, dynamic> json) {
    return LoteModel(
      id: json['id'] as int? ?? 1,
      codigo: json['codigo'] as String? ?? 'LOT-01',
      nombre: json['nombre'] as String? ?? 'Lote Principal',
      fase: json['fase'] as String? ?? 'Ceba',
      cantidadPorcinos: json['cantidad_porcinos'] as int? ?? json['cantidad'] as int? ?? 45,
      pesoPromedio: (json['peso_promedio'] as num?)?.toDouble() ?? 81.2,
      galpon: json['galpon'] as String? ?? 'Galpón 2 - Corral A',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo': codigo,
      'nombre': nombre,
      'fase': fase,
      'cantidad_porcinos': cantidadPorcinos,
      'peso_promedio': pesoPromedio,
      'galpon': galpon,
    };
  }
}
