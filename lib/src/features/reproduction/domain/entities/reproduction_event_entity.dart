import 'package:equatable/equatable.dart';

class ReproductionServiceEntity extends Equatable {
  final String id;
  final String hembraUuid;
  final String hembraArete;
  final String tipoServicio; // 'inseminacion_artificial' | 'monta_natural'
  final String? codigoPajillaMacho;
  final DateTime fechaServicio;
  final DateTime fechaProbableParto;
  final String estadoConfirmacion; // 'pendiente' | 'positiva' | 'negativa' | 'repetida'
  final String? observaciones;

  const ReproductionServiceEntity({
    required this.id,
    required this.hembraUuid,
    required this.hembraArete,
    required this.tipoServicio,
    this.codigoPajillaMacho,
    required this.fechaServicio,
    required this.fechaProbableParto,
    this.estadoConfirmacion = 'pendiente',
    this.observaciones,
  });

  @override
  List<Object?> get props => [
        id,
        hembraUuid,
        hembraArete,
        tipoServicio,
        codigoPajillaMacho,
        fechaServicio,
        fechaProbableParto,
        estadoConfirmacion,
        observaciones,
      ];
}

/// Entidad inmutable que modela el evento de parto de una hembra reproductora.
class ReproductionEventEntity extends Equatable {
  final int? id;
  final String? uuid;
  final int porcinoId; // ID de la madre (Cerda)
  final String? hembraUuid;
  final String? hembraArete;
  final String? corralMaternidadCodigo;
  final DateTime fecha;
  final int nacidosVivos;
  final int nacidosMuertos;
  final int momias;
  final double pesoTotalCamadaKg;
  final int numeroParto;
  final String? observaciones;

  const ReproductionEventEntity({
    this.id,
    this.uuid,
    required this.porcinoId,
    this.hembraUuid,
    this.hembraArete,
    this.corralMaternidadCodigo,
    required this.fecha,
    required this.nacidosVivos,
    required this.nacidosMuertos,
    required this.momias,
    required this.pesoTotalCamadaKg,
    this.numeroParto = 1,
    this.observaciones,
  });

  int get totalNacidos => nacidosVivos + nacidosMuertos + momias;
  double get pesoPromedioLechon =>
      nacidosVivos > 0 ? (pesoTotalCamadaKg / nacidosVivos) : 0.0;

  @override
  List<Object?> get props => [
        id,
        uuid,
        porcinoId,
        hembraUuid,
        hembraArete,
        corralMaternidadCodigo,
        fecha,
        nacidosVivos,
        nacidosMuertos,
        momias,
        pesoTotalCamadaKg,
        numeroParto,
        observaciones,
      ];
}

class WeaningEventEntity extends Equatable {
  final String id;
  final String hembraUuid;
  final String hembraArete;
  final String? corralDestinoCodigo;
  final DateTime fechaDestete;
  final int lechonesDestetados;
  final double pesoTotalKg;
  final int diasLactancia;
  final String? observaciones;

  const WeaningEventEntity({
    required this.id,
    required this.hembraUuid,
    required this.hembraArete,
    this.corralDestinoCodigo,
    required this.fechaDestete,
    required this.lechonesDestetados,
    required this.pesoTotalKg,
    this.diasLactancia = 21,
    this.observaciones,
  });

  double get pesoPromedioLechon =>
      lechonesDestetados > 0 ? (pesoTotalKg / lechonesDestetados) : 0.0;

  @override
  List<Object?> get props => [
        id,
        hembraUuid,
        hembraArete,
        corralDestinoCodigo,
        fechaDestete,
        lechonesDestetados,
        pesoTotalKg,
        diasLactancia,
        observaciones,
      ];
}
