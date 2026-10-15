import 'package:equatable/equatable.dart';

class WeightRecordEntity extends Equatable {
  final int? id;
  final int porcinoId;
  final double peso;
  final DateTime fecha;
  final String tipo; // 'manual' | 'ia'
  final double? gdpCalculada;

  const WeightRecordEntity({
    this.id,
    required this.porcinoId,
    required this.peso,
    required this.fecha,
    required this.tipo,
    this.gdpCalculada,
  });

  @override
  List<Object?> get props => [id, porcinoId, peso, fecha, tipo, gdpCalculada];
}

class IaWeightEstimationResult extends Equatable {
  final int porcinoId;
  final double pesoEstimado;
  final String unidad;
  final String metodo;
  final DateTime fecha;
  final double? confianzaIa;

  const IaWeightEstimationResult({
    required this.porcinoId,
    required this.pesoEstimado,
    this.unidad = 'kg',
    this.metodo = 'ia',
    required this.fecha,
    this.confianzaIa,
  });

  @override
  List<Object?> get props => [
        porcinoId,
        pesoEstimado,
        unidad,
        metodo,
        fecha,
        confianzaIa,
      ];
}
