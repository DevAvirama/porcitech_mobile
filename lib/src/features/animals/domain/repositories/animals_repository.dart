import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/porcino_entity.dart';

abstract class AnimalsRepository {
  Future<Either<Failure, List<PorcinoEntity>>> getPorcinos({
    String? query,
    String? filter,
  });

  Future<Either<Failure, PorcinoEntity>> getPorcinoById(int id, {String? uuid});

  Future<Either<Failure, PorcinoEntity>> getPorcinoByQr(String codigo);

  Future<Either<Failure, List<PesoHistoricoItem>>> getHistorialPesajes(
    int id, {
    String? uuid,
  });

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
  });

  Future<Either<Failure, List<LoteEntity>>> getLotes();

  Future<Either<Failure, LoteEntity>> createLote({
    required String codigo,
    required String nombre,
    required String fase,
    required String galpon,
    int capacidadMaxima = 25,
  });
}
