import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/storage/local_cache_service.dart';
import '../../domain/entities/porcino_entity.dart';
import '../../domain/repositories/animals_repository.dart';
import '../datasources/animals_remote_datasource.dart';
import '../models/lote_model.dart';
import '../models/porcino_model.dart';

class AnimalsRepositoryImpl implements AnimalsRepository {
  final AnimalsRemoteDataSource remoteDataSource;
  final LocalCacheService cacheService;

  AnimalsRepositoryImpl({
    required this.remoteDataSource,
    required this.cacheService,
  });

  @override
  Future<Either<Failure, List<PorcinoEntity>>> getPorcinos({
    String? query,
    String? filter,
  }) async {
    if (cacheService.isOfflineModeEnabled()) {
      return Right(_getCachedOrSeedPorcinos(query: query, filter: filter));
    }

    try {
      final remoteList = await remoteDataSource.getPorcinos(
        query: query,
        filter: filter,
      );
      if (remoteList.isNotEmpty) {
        final jsonList = remoteList.map((e) => e.toJson()).toList();
        await cacheService.cacheJson(cacheService.keyCachedAnimals, jsonList);
        return Right(remoteList);
      }
      return Right(_getCachedOrSeedPorcinos(query: query, filter: filter));
    } on AppException {
      return Right(_getCachedOrSeedPorcinos(query: query, filter: filter));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PorcinoEntity>> getPorcinoById(int id, {String? uuid}) async {
    if (cacheService.isOfflineModeEnabled()) {
      final list = _getCachedOrSeedPorcinos();
      final found = list.cast<PorcinoEntity?>().firstWhere(
            (p) => p?.id == id || (uuid != null && p?.uuid == uuid),
            orElse: () => null,
          );
      if (found != null) return Right(found);
      return const Left(NotFoundFailure('Porcino no localizado en almacenamiento local.'));
    }

    try {
      final item = await remoteDataSource.getPorcinoById(id, uuid: uuid);
      return Right(item);
    } on AppException {
      final list = _getCachedOrSeedPorcinos();
      final found = list.cast<PorcinoEntity?>().firstWhere(
            (p) => p?.id == id || (uuid != null && p?.uuid == uuid),
            orElse: () => null,
          );
      if (found != null) return Right(found);
      return const Left(NotFoundFailure());
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PorcinoEntity>> getPorcinoByQr(String codigo) async {
    final cleanCode = codigo.trim().toUpperCase();

    if (cacheService.isOfflineModeEnabled()) {
      final list = _getCachedOrSeedPorcinos();
      final found = list.cast<PorcinoEntity?>().firstWhere(
            (p) =>
                p?.codigo.toUpperCase() == cleanCode ||
                p?.codigoQr?.toUpperCase() == cleanCode ||
                p?.codigo.toUpperCase().contains(cleanCode) == true,
            orElse: () => null,
          );
      if (found != null) return Right(found);
      return Left(NotFoundFailure('No se encontró porcino con arete/código $codigo'));
    }

    try {
      final item = await remoteDataSource.getPorcinoByQr(cleanCode);
      return Right(item);
    } on AppException {
      final list = _getCachedOrSeedPorcinos();
      final found = list.cast<PorcinoEntity?>().firstWhere(
            (p) =>
                p?.codigo.toUpperCase() == cleanCode ||
                p?.codigoQr?.toUpperCase() == cleanCode ||
                p?.codigo.toUpperCase().contains(cleanCode) == true,
            orElse: () => null,
          );
      if (found != null) return Right(found);
      return Left(NotFoundFailure('No se encontró porcino con arete $codigo'));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PesoHistoricoItem>>> getHistorialPesajes(
    int id, {
    String? uuid,
  }) async {
    if (cacheService.isOfflineModeEnabled()) {
      return const Right([]);
    }
    try {
      final items = await remoteDataSource.getHistorialPesajes(id, uuid: uuid);
      return Right(items);
    } catch (e) {
      return const Right([]);
    }
  }

  @override
  Future<Either<Failure, PorcinoEntity>> createPorcino({
    required String codigo,
    String? nombreAlias,
    required String raza,
    required String sexo,
    required DateTime fechaNacimiento,
    required int loteId,
    String? corralUuid,
    String estado = 'levante',
    double pesoInicialKg = 0.0,
  }) async {
    final resolvedCorralUuid = corralUuid ?? LoteModel.resolveUuid(loteId);
    final lotes = _getCachedOrSeedLotes();
    final matchedLote = lotes.cast<LoteEntity?>().firstWhere(
          (l) => l?.id == loteId || (resolvedCorralUuid != null && l?.uuid == resolvedCorralUuid),
          orElse: () => null,
        );

    final newModel = PorcinoModel(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      corralUuid: resolvedCorralUuid,
      codigo: codigo.trim(),
      codigoQr: 'QR-${codigo.trim()}',
      nombreAlias: nombreAlias,
      raza: raza,
      sexo: sexo,
      fechaNacimiento: fechaNacimiento,
      loteId: loteId,
      loteNombre: matchedLote?.codigo ?? 'Corral $loteId',
      pesoActual: pesoInicialKg > 0 ? pesoInicialKg : 18.5,
      estadoSanitario: 'Sano',
      fase: estado,
      gdpActualGramoDia: 520.0,
      diasEnFase: 1,
    );

    final offlineAnimalPayload = <String, dynamic>{
      'codigo_arete': codigo.trim(),
      'codigo_qr': 'QR-${codigo.trim()}',
      if (nombreAlias != null && nombreAlias.trim().isNotEmpty)
        'nombre_alias': nombreAlias.trim(),
      'raza': raza,
      'sexo': sexo.toLowerCase().contains('macho') ? 'macho' : 'hembra',
      'fecha_nacimiento': fechaNacimiento.toIso8601String().split('T').first,
      'estado': estado.toLowerCase(),
      'corral_id': ?resolvedCorralUuid,
      'peso_actual_kg': pesoInicialKg,
    };

    if (cacheService.isOfflineModeEnabled()) {
      await cacheService.enqueueSyncItem(
        endpoint: '/animales',
        method: 'POST',
        payload: offlineAnimalPayload,
        description: 'Registro de porcino arete $codigo',
      );
      _addPorcinoToCache(newModel);
      return Right(newModel);
    }

    try {
      final remote = await remoteDataSource.createPorcino(
        codigo: codigo,
        nombreAlias: nombreAlias,
        raza: raza,
        sexo: sexo,
        fechaNacimiento: fechaNacimiento,
        loteId: loteId,
        corralUuid: resolvedCorralUuid,
        estado: estado,
        pesoInicialKg: pesoInicialKg,
      );
      _addPorcinoToCache(remote);
      return Right(remote);
    } on AppException {
      await cacheService.enqueueSyncItem(
        endpoint: '/animales',
        method: 'POST',
        payload: offlineAnimalPayload,
        description: 'Registro de porcino arete $codigo',
      );
      _addPorcinoToCache(newModel);
      return Right(newModel);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LoteEntity>>> getLotes() async {
    if (cacheService.isOfflineModeEnabled()) {
      return Right(_getCachedOrSeedLotes());
    }

    try {
      final list = await remoteDataSource.getLotes();
      if (list.isNotEmpty) {
        final jsonList = list.map((e) => e.toJson()).toList();
        await cacheService.cacheJson(cacheService.keyCachedLotes, jsonList);
        return Right(list);
      }
      return Right(_getCachedOrSeedLotes());
    } on AppException {
      return Right(_getCachedOrSeedLotes());
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, LoteEntity>> createLote({
    required String codigo,
    required String nombre,
    required String fase,
    required String galpon,
    int capacidadMaxima = 25,
  }) async {
    final model = LoteModel(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      codigo: codigo,
      nombre: nombre,
      fase: fase,
      cantidadPorcinos: 0,
      capacidadMaxima: capacidadMaxima,
      pesoPromedio: 0.0,
      galpon: galpon,
    );

    final f = fase.toLowerCase();
    String faseBackend = 'ceba';
    if (f.contains('gesta')) {
      faseBackend = 'gestacion';
    } else if (f.contains('mater') || f.contains('lacta')) {
      faseBackend = 'maternidad';
    } else if (f.contains('deste') || f.contains('prece')) {
      faseBackend = 'precebo';
    } else if (f.contains('levan')) {
      faseBackend = 'levante';
    } else if (f.contains('cuaren')) {
      faseBackend = 'cuarentena';
    }

    final offlineLotePayload = <String, dynamic>{
      'codigo': codigo.trim(),
      'descripcion': nombre.trim().isNotEmpty ? '${nombre.trim()} • $galpon' : galpon,
      'fase': faseBackend,
      'capacidad_maxima': capacidadMaxima,
      'activo': true,
    };

    if (cacheService.isOfflineModeEnabled()) {
      await cacheService.enqueueSyncItem(
        endpoint: '/corrales',
        method: 'POST',
        payload: offlineLotePayload,
        description: 'Creación de corral $codigo ($nombre)',
      );
      return Right(model);
    }

    try {
      final remote = await remoteDataSource.createLote(
        codigo: codigo,
        nombre: nombre,
        fase: fase,
        galpon: galpon,
        capacidadMaxima: capacidadMaxima,
      );
      return Right(remote);
    } on AppException {
      await cacheService.enqueueSyncItem(
        endpoint: '/corrales',
        method: 'POST',
        payload: offlineLotePayload,
        description: 'Creación de corral $codigo ($nombre)',
      );
      return Right(model);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  void _addPorcinoToCache(PorcinoModel model) {
    final cached = _getCachedOrSeedPorcinos();
    cached.insert(0, model);
    final jsonList = cached.map((e) {
      if (e is PorcinoModel) return e.toJson();
      return (e as dynamic).toJson();
    }).toList();
    cacheService.cacheJson(cacheService.keyCachedAnimals, jsonList);
  }

  List<PorcinoEntity> _getCachedOrSeedPorcinos({String? query, String? filter}) {
    List<PorcinoModel> list = [];
    final cachedJson = cacheService.getCachedJson(cacheService.keyCachedAnimals);
    if (cachedJson != null && cachedJson is List) {
      list = cachedJson
          .map((e) => PorcinoModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    if (list.isEmpty) {
      list = [
        PorcinoModel(
          id: 4092,
          codigo: 'POR-4092',
          codigoQr: 'QR-POR-4092',
          raza: 'Landrace x Pietrain',
          sexo: 'Macho Castrado',
          fechaNacimiento: DateTime.now().subtract(const Duration(days: 145)),
          loteId: 3,
          loteNombre: 'COR-CEB-03',
          pesoActual: 82.5,
          estadoSanitario: 'Sano',
          fase: 'Ceba',
          gdpActualGramoDia: 820.0,
          diasEnFase: 65,
        ),
        PorcinoModel(
          id: 104,
          codigo: 'CERDA-H-104',
          codigoQr: 'QR-CERDA-H-104',
          raza: 'Landrace Puro',
          sexo: 'Hembra',
          fechaNacimiento: DateTime.now().subtract(const Duration(days: 480)),
          loteId: 1,
          loteNombre: 'COR-GES-01',
          pesoActual: 215.0,
          estadoSanitario: 'Sano',
          fase: 'Gestación',
          gdpActualGramoDia: 380.0,
          diasEnFase: 110,
        ),
        PorcinoModel(
          id: 2015,
          codigo: 'POR-2015',
          codigoQr: 'QR-POR-2015',
          raza: 'Duroc',
          sexo: 'Macho',
          fechaNacimiento: DateTime.now().subtract(const Duration(days: 90)),
          loteId: 2,
          loteNombre: 'COR-LEV-02',
          pesoActual: 48.0,
          estadoSanitario: 'Retiro Farmacológico',
          fase: 'Levante',
          gdpActualGramoDia: 740.0,
          diasEnFase: 35,
          medicacionActiva: 'Oxitetraciclina L.A.',
          diasRetiroRestantes: 12,
          fechaFinRetiro: DateTime.now().add(const Duration(days: 12)),
        ),
        PorcinoModel(
          id: 503,
          codigo: 'POR-503',
          codigoQr: 'QR-POR-503',
          raza: 'Large White',
          sexo: 'Hembra',
          fechaNacimiento: DateTime.now().subtract(const Duration(days: 120)),
          loteId: 3,
          loteNombre: 'COR-CEB-03',
          pesoActual: 76.0,
          estadoSanitario: 'En Tratamiento',
          fase: 'Ceba',
          gdpActualGramoDia: 680.0,
          diasEnFase: 50,
          medicacionActiva: 'Amoxicilina Trihidrato',
          diasRetiroRestantes: 5,
          fechaFinRetiro: DateTime.now().add(const Duration(days: 5)),
        ),
      ];
    }

    var filtered = list;
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      filtered = filtered
          .where((p) =>
              p.codigo.toLowerCase().contains(q) ||
              (p.nombreAlias?.toLowerCase().contains(q) ?? false) ||
              p.raza.toLowerCase().contains(q) ||
              p.loteNombre.toLowerCase().contains(q))
          .toList();
    }

    if (filter != null && filter != 'Todos') {
      if (filter == 'Enfermos') {
        filtered = filtered
            .where((p) =>
                p.estadoSanitario == 'Enfermo' ||
                p.estadoSanitario == 'En Tratamiento' ||
                p.estadoSanitario == 'Retiro Farmacológico')
            .toList();
      } else {
        filtered = filtered
            .where((p) => p.fase.toLowerCase() == filter.toLowerCase())
            .toList();
      }
    }

    return filtered;
  }

  List<LoteEntity> _getCachedOrSeedLotes() {
    final cachedJson = cacheService.getCachedJson(cacheService.keyCachedLotes);
    if (cachedJson != null && cachedJson is List && cachedJson.isNotEmpty) {
      return cachedJson
          .map((e) => LoteModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return const [
      LoteModel(
        id: 1,
        codigo: 'COR-GES-01',
        nombre: 'Corral Gestación A',
        fase: 'Gestación',
        cantidadPorcinos: 12,
        capacidadMaxima: 25,
        pesoPromedio: 210.5,
        galpon: 'Galpón 1 - Maternidad y Gestación',
      ),
      LoteModel(
        id: 2,
        codigo: 'COR-LEV-02',
        nombre: 'Corral Levante Norte',
        fase: 'Levante',
        cantidadPorcinos: 24,
        capacidadMaxima: 30,
        pesoPromedio: 47.8,
        galpon: 'Galpón 2 - Levante',
      ),
      LoteModel(
        id: 3,
        codigo: 'COR-CEB-03',
        nombre: 'Corral Ceba 03',
        fase: 'Ceba',
        cantidadPorcinos: 28,
        capacidadMaxima: 35,
        pesoPromedio: 81.4,
        galpon: 'Galpón 3 - Ceba Tecnificada',
      ),
    ];
  }
}
