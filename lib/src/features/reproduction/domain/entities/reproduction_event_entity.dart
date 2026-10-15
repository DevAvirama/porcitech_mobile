import 'package:equatable/equatable.dart';

/// Entidad inmutable que modela el evento de parto de una hembra reproductora.
class ReproductionEventEntity extends Equatable {
  final int? id;
  final int porcinoId; // ID de la madre (Cerda)
  final DateTime fecha;
  final int nacidosVivos;
  final int nacidosMuertos;
  final int momias;
  final double pesoTotalCamadaKg;
  final int numeroParto;
  final String? observaciones;

  const ReproductionEventEntity({
    this.id,
    required this.porcinoId,
    required this.fecha,
    required this.nacidosVivos,
    required this.nacidosMuertos,
    required this.momias,
    required this.pesoTotalCamadaKg,
    this.numeroParto = 1,
    this.observaciones,
  });

  int get totalNacidos => nacidosVivos + nacidosMuertos + momias;
  double get pesoPromedioLechon => nacidosVivos > 0 ? (pesoTotalCamadaKg / nacidosVivos) : 0.0;

  @override
  List<Object?> get props => [
        id,
        porcinoId,
        fecha,
        nacidosVivos,
        nacidosMuertos,
        momias,
        pesoTotalCamadaKg,
        numeroParto,
        observaciones,
      ];
}
