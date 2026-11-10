import 'package:equatable/equatable.dart';

class PesoHistoricoItem extends Equatable {
  final DateTime fecha;
  final double pesoKg;
  final String metodo; // 'manual' | 'ia'

  const PesoHistoricoItem({
    required this.fecha,
    required this.pesoKg,
    this.metodo = 'manual',
  });

  @override
  List<Object?> get props => [fecha, pesoKg, metodo];
}

/// Entidad inmutable que modela al porcino con trazabilidad zootécnica completa.
/// Los aretes de identificación visual (código) son amigables para el operario,
/// conservando los UUIDs reales de PostgreSQL para las operaciones REST con FastAPI.
class PorcinoEntity extends Equatable {
  final int id;
  final String? uuid; // UUID original en PostgreSQL / FastAPI
  final String? corralUuid; // UUID del corral asignado en PostgreSQL
  final String codigo; // Arete de campo (ej: POR-4092, CERDA-H-104)
  final String? codigoQr; // Código QR de trazabilidad (ej: QR-POR-4092)
  final String? nombreAlias; // Alias opcional del ejemplar
  final String raza; // Landrace, Large White, Pietrain, Duroc
  final String sexo; // 'Hembra' | 'Macho' | 'Macho Castrado'
  final DateTime fechaNacimiento;
  final int loteId;
  final String loteNombre;
  final double pesoActual;
  final String estadoSanitario; // 'Sano', 'Enfermo', 'En Tratamiento', 'Retiro Farmacológico'
  final String fase; // 'Ceba', 'Gestación', 'Maternidad', 'Precebo', 'Levante', 'Lactante'
  final double gdpActualGramoDia; // GDP calculada en g/día
  final int diasEnFase;
  final String? medicacionActiva;
  final int diasRetiroRestantes;
  final DateTime? fechaFinRetiro;
  final List<PesoHistoricoItem> curvaCrecimiento;

  const PorcinoEntity({
    required this.id,
    this.uuid,
    this.corralUuid,
    required this.codigo,
    this.codigoQr,
    this.nombreAlias,
    required this.raza,
    required this.sexo,
    required this.fechaNacimiento,
    required this.loteId,
    required this.loteNombre,
    required this.pesoActual,
    required this.estadoSanitario,
    required this.fase,
    required this.gdpActualGramoDia,
    required this.diasEnFase,
    this.medicacionActiva,
    this.diasRetiroRestantes = 0,
    this.fechaFinRetiro,
    this.curvaCrecimiento = const [],
  });

  int get edadEnDias => DateTime.now().difference(fechaNacimiento).inDays.clamp(0, 10000);
  bool get esHembra => sexo.toLowerCase().contains('hembra');
  bool get esHembraReproductora =>
      esHembra &&
      (fase.toLowerCase().contains('gesta') ||
          fase.toLowerCase().contains('mater') ||
          fase.toLowerCase().contains('activo') ||
          edadEnDias >= 180);
  bool get tieneRetiroFarmacologicoActivo => diasRetiroRestantes > 0;

  @override
  List<Object?> get props => [
        id,
        uuid,
        corralUuid,
        codigo,
        codigoQr,
        nombreAlias,
        raza,
        sexo,
        fechaNacimiento,
        loteId,
        loteNombre,
        pesoActual,
        estadoSanitario,
        fase,
        gdpActualGramoDia,
        diasEnFase,
        medicacionActiva,
        diasRetiroRestantes,
        fechaFinRetiro,
        curvaCrecimiento,
      ];
}

/// Entidad inmutable que representa un Corral / Lote de animales en galpón.
class LoteEntity extends Equatable {
  final int id;
  final String? uuid;
  final String codigo;
  final String nombre;
  final String fase;
  final int cantidadPorcinos;
  final int capacidadMaxima;
  final double pesoPromedio;
  final String galpon;
  final bool activo;

  const LoteEntity({
    required this.id,
    this.uuid,
    required this.codigo,
    required this.nombre,
    required this.fase,
    required this.cantidadPorcinos,
    this.capacidadMaxima = 25,
    required this.pesoPromedio,
    required this.galpon,
    this.activo = true,
  });

  @override
  List<Object?> get props => [
        id,
        uuid,
        codigo,
        nombre,
        fase,
        cantidadPorcinos,
        capacidadMaxima,
        pesoPromedio,
        galpon,
        activo,
      ];
}
