import 'package:equatable/equatable.dart';

class FeedingRationEntity extends Equatable {
  final String id;
  final String corralUuid;
  final String corralCodigo;
  final String alimentoItemId;
  final String alimentoNombre;
  final String faseAlimentacion; // 'Pre-iniciador' | 'Iniciador' | 'Levante' | 'Ceba'
  final double cantidadKg;
  final double costoTotal;
  final DateTime fechaSuministro;
  final String? operarioNombre;
  final String? observaciones;

  const FeedingRationEntity({
    required this.id,
    required this.corralUuid,
    required this.corralCodigo,
    required this.alimentoItemId,
    required this.alimentoNombre,
    required this.faseAlimentacion,
    required this.cantidadKg,
    this.costoTotal = 0.0,
    required this.fechaSuministro,
    this.operarioNombre,
    this.observaciones,
  });

  @override
  List<Object?> get props => [
        id,
        corralUuid,
        corralCodigo,
        alimentoItemId,
        alimentoNombre,
        faseAlimentacion,
        cantidadKg,
        costoTotal,
        fechaSuministro,
        operarioNombre,
        observaciones,
      ];
}

class InventoryItemEntity extends Equatable {
  final String id;
  final String categoriaCodigo;
  final String categoriaNombre;
  final String codigoSku;
  final String nombre;
  final String unidadMedida;
  final double stockActual;
  final double stockMinimo;
  final double costoUnitario;
  final String ubicacionBodega;

  const InventoryItemEntity({
    required this.id,
    required this.categoriaCodigo,
    required this.categoriaNombre,
    required this.codigoSku,
    required this.nombre,
    required this.unidadMedida,
    required this.stockActual,
    required this.stockMinimo,
    this.costoUnitario = 0.0,
    this.ubicacionBodega = 'Bodega Principal',
  });

  bool get esBajoStock => stockActual <= stockMinimo;

  bool get esAlimento {
    final c = '$categoriaCodigo $categoriaNombre $nombre'.toLowerCase();
    return c.contains('alim') ||
        c.contains('concen') ||
        c.contains('pre-ini') ||
        c.contains('iniciad') ||
        c.contains('levan') ||
        c.contains('ceba') ||
        c.contains('bulto');
  }

  @override
  List<Object?> get props => [
        id,
        categoriaCodigo,
        categoriaNombre,
        codigoSku,
        nombre,
        unidadMedida,
        stockActual,
        stockMinimo,
        costoUnitario,
        ubicacionBodega,
      ];
}
